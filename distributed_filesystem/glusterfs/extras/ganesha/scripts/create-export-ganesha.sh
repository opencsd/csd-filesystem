#!/bin/bash

#This script is called by glusterd when the user
#tries to export a volume via NFS-Ganesha.
#An export file specific to a volume
#is created in GANESHA_DIR/exports.

# Try loading the config from any of the distro
# specific configuration locations
if [ -f /etc/sysconfig/ganesha ]
        then
        . /etc/sysconfig/ganesha
fi
if [ -f /etc/conf.d/ganesha ]
        then
        . /etc/conf.d/ganesha
fi
if [ -f /etc/default/ganesha ]
        then
        . /etc/default/ganesha
fi

GANESHA_DIR=${1%/}
OPTION=$2
VOL=$3
CONF=$GANESHA_DIR"/ganesha.conf"
declare -i EXPORT_ID

function check_cmd_status()
{
        if [ "$1" != "0" ]
                 then
                 rm -rf $GANESHA_DIR/exports/export.$VOL.conf
                 sed -i /$VOL.conf/d $CONF
                 exit 1
        fi
}


if [ ! -d "$GANESHA_DIR/exports" ];
        then
        mkdir $GANESHA_DIR/exports
        check_cmd_status `echo $?`
fi

function write_conf()
{
echo -e "# WARNING : Using Gluster CLI will overwrite manual
# changes made to this file. To avoid it, edit the
# file and run ganesha-ha.sh --refresh-config."

echo "EXPORT{"
echo "      Export_Id = 2;"
echo "      Path = \"/$VOL\";"
echo "      FSAL {"
echo "           name = "GLUSTER";"
echo "           hostname=\"localhost\";"
echo  "          volume=\"$VOL\";"
echo "           }"
echo "      Access_type = RW;"
echo "      Disable_ACL = true;"
echo '      Squash="No_root_squash";'
echo "      Pseudo=\"/$VOL\";"
echo '      Protocols = "3", "4" ;'
echo '      Transports = "UDP","TCP";'
echo '      SecType = "sys";'
echo '      Security_Label = False;'
echo "     }"
}
if [ "$OPTION" = "on" ];
then
        if ! (cat $CONF | grep  $VOL.conf\"$ )
        then
                write_conf $@ > $GANESHA_DIR/exports/export.$VOL.conf
                echo "%include \"$GANESHA_DIR/exports/export.$VOL.conf\"" >> $CONF
                count=`ls -l $GANESHA_DIR/exports/*.conf | wc -l`
                if [ "$count" = "1" ] ; then
                        EXPORT_ID=2
                else
                        EXPORT_ID=`cat $GANESHA_DIR/.export_added`
                        check_cmd_status `echo $?`
                        EXPORT_ID=EXPORT_ID+1
                        sed -i s/Export_Id.*/"Export_Id= $EXPORT_ID ;"/ \
                        $GANESHA_DIR/exports/export.$VOL.conf
                        check_cmd_status `echo $?`
                fi
                echo $EXPORT_ID > $GANESHA_DIR/.export_added
        fi
else
        rm -rf $GANESHA_DIR/exports/export.$VOL.conf
        sed -i /$VOL.conf/d $CONF
fi
