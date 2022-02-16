#!/bin/bash
#===========================================================================
#          FILE: rpm_packaging.sh
#         USAGE: ./rpm_packaging.sh --help
#   DESCRIPTION: AnyStor-E RPM packaging script
#       OPTIONS: ---
#       VERSION: 3.0
#         NOTES: ---
#        AUTHOR: Ji-Hyeon Gim <potatogim@gluesys.com>
#                Kyeong-Pyo Kim <kpkim@gluesys.com>
#                Geun-Yeong Bak <gybak@gluesys.com>
#     COPYRIGHT: Copyright 2015-2021. Gluesys Co., Ltd. All rights reserved.
#          DATE:
#===========================================================================

#===========================================================================
# Global Variable
#===========================================================================
PKG_VERSION=
PKG_RELEASE=

#####
#   Paths
###
SCRIPTDIR="$( cd "$(dirname "$0")"; pwd -P )"

PACK_DIR=

BUILD=
RELEASE=
SOURCE=
LOG=

COMPILE=
RPMBUILD=
I18N=

TGT_DIR='/usr'

#####
#   Repo./Branch Select
###
GMS_REPO="ac2/GMS"
GMS_BRANCH=""
GMS_SRC=""
GMS_LOCAL=0
GMS_COMMIT=""

#####
#   Options
####
WITH_PP=0


#===========================================================================
# Functions
#===========================================================================
function export_srcs
{
    ########################################
    # GMS
    ########################################
    if [ $GMS_LOCAL -eq 0 ]; then
        echo "[`date`] Exporting ${GMS_REPO} with ${GMS_BRANCH}..."

        rm -rf $GMS_SRC 1>/dev/null
        mkdir -p $GMS_SRC 1>/dev/null

        git archive --format tar --remote git@gitlab.gluesys.com:${GMS_REPO}.git ${GMS_BRANCH} \
            -o "/tmp/${GMS_REPO//\//-}-${GMS_BRANCH}.tar"

        tar -xpf "/tmp/${GMS_REPO//\//-}-${GMS_BRANCH}.tar" -C $GMS_SRC 1>/dev/null

        if [ $? -ne 0 ]; then
            echo "[ERR] Could not export '$GMS_REPO'!"
            exit 255
        fi
    fi

    ########################################
    # to compile
    ########################################
#     echo "[`date`] Exporting packages to be compiled..."
#
#     rm -rf $COMPILE 1>/dev/null
#     mkdir -p $COMPILE 1>/dev/null
#
#     svn export --force svn://svn.gluesys.com/GMS2/compile $COMPILE 1>/dev/null
#
#     if [ $? -ne 0 ]; then
#         echo "[ERR] Could not export 'compile'!"
#         exit 255
#     fi

    return 0
}

function update_version()
{
    if [ $GMS_LOCAL -eq 1 ]; then
        pushd $GMS_SRC
        GMS_COMMIT=$(git rev-parse HEAD | cut -c -8)
        popd
    else
        GMS_COMMIT=$(git get-tar-commit-id < /tmp/${GMS_REPO//\//-}-${GMS_BRANCH}.tar | cut -c -8)
    fi

    DATE=`LANG=en_US.UTF-8 date`

    #if [ "x$PKG_RELEASE" == "x" ]; then
    #    PKG_RELEASE=`cat $GMS_SRC/VERSION | jq .\"AnyStor-E\" | sed -e 's/^.\+-//g;'`
    #
    #    if [[ "$PKG_RELEASE" =~ ^[0-9]+$ ]]; then
    #        PKG_RELEASE=$PKG_RELEASE+1
    #    fi
    #fi

    echo "PKG_RELEASE: $PKG_RELEASE"

    if [ "x$PKG_VERSION" == "x" ]; then
        if [ $GMS_LOCAL -eq 1 ]; then
            pushd $GMS_SRC
            PKG_VERSION=`git tag | grep '^[0-9]' | sort -V | tail -n1 | awk -F '.' '{ print $1 "." $2 "." $NF+1 }'`
            popd
        else
            PKG_VERSION=`cat $GMS_SRC/VERSION | jq .\"AnyStor-E\" | sed -e 's/\"//g'`
        fi

        cat $GMS_SRC/VERSION | jq ".GMS += \" ${GMS_BRANCH:-"src"}\"
                                    | .Commit = \"${GMS_COMMIT:-"unknown"}\"
                                    | .Date = \"${DATE}\"" \
            > $SOURCE/gms/VERSION
    else
        cat $GMS_SRC/VERSION | jq ".GMS = \"${PKG_VERSION}-${PKG_RELEASE}\"
                                    | .Commit = \"${GMS_COMMIT:-"unknown"}\"
                                    | .Date = \"${DATE}\"" \
            > $SOURCE/gms/VERSION
    fi

    return 0
}

#####
#   Make RPM SPEC
###
function write_rpm_spec()
{
    echo "[`date`] Write rpm spec"

    local OUTPUT=$RPMBUILD/SPECS/anystor-e.spec

    [ -f $OUTPUT ] && rm -f $OUTPUT

    local PKG_TAG="[GMS:${GMS_BRANCH}(${GMS_COMMIT})]"

    OIFS=$IFS
    IFS=

    # Substitue pre-defined words to corresponding var in meta.spec
    while IFS= read -r line;
    do
        # AnyStor-E version
        if [[ $line =~ BUILD_VER ]]; then
            echo ${line//BUILD_VER/$PKG_VERSION} >> $OUTPUT
        # source tag/branch info
        elif [[ $line =~ BUILD_TAG ]]; then
            echo ${line//BUILD_TAG/$PKG_TAG} >> $OUTPUT
        # required package
        elif [[ $line =~ BUILD_REQS ]]; then
            cat $GMS_SRC/build/required_packages >> $OUTPUT
        # rpmbuild target directory
        elif [[ $line =~ BUILD_TARGET_DIR ]]; then
            echo ${line//BUILD_TARGET_DIR/$TGT_DIR} >> $OUTPUT
        else
            echo $line >> $OUTPUT
        fi
    done < $GMS_SRC/build/meta.spec

    IFS=$OIFS

#    # Substitute source files list for BUILD_FILES in meta.spec
#    OIFS=$IFS
#    IFS=$'\n'
#
#    for t_file in $(tar -tf $RPMBUILD/SOURCES/anystor-e-${PKG_VERSION}-${PKG_RELEASE}.tar.gz)
#    do
#        t_file="${t_file/#anystor-e-${PKG_VERSION}-${PKG_RELEASE}/$TGT_DIR}"
#
#        if [[ $t_file == '/usr/' || $t_file =~ /\. ]]; then
#            continue
#        elif [[ $t_file =~ /$ ]]; then
#            echo "%dir \"$t_file\"" >> $OUTPUT
#        elif [[ $t_file =~ supervisord.private.conf ]]; then
#            echo "%config(noreplace) \"/usr/gms/misc/etc/supervisord.private.conf\"" \
#                >> $OUTPUT
#        else
#            echo "\"$t_file\"" >> $OUTPUT
#
#            #if [[ $t_file =~ .py$ ]]; then
#                #echo "\"${t_file/.py/.pyc}\"" >> $OUTPUT
#                #echo "\"${t_file/.py/.pyo}\"" >> $OUTPUT
#            #fi
#        fi
#    done
#
#    IFS=$OIFS
#
#    # i18n mo files will be built in rpmbuild
#    echo "\"/usr/share/locale/ko_KR/LC_MESSAGES/com.gluesys.gms.mo\"" >> $OUTPUT
#
#    # Substitute change log for BUILD_CLOG in meta.spec
#    echo -e "\n%changelog" >> $OUTPUT
#    echo "* `date +"%a %b %d %Y"` AnyStor-E <rnd@gluesys.com> $PKG_VERSION" >> $OUTPUT
#    echo "- release AnyStor-E v$PKG_VERSION" >> $OUTPUT
}

function print_help()
{
    echo
    echo -n "USAGE: $0 --gms-repo [GIT REPO] --gms-branch [GIT BRANCH] --gms-src [PATH]"
    echo " --version [VERSION]"
    echo
    echo "OPTIONS"
    echo "    --gms-repo [GIT REPO]         it specifies which git repository will be used for GMS."
    echo "    --gms-branch [GIT BRANCH]     specify a branch of GMS."
    echo "    --gms-src [PATH]              it specifies a local source of GMS."
    echo "    --version [VERSION]           it specifies version of AnyStor-E."
    echo "    --release [RELEASE]           it specifies release number of AnyStor-E."
    echo "    --with-pp                     packing with pp for converting to executable."
    echo "                                  default is 0."
    echo "    -h, --help                    show this help message."
    echo
    echo "Copyright 2015-2021. Gluesys Co., Ltd. All rights reserved."
    echo ""
}


#===========================================================================
# Main
#===========================================================================

#####
#   Setup Build Environments
###

# Indicate target source
## Pasrse input
while getopts ":h-:" opt; do
    case $opt in
        -)
            case "${OPTARG}" in
                gms-repo)
                    GMS_REPO=${!OPTIND}
                    OPTIND=$(( $OPTIND + 1 ))
                    ;;
                gms-repo=*)
                    GMS_REPO=${OPTARG#*=}
                    ;;
                gms-branch)
                    GMS_BRANCH=${!OPTIND}
                    OPTIND=$(( $OPTIND + 1 ))
                    ;;
                gms-branch=*)
                    GMS_BRANCH=${OPTARG#*=}
                    ;;
                gms-src)
                    GMS_SRC=${!OPTIND}
                    OPTIND=$(( $OPTIND + 1 ))
                    ;;
                gms-src=*)
                    GMS_SRC=${OPTARG#*=}
                    ;;
                with-pp)
                    WITH_PP=1
                    ;;
                with-pp=*)
                    WITH_PP=${OPTARG#*=}
                    ;;
                output)
                    OUTPUT=${!OPTIND}
                    OPTIND=$(( $OPTIND + 1 ))
                    ;;
                output=*)
                    OUTPUT=${OPTARG#*=}
                    ;;
                version)
                    PKG_VERSION=${!OPTIND}
                    OPTIND=$(( $OPTIND + 1 ))
                    ;;
                version=*)
                    PKG_VERSION=${OPTARG#*=}
                    ;;
                release)
                    PKG_RELEASE=${!OPTIND}
                    OPTIND=$(( $OPTIND + 1 ))
                    ;;
                release=*)
                    PKG_RELEASE=${OPTARG#*=}
                    ;;
                help)
                    print_help
                    exit 0
                    ;;
                *)
                    echo "Invalid option: --$OPTARG"
                    ;;
            esac
            ;;
        h)
            print_help
            exit 0
            ;;
        ?)
            echo "Invalid option: -$OPTARG"
            exit 1
            ;;
        :)
            echo "Option -$OPTARG requires an argument."
            exit 1
            ;;
    esac
done;

if [ "x$GMS_BRANCH" == "x" ]; then
    if [ "x$GMS_SRC" != "x" ]; then
        GMS_REPO=""
        GMS_BRANCH=""
        GMS_LOCAL=1
    else
        echo "GMS repository info is not specified!"
        exit 2;
    fi
fi

# Setup the working spaces
## create directory for the release.
export LD_LIBRARY_PATH=/usr/lib64

PACK_DIR=${OUTPUT:-"$HOME/ANYSTOR-E"}

[ ! -d $PACK_DIR ] && mkdir -p $PACK_DIR

BUILD=$PACK_DIR/build
RELEASE=$PACK_DIR/release
SOURCE=$RELEASE/anystor-e
LOG=$PACK_DIR/build.log

COMPILE=$BUILD/compile
RPMBUILD=$PACK_DIR/rpmbuild

[ $GMS_LOCAL -ne 1 ] && GMS_SRC="$BUILD/gms"

I18N=$GMS_SRC/po

[ -d $RELEASE ] && rm -rf $RELEASE
[ -d $RELEASE ] || mkdir -p $RELEASE $SOURCE

#[ -d $RPMBUILD ] && rm -rf $RPMBUILD 1>/dev/null
[ -d $RPMBUILD ] || mkdir -p $RPMBUILD 1>/dev/null

for d in BUILD BUILDROOT RPMS SOURCES SPECS SRPMS; do
    [ -d ${RPMBUILD}/$d ] || mkdir ${RPMBUILD}/$d 1>/dev/null
done;

# print
LISTS=()
RESULTS=()
PPFLAGS="-B -T gluesys -M List::MoreUtils::PP -l db -l zmq -l pgm"

START_TIME=$(date)
echo
echo "[$START_TIME] Starting to package AnyStor-E"
echo
echo "GMS"
echo "  - REPO   : $GMS_REPO"
echo "  - BRANCH : $GMS_BRANCH"
echo "  - SRC    : $GMS_SRC"
echo "  - LOCAL  : $GMS_LOCAL"
echo
echo "OPTIONS"
echo "  - WITH_PP : $WITH_PP"
echo

# Setup pipe for redirection stdout/stderr
npipe=/tmp/$$.tmp

trap "{ rm -f $npipe; }" EXIT
trap "{ rm -f $npipe; exit 255; }" SIGINT SIGTERM

mknod $npipe p
tee < $npipe $LOG &

## Save stdout/stderr to 5/6.
exec 5>&1 6>&2

## Close stdout/stderr and re-open with npipe.
exec 1>&- 2>&-
exec 1>$npipe 2>$npipe

# Fetch the target source to working spaces
export_srcs

# GMS packaging
cp -af $GMS_SRC $SOURCE/gms

if [ $? -ne 0 ]; then
    echo "Failed to package GMS!"
fi

# Add tag/branch infos to the VERSION file
update_version

# Archiving the prepared sources
pushd $RELEASE 1>/dev/null

VR=${PKG_VERSION}${PKG_RELEASE:+-$PKG_RELEASE}${PKG_RELEASE:--1}
DISTRO=`rpm --eval '%{dist}'`

mv $SOURCE $SOURCE-${VR}

#tar -cpz --exclude-vcs --exclude '*/t/*' --exclude '*.t$' \
tar -cpz --exclude-vcs \
    --exclude 'rpmbuild/*' --exclude 'other_job_rpm/*' \
    --exclude 'nyptprof.out*' \
    -f "${RPMBUILD}/SOURCES/anystor-e-${VR}.tar.gz" \
    "anystor-e-${VR}"

if [ $? -ne 0 ]; then
    echo "Failed to packaging"
    exit 6
fi

popd 1>/dev/null

# Write .spec rpm description
write_rpm_spec

# Make rpm package
echo "[`date`] Make rpm package"

rpmbuild -ba \
    --define "_topdir $RPMBUILD" \
    ${PKG_RELEASE:+--define "prerel $PKG_RELEASE"} \
    $RPMBUILD/SPECS/anystor-e.spec

if [ $? -ne 0 ]; then
    echo "Failed to rpmbuild"
    exit 1
fi

# Extract finished rpm package
RPMFILE="anystor-e-${VR}${DISTRO}.x86_64.rpm"

ln -sf $RPMBUILD/RPMS/x86_64/$RPMFILE $PACK_DIR/$RPMFILE

if [ $? -ne 0 ]; then
    echo "Failed to make a symlink for the rpm package!"
    exit 6
fi

ln -sf $RPMBUILD/RPMS/x86_64/$RPMFILE $PACK_DIR/installer.rpm

if [ $? -ne 0 ]; then
    echo "Failed to make a symlink for the rpm package!"
    exit 6
fi

echo "======================================================="
echo "  Results "
echo "      - GMS    : ${GMS_BRANCH:-src}(${GMS_COMMIT:-src})"
echo "      - OUTPUT : $PACK_DIR"
echo ""
echo "  $START_TIME - `date`"

if [ ${#LISTS[@]} -gt 1 ]; then

    for (( i=0; i<${#LISTS[@]}; i++ ))
    do
        printf "%5s %-30s %15s\n" "-" "${LISTS[$i]}" "[${RESULTS[$i]}]"
    done

fi

echo "======================================================="
echo ""
echo "Copyright 2015-2021. Gluesys Co., Ltd. All rights reserved."
echo ""
echo "Complete."

# Restore stdout/stderr with 5/6 which save original stdout/stderr.
exec 1>&5 2>&6

# Close FD 5, 6.
exec 5>&- 6>&-

exit 0
