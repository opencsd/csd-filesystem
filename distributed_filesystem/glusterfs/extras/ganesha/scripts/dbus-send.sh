#!/bin/bash

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

function check_cmd_status()
{
        if [ "$1" != "0" ]
        then
                logger "dynamic export failed on node :${hostname -s}"
        fi
}

#This function keeps track of export IDs and increments it with every new entry
function dynamic_export_add()
{
        dbus-send  --system \
--dest=org.ganesha.nfsd  /org/ganesha/nfsd/ExportMgr \
org.ganesha.nfsd.exportmgr.AddExport  string:$GANESHA_DIR/exports/export.$VOL.conf \
string:"EXPORT(Path=/$VOL)"
        check_cmd_status `echo $?`
}

#This function removes an export dynamically(uses the export_id of the export)
function dynamic_export_remove()
{
        # Below bash fetch all the export from ShowExport command and search
        # export entry based on path and then get its export entry.
        # There are two possiblities for path, either entire volume will be
        # exported or subdir. It handles both cases. But it remove only first
        # entry from the list based on assumption that entry exported via cli
        # has lowest export id value
	removed_id=$(dbus-send --type=method_call --print-reply --system \
                    --dest=org.ganesha.nfsd /org/ganesha/nfsd/ExportMgr \
                    org.ganesha.nfsd.exportmgr.ShowExports | grep -B 1 -we \
                    "/"$VOL -e "/"$VOL"/" | grep uint16 | awk '{print $2}' \
		    | head -1)

        dbus-send --print-reply --system \
--dest=org.ganesha.nfsd /org/ganesha/nfsd/ExportMgr \
org.ganesha.nfsd.exportmgr.RemoveExport uint16:$removed_id
        check_cmd_status `echo $?`
}

if [ "$OPTION" = "on" ];
then
        dynamic_export_add $@
fi

if [ "$OPTION" = "off" ];
then
        dynamic_export_remove $@
fi
