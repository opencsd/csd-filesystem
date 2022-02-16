#!/bin/rpmbuld -qa
#===========================================================================
#          FILE: meta.spec
#         USAGE: pacakge.sh use this .spec
#   DESCRIPTION: meta file for RPM package dynamic generating 
#       OPTIONS: ---
#       VERSION: BUILD_VER
#         NOTES: ---
#        AUTHOR: Ji-Hyeon Gim <potatogim@gluesys.com>
#     COPYRIGHT: Copyright 2015-2021. Gluesys Co., Ltd. All rights reserved.
#          DATE: 
#===========================================================================
#===========================================================================
# Global Definitions
#===========================================================================
%define _unpackaged_files_terminate_build 0
%define __spec_install_post %{nil}
%define debug_package %{nil}

%if ( 0%{?fedora} && 0%{?fedora} > 16 ) || ( 0%{?rhel} && 0%{?rhel} > 6 )
%global _with_systemd true
%endif


#===========================================================================
# RPM Installer Attributes
#===========================================================================
Name:		anystor-e
Version:	BUILD_VER
Release:	%{!?prerel:1}%{?prerel:0}%{?prerel:.%{prerel}}%{?dist}
Summary:	AnyStor Enterprise BUILD_TAG

Group:		Cluster/Storage
License:	Copyright 2015-2021. Gluesys Co., Ltd. All rights reserved.
URL:		http://www.gluesys.com
Source0:	%{name}-%{version}-%{!?prerel:1}%{?prerel:0}%{?prerel:.%{prerel}}.tar.gz

Provides:	anycloud
Obsoletes:	anycloud

BUILD_REQS

AutoReq:	no
AutoReqProv:	no

%description

AnyStor-E is a storage management solution for enterprise infrastructure.


#===========================================================================
#   Preparation
#===========================================================================
%prep
%setup -q -n %{name}-%{version}-%{!?prerel:1}%{?prerel:0}%{?prerel:.%{prerel}}


#===========================================================================
#   Build
#===========================================================================
%build

pushd gms/i18n
find ../lib ../libgms -name '*.pm' > POTFILES
sed -i -e "s|/usr/share/locale|$RPM_BUILD_ROOT/%{_datadir}/locale|" PACKAGE
make update-mo
popd


#===========================================================================
#   Install(on the build machine)
#===========================================================================
%install

mkdir -p $RPM_BUILD_ROOT/BUILD_TARGET_DIR/gms
mkdir -p $RPM_BUILD_ROOT/%{_sysconfdir}/sysconfig
mkdir -p $RPM_BUILD_ROOT/%{_unitdir}
mkdir -p $RPM_BUILD_ROOT/%{_datadir}/locale

# install i18n
pushd gms/i18n
make install
popd

cp -af $RPM_BUILD_ROOT/%{_datadir}/locale/ko_KR \
        $RPM_BUILD_ROOT/%{_datadir}/locale/ko

for i in bin config doc lib libgms misc public script templates VERSION;
do
    cp -af gms/$i $RPM_BUILD_ROOT/BUILD_TARGET_DIR/gms/$i
done;

cp -af gms/misc/gms.sysconfig \
        $RPM_BUILD_ROOT/%{_sysconfdir}/sysconfig/gms

%if ( 0%{?_with_systemd:1} )
    cp -af $RPM_BUILD_ROOT/BUILD_TARGET_DIR/gms/misc/gms.service \
           $RPM_BUILD_ROOT/%{_unitdir}/gms.service
%endif

mkdir -p $RPM_BUILD_ROOT/%{_sysconfdir}/rsyslog.d

cp -af gms/misc/gms.rsyslog \
        $RPM_BUILD_ROOT/%{_sysconfdir}/rsyslog.d/gms.conf

mkdir -p $RPM_BUILD_ROOT/%{_sysconfdir}/logrotate.d

cp -af gms/misc/gms.logrotate \
        $RPM_BUILD_ROOT/%{_sysconfdir}/logrotate.d/gms

find $RPM_BUILD_ROOT/BUILD_TARGET_DIR -name '*.go' -exec rm -f '{}' \;


#===========================================================================
#   Pre-install
#===========================================================================
%pre

[ ! -d /var/lib/gms ] && mkdir -p /var/lib/gms

cat 1>/var/lib/gms/functions <<-EOF
# -*-Shell-script-*-
function disable_stdout()
{
    if ( true >&3 ) 2>/dev/null; then
        exec 4>&3
        exec 3>&-
    fi
}

function enable_stdout()
{
    if ( true >&4 ) 2>/dev/null; then
        exec 3>&4
        exec 4>&-
    fi
}

function log()
{
    COLOR_RESET="\e[0m"
    RED="\e[0;31m"
    GREEN="\e[0;32m"
    YELLOW="\e[0;33m"
    BLUE="\e[0;34m"
    PURPLE="\e[0;35m"
    CYAN="\e[0;36m"
    WHITE="\e[0;37m"

    case \$# in
        3)
            LEVEL=\$1
            FORMAT=\$2
            MSG=\$3
            ;;
        2)
            LEVEL=\$1
            FORMAT="%s"
            MSG=\$2
            ;;
    esac

    case \$LEVEL in
        INFO)
            if ( true >&3 ) 2>/dev/null; then
                printf "\$FORMAT\n" "\$MSG" >&3
            fi

            printf "%s: \$FORMAT\n" "\`date "+%Y-%m-%d %T"\`" "\$MSG"
            ;;
        WARN)
            if ( true >&3 ) 2>/dev/null; then
                printf "\$YELLOW\$FORMAT\$COLOR_RESET\n" "\$MSG" >&3
            fi

            printf "%s: \$FORMAT\n" "\`date "+%Y-%m-%d %T"\`" "\$MSG"
            ;;
        ERR)
            if ( true >&3 ) 2>/dev/null; then
                printf "\$RED\$FORMAT\$COLOR_RESET\n" "\$MSG" >&3
            fi

            printf "%s: \$FORMAT\n" "\`date "+%Y-%m-%d %T"\`" "\$MSG"
            ;;
        *)
            if ( true >&3 ) 2>/dev/null; then
                printf "\$FORMAT\n" "\$MSG" >&3
            fi

            printf "%s: \$FORMAT\n" "\`date "+%Y-%m-%d %T"\`" "\$MSG"
            ;;
    esac

    return 0
}

function version_to_metric()
{
    local version=\$1

    local metric=0

    while [ "\$version" != "" ];
    do
        next_dot=\`expr index "\$version" '.'\`
        let cutting_point=\$next_dot-1

        if [ \$cutting_point -ge 0 ]; then
            operand=\${version:0:\$cutting_point}
        else
            operand=\$version
        fi

        let metric=\$metric+\$operand

        if [[ \$version =~ '.' ]]; then
            version=\${version:\$next_dot}
            let metric=\$metric*1000
        else
            break
        fi
    done

    eval \$2=\$metric
}
EOF


#===========================================================================
#   Post-install
#===========================================================================
%post

#!/bin/sh

#####
#   Global Variables
###
GMS_DIR='BUILD_TARGET_DIR/gms'
GMS_VAR_LIB_DIR="/var/lib/gms"
ACTS_DIR="$GMS_VAR_LIB_DIR/deploy/rpm_deploy_actions"


#####
#   Helper
###
. /var/lib/gms/functions


#####
#   Logging
###
[ ! -d /var/log/gms ] && mkdir -p /var/log/gms
[ ! -d $GMS_VAR_LIB_DIR/local_db ] && mkdir -p $GMS_VAR_LIB_DIR/local_db

TIMESTAMP=$(date "+%y%m%d-%H%M%S")

if [ $1 -gt 1 ]; then
    LOG_FILE="/var/log/gms/upgrade"
else
    LOG_FILE="/var/log/gms/install"
fi

LOG_FILE="${LOG_FILE}-${TIMESTAMP}.log"

exec 3>&1
exec 1>&-
exec 2>&-

exec 1>>"$LOG_FILE"
exec 2>&1


#####
#   Main
###

ldconfig

getent group gms > /dev/null || groupadd -r gms
getent passwd admin > /dev/null

if [ $? -ne 0 ]; then
    useradd -r -g gms -c "GMS User" -s /sbin/nologin -d /var/log/gms admin
    echo "admin" | passwd admin --stdin
fi

if [ -e "$GMS_VAR_LIB_DIR" ] && [ ! -d "$GMS_VAR_LIB_DIR" ]; then
    rm -f "$GMS_VAR_LIB_DIR"
fi

if [ ! -e "$GMS_VAR_LIB_DIR" ]; then
    mkdir -p "$GMS_VAR_LIB_DIR"
fi

# Take local-stage
LOCAL_STAGE=''

if [ -e "$GMS_VAR_LIB_DIR/local_stage" ]; then
    LOCAL_STAGE=`$GMS_DIR/bin/stagectl get -s local`
fi

log "INFO" "Current Local Stage: $LOCAL_STAGE"


#####
#   RPM Deploy Actions
###

# Select rpm_deploy_actions corresponding to the os type
ACTIONS="$GMS_DIR/misc/deploy/rpm_deploy_actions"

# Copy selected rpm_deploy_actions to deploy directory
mkdir -p "$ACTS_DIR"

cp -f "$ACTIONS/file_updates.act" "$ACTS_DIR/"
cp -f "$ACTIONS/file_copies.act" "$ACTS_DIR/"
cp -f "$ACTIONS/file_links.act" "$ACTS_DIR/"
cp -f "$ACTIONS/commands.act" "$ACTS_DIR/"

cp -f "$GMS_DIR/script/rpm_deploy_actions_handler" "$ACTS_DIR/"

# Apply rpm_deploy_actions to the system
$ACTS_DIR/rpm_deploy_actions_handler 'do' "$ACTS_DIR"


#####
#   Load default environment variables
###
. /etc/default/gluesys


#####
#   Check whether the node is initialized
###

# Fetch initialized info
if [ -e "$GMS_VAR_LIB_DIR/initialized" ]; then
    is_init=`cat "$GMS_VAR_LIB_DIR/initialized"`
else
    is_init=0
fi

# If the node is initialized, proceed to update process

# Determine that the node is initialized
if [ "x$is_init" == "x1" ]; then
    log "INFO" "Status: INITIALIZED"
else
    log "INFO" "Status: UNINITIALIZED"
    touch "$GMS_VAR_LIB_DIR/local_mode"
    echo '{ "data" : "", "stage" : "configured" }' > /var/lib/gms/local_stage
fi


#####
#   Update node version file in local
###
echo %{version} > "$GMS_VAR_LIB_DIR/version"


#####
#   Update local-stage
###
if [ "x$LOCAL_STAGE" != "x" ]; then
    log "INFO" "Setting Local Stage to \"$LOCAL_STAGE\"..."
    echo "{ \"data\" : \"\", \"stage\" : \"$LOCAL_STAGE\" }" > /var/lib/gms/local_stage
elif [ $1 == 1 ]; then
    log "INFO" "Setting Local Stage to \"installed\"..."
    touch "$GMS_VAR_LIB_DIR/local_mode"
    echo "{ \"data\" : \"\", \"stage\" : \"installed\" }" > /var/lib/gms/local_stage
fi


#####
#   Delegate default admin
###
/usr/gms/script/gms admin -n admin


#####
#   Print complete message
###
if [ "x$is_init" == "x1" ]; then
    log "INFO" "This node has updated successfully : %{version}"
else
    log "INFO" "Please execute this command on the shell"
    log "INFO" ""
    log "INFO" "	# /usr/gms/script/node_configure"
    log "INFO" ""
fi

%if ( 0%{?_with_systemd:1} )
    systemctl daemon-reload
    systemctl enable gms.service
    systemctl start gms.service

    log "INFO" 'Stopping and disabling lvm2-lvmetad...'

    lvmconfig \
        --type current --mergedconfig \
        --config=global/use_lvmetad=0 --withcomment -f /etc/lvm/lvm.conf

    systemctl stop lvm2-lvmetad.service
    systemctl disable lvm2-lvmetad.service

    log "INFO" 'Updating lvm configuration...'

    lvmconfig \
        --type current --mergedconfig \
        --config=dmeventd/thin_command="/usr/gms/script/thin_pool_event" \
        --withcomment -f /etc/lvm/lvm.conf

    lvmconfig \
        --type current --mergedconfig \
        --config=activation/thin_pool_autoextend_threshold=80 \
        --withcomment -f /etc/lvm/lvm.conf

    lvmconfig \
        --type current --mergedconfig \
        --config=activation/thin_pool_autoextend_percent=50 \
        --withcomment -f /etc/lvm/lvm.conf

    lvmconfig \
        --type current --mergedconfig \
        --config=global/thin_check_options='"--skip-mappings"' \
        --withcomment -f /etc/lvm/lvm.conf

    log "INFO" 'Updating 3rd party package systemd unit file...'

    for SVC in mariadb glusterd ntpd smb ctdb;
    do
        SVC_FILE="%{_unitdir}/$SVC.service";

        if [ -e "$SVC_FILE" ]; then
            if [ `grep "^Restart=" $SVC_FILE | wc -l` -gt 0 ]; then
                sed -i -e 's/^Restart=.\+$/Restart=on-failure/;' $SVC_FILE
            else
                sed -i -e '/^\[Service\]$/a Restart=on-failure' $SVC_FILE
            fi
        fi
    done

    systemctl daemon-reload
%else
    /sbin/chkconfig --add gms
    /sbin/chkconfig --enable gms

    /sbin/service gms start
%endif


#===========================================================================
#   Pre-uninstall
#===========================================================================
%preun

#!/bin/sh

#####
#   Global Variables
###
GMS_DIR='BUILD_TARGET_DIR/gms'
GMS_VAR_LIB_DIR="/var/lib/gms"
ACTS_DIR="/var/lib/gms/deploy/rpm_deploy_actions"


#####
#   Helper
###
. /var/lib/gms/functions


#####
#   Logging
###
TIMESTAMP=$(date "+%y%m%d-%H%M%S")

if [ $1 -gt 1 ]; then
    LOG_FILE="/var/log/gms/upgrade"
else
    LOG_FILE="/var/log/gms/uninstall"
fi

LOG_FILE="${LOG_FILE}-${TIMESTAMP}.log"

exec 3>&1
exec 1>&-
exec 2>&-

exec 1>>"$LOG_FILE"
exec 2>&1


#####
#   Main
###
if [ $1 -eq 0 ]; then
    #####
    #    Check whether the node is detached
    ###

    # Determine that the node is detached
    if [ -e "$GMS_VAR_LIB_DIR/initialized" ]; then
        is_init=`cat "$GMS_VAR_LIB_DIR/initialized"`
    else
        is_init=0
    fi

    #####
    # If the node is detached, proceed to clear process
    ###
    if [ "x$is_init" == "x0" ]; then
        # Clear process
        ## Delete node version file in local
        rm -f "$GMS_VAR_LIB_DIR/version"
    else
        log "ERR" "This node is not detached!!"
        exit 1;
    fi

    # - Parse contents of rpm_updates which would be in deploy directory
    # - Revert changes in system/common files refering rpm_updates
    # - Delete copied/moved source files refering rpm_updates
    # - Delete link files refering rpm_updates
    # - Execute revert commands refering rpm_updates
    $ACTS_DIR/rpm_deploy_actions_handler 'undo' "$ACTS_DIR"

    # Delete rpm_updates in deploy directory
    rm -rf "$ACTS_DIR"

    %if ( 0%{?_with_systemd:1} )
        /bin/systemctl stop gms.service
        /bin/systemctl disable gms.service
        /bin/systemctl daemon-reload
    %else
        /sbin/service gms stop

        /sbin/chkconfig --disable gms
        /sbin/chkconfig --del gms
    %endif
fi


#===========================================================================
#   Post-uninstall
#===========================================================================
%postun

#!/bin/sh

#####
#   Global Variables
###

#####
#   Main
###
if [ $1 -eq 0 ]; then
    %if ( 0%{?_with_systemd:1} )
        log "INFO" 'Enabling and starting lvm2-lvmetad...'

        sed -i -e 's/^\(\s\+\)use_lvmetad*$/\1use_lvmetad = 1/;' /etc/lvm/lvm.conf

        systemctl enable lvm2-lvmetad.service
        systemctl start lvm2-lvmetad.service

        log "INFO" 'Restore lvm configuration...'
        lvmconfig --type default --withcomment -f /etc/lvm/lvm.conf

        log "INFO" 'Restore 3rd party package systemd unit file...'

        for SVC in mariadb glusterd ntpd smb ctdb;
        do
            SVC_FILE="%{_unitdir}/$SVC.service";

            if [ -e "$SVC_FILE" ]; then
                if [ "$SVC" == "ctdb" ]; then
                    sed -i -e 's/^Restart=.\+$/Restart=no/' $SVC_FILE
                else
                    sed -i -e '/^Restart=.\+$/d;' $SVC_FILE
                fi
            fi
        done

        systemctl daemon-reload
    %endif
fi


#===========================================================================
# Source files
#===========================================================================
%files

%config %{_sysconfdir}/sysconfig/gms

%if ( 0%{?_with_systemd:1} )
    %config %{_unitdir}/gms.service
%endif

%config %{_sysconfdir}/rsyslog.d/gms.conf
%config %{_sysconfdir}/logrotate.d/gms

%{_prefix}/gms
%{_unitdir}
%{_datadir}/locale


#===========================================================================
# ChangeLog
#===========================================================================
%changelog

* Fri Nov 26 2021 Ji-Hyeon Gim <potatogim@gluesys.com> - 3.1.0-1
- testing

* Tue May 18 2021 Ji-Hyeon Gim <potatogim@gluesys.com> - 3.0.6-1
- release 3.0.6-1

* Fri Mar 26 2021 Ji-Hyeon Gim <potatogim@gluesys.com> 3.0.6-0.rc2
- release 3.0.6 release candidate 2

* Mon Feb 22 2021 Ji-Hyeon Gim <potatogim@gluesys.com> 3.0.6-0.rc1
- release 3.0.6 release candidate 1

* Wed Aug 26 2020 Ji-Hyeon Gim <potatogim@gluesys.com> 3.0.6-0.b1
- release 3.0.6 beta 1

* Sat Aug 08 2020 Ji-Hyeon Gim <potatogim@gluesys.com> 3.0.6-0.a1
- release 3.0.6 alpha 1

* Mon Feb 17 2020 Ji-Hyeon Gim <potatogim@gluesys.com> 3.0.5-2
- release AnyStor-E 3.0.5-2

* Mon Feb 17 2020 Ji-Hyeon Gim <potatogim@gluesys.com> 3.0.5-1
- release AnyStor-E v3.0.5

* Wed Feb 05 2020 Ji-Hyeon Gim <potatogim@gluesys.com> - 3.0.5-0.b1
- 0.b1 released

* Sun Dec 01 2019 Ji-Hyeon Gim <potatogim@gluesys.com> - 3.0.5-0.a1
- 0.a1 released

* Tue Mar 26 2019 Ji-Hyeon Gim <potatogim@gluesys.com> - 3.0.4
- release AnyStor-E v3.0.4
