#!/usr/bin/python3
# -*- coding: utf-8 -*-

# Copyright (c) 2015 Red Hat, Inc. <http://www.redhat.com/>
# This file is part of GlusterFS.
#
# This file is licensed to you under your choice of the GNU Lesser
# General Public License, version 3 or any later version (LGPLv3 or
# later), or the GNU General Public License, version 2 (GPLv2), in all
# cases as published by the Free Software Foundation.

import sys
from errno import ENOENT, ENOTEMPTY
import time
from multiprocessing import Process
import os
import xml.etree.cElementTree as etree
from argparse import ArgumentParser, RawDescriptionHelpFormatter, Action
from gfind_py2py3 import gfind_write_row, gfind_write
import logging
import shutil
import tempfile
import signal
from datetime import datetime
import codecs
import re

from utils import execute, is_host_local, mkdirp, fail
from utils import setup_logger, human_time, handle_rm_error
from utils import get_changelog_rollover_time, cache_output, create_file
import conf
from changelogdata import OutputMerger

PROG_DESCRIPTION = """
GlusterFS Incremental API
"""
ParseError = etree.ParseError if hasattr(etree, 'ParseError') else SyntaxError

logger = logging.getLogger()
vol_statusStr = ""
gtmpfilename = None
g_pid_nodefile_map = {}


class StoreAbsPath(Action):
    def __init__(self, option_strings, dest, nargs=None, **kwargs):
        super(StoreAbsPath, self).__init__(option_strings, dest, **kwargs)

    def __call__(self, parser, namespace, values, option_string=None):
        setattr(namespace, self.dest, os.path.abspath(values))


def get_pem_key_path(session, volume):
    return os.path.join(conf.get_opt("session_dir"),
                        session,
                        volume,
                        "%s_%s_secret.pem" % (session, volume))


def node_cmd(host, host_uuid, task, cmd, args, opts):
    """
    Runs command via ssh if host is not local
    """
    try:
        localdir = is_host_local(host_uuid)

        # this is so to avoid deleting the ssh keys on local node which
        # otherwise cause ssh password prompts on the console (race conditions)
        # mode_delete() should be cleaning up the session tree
        if localdir and task == "delete":
            return

        pem_key_path = get_pem_key_path(args.session, args.volume)

        if not localdir:
            # prefix with ssh command if not local node
            cmd = ["ssh",
                   "-oNumberOfPasswordPrompts=0",
                   "-oStrictHostKeyChecking=no",
                   # We force TTY allocation (-t -t) so that Ctrl+C is handed
                   # through; see:
                   #   https://bugzilla.redhat.com/show_bug.cgi?id=1382236
                   # Note that this turns stderr of the remote `cmd`
                   # into stdout locally.
                   "-t",
                   "-t",
                   "-i", pem_key_path,
                   "root@%s" % host] + cmd

        (returncode, err, out) = execute(cmd, logger=logger)
        if returncode != 0:
            # Because the `-t -t` above turns the remote stderr into
            # local stdout, we need to log both stderr and stdout
            # here to print all error messages.
            fail("%s - %s failed; stdout (including remote stderr):\n"
                 "%s\n"
                 "stderr:\n"
                 "%s" % (host, task, out, err),
                 returncode,
                 logger=logger)

        if opts.get("copy_outfile", False) and not localdir:
            cmd_copy = ["scp",
                        "-oNumberOfPasswordPrompts=0",
                        "-oStrictHostKeyChecking=no",
                        "-i", pem_key_path,
                        "root@%s:/%s" % (host, opts.get("node_outfile")),
                        os.path.dirname(opts.get("node_outfile"))]
            execute(cmd_copy, exit_msg="%s - Copy command failed" % host,
                    logger=logger)
    except KeyboardInterrupt:
        sys.exit(2)


def run_cmd_nodes(task, args, **kwargs):
    global g_pid_nodefile_map
    nodes = get_nodes(args.volume)
    pool = []
    for num, node in enumerate(nodes):
        host, brick = node[1].split(":")
        host_uuid = node[0]
        cmd = []
        opts = {}

        # tmpfilename is valid only for tasks: pre, query and cleanup
        tmpfilename = kwargs.get("tmpfilename", "BADNAME")

        node_outfile = os.path.join(conf.get_opt("working_dir"),
                                    args.session, args.volume,
                                    tmpfilename,
                                    "tmp_output_%s" % num)

        if task == "pre":
            if vol_statusStr != "Started":
                fail("Volume %s is not online" % args.volume,
                     logger=logger)

            # If Full backup is requested or start time is zero, use brickfind
            change_detector = conf.get_change_detector("changelog")
            tag = None
            if args.full:
                change_detector = conf.get_change_detector("brickfind")
                tag = args.tag_for_full_find.strip()
                if tag == "":
                    tag = '""' if not is_host_local(host_uuid) else ""

            # remote file will be copied into this directory
            mkdirp(os.path.dirname(node_outfile),
                   exit_on_err=True, logger=logger)

            FS = args.field_separator
            if not is_host_local(host_uuid):
                FS = "'" + FS + "'"

            cmd = [change_detector,
                   args.session,
                   args.volume,
                   host,
                   brick,
                   node_outfile] + \
                ([str(kwargs.get("start")), str(kwargs.get("end"))]
                    if not args.full else []) + \
                ([tag] if tag is not None else []) + \
                ["--output-prefix", args.output_prefix] + \
                (["--debug"] if args.debug else []) + \
                (["--no-encode"] if args.no_encode else []) + \
                (["--only-namespace-changes"] if args.only_namespace_changes
                 else []) + \
                (["--type", args.type]) + \
                (["--field-separator", FS] if args.full else [])

            opts["node_outfile"] = node_outfile
            opts["copy_outfile"] = True
        elif task == "query":
            # If Full backup is requested or start time is zero, use brickfind
            tag = None
            change_detector = conf.get_change_detector("changelog")
            if args.full:
                change_detector = conf.get_change_detector("brickfind")
                tag = args.tag_for_full_find.strip()
                if tag == "":
                    tag = '""' if not is_host_local(host_uuid) else ""

            # remote file will be copied into this directory
            mkdirp(os.path.dirname(node_outfile),
                   exit_on_err=True, logger=logger)

            FS = args.field_separator
            if not is_host_local(host_uuid):
                FS = "'" + FS + "'"

            cmd = [change_detector,
                   args.session,
                   args.volume,
                   host,
                   brick,
                   node_outfile] + \
                ([str(kwargs.get("start")), str(kwargs.get("end"))]
                    if not args.full else []) + \
                ([tag] if tag is not None else []) + \
                ["--only-query"] + \
                ["--output-prefix", args.output_prefix] + \
                (["--debug"] if args.debug else []) + \
                (["--no-encode"] if args.no_encode else []) + \
                (["--only-namespace-changes"]
                    if args.only_namespace_changes else []) + \
                (["--type", args.type]) + \
                (["--field-separator", FS] if args.full else [])

            opts["node_outfile"] = node_outfile
            opts["copy_outfile"] = True
        elif task == "cleanup":
            # After pre/query run, cleanup the working directory and other
            # temp files. Remove the directory to which node_outfile has
            # been copied in main node
            try:
                os.remove(node_outfile)
            except (OSError, IOError):
                logger.warn("Failed to cleanup temporary file %s" %
                            node_outfile)
                pass

            cmd = [conf.get_opt("nodeagent"),
                   "cleanup",
                   args.session,
                   args.volume,
                   os.path.dirname(node_outfile)] + \
                (["--debug"] if args.debug else [])
        elif task == "create":
            if vol_statusStr != "Started":
                fail("Volume %s is not online" % args.volume,
                     logger=logger)

            # When glusterfind create, create session directory in
            # each brick nodes
            cmd = [conf.get_opt("nodeagent"),
                   "create",
                   args.session,
                   args.volume,
                   brick,
                   kwargs.get("time_to_update")] + \
                (["--debug"] if args.debug else []) + \
                (["--reset-session-time"] if args.reset_session_time
                 else [])
        elif task == "post":
            # Rename pre status file to actual status file in each node
            cmd = [conf.get_opt("nodeagent"),
                   "post",
                   args.session,
                   args.volume,
                   brick] + \
                (["--debug"] if args.debug else [])
        elif task == "delete":
            # When glusterfind delete, cleanup all the session files/dirs
            # from each node.
            cmd = [conf.get_opt("nodeagent"),
                   "delete",
                   args.session,
                   args.volume] + \
                (["--debug"] if args.debug else [])

        if cmd:
            p = Process(target=node_cmd,
                        args=(host, host_uuid, task, cmd, args, opts))
            p.start()
            pool.append(p)
            g_pid_nodefile_map[p.pid] = node_outfile

    for num, p in enumerate(pool):
        p.join()
        if p.exitcode != 0:
            logger.warn("Command %s failed in %s" % (task, nodes[num][1]))
            if task in ["create", "delete"]:
                fail("Command %s failed in %s" % (task, nodes[num][1]))
            elif task == "pre" or task == "query":
                if args.disable_partial:
                    sys.exit(1)
                else:
                    del g_pid_nodefile_map[p.pid]


@cache_output
def get_nodes(volume):
    """
    Get the gluster volume info xml output and parse to get
    the brick details.
    """
    global vol_statusStr

    cmd = ["gluster", 'volume', 'info', volume, "--xml"]
    _, data, _ = execute(cmd,
                         exit_msg="Failed to Run Gluster Volume Info",
                         logger=logger)
    tree = etree.fromstring(data)

    # Test to check if volume has been deleted after session creation
    count_el = tree.find('volInfo/volumes/count')
    if int(count_el.text) == 0:
        fail("Unable to get volume details", logger=logger)

    # this status is used in caller: run_cmd_nodes
    vol_statusStr = tree.find('volInfo/volumes/volume/statusStr').text
    vol_typeStr = tree.find('volInfo/volumes/volume/typeStr').text

    nodes = []
    volume_el = tree.find('volInfo/volumes/volume')
    try:
        brick_elems = []
        if vol_typeStr == "Tier":
            brick_elems.append('bricks/hotBricks/brick')
            brick_elems.append('bricks/coldBricks/brick')
        else:
            brick_elems.append('bricks/brick')

        for elem in brick_elems:
            for b in volume_el.findall(elem):
                nodes.append((b.find('hostUuid').text,
                              b.find('name').text))
    except (ParseError, AttributeError, ValueError) as e:
        fail("Failed to parse Volume Info: %s" % e, logger=logger)

    return nodes


def _get_args():
    parser = ArgumentParser(formatter_class=RawDescriptionHelpFormatter,
                            description=PROG_DESCRIPTION)
    subparsers = parser.add_subparsers(dest="mode")
    subparsers.required = True

    # create <SESSION> <VOLUME> [--debug] [--force]
    parser_create = subparsers.add_parser('create')
    parser_create.add_argument("session", help="Session Name")
    parser_create.add_argument("volume", help="Volume Name")
    parser_create.add_argument("--debug", help="Debug", action="store_true")
    parser_create.add_argument("--force", help="Force option to recreate "
                               "the session", action="store_true")
    parser_create.add_argument("--reset-session-time",
                               help="Reset Session Time to Current Time",
                               action="store_true")

    # delete <SESSION> <VOLUME> [--debug]
    parser_delete = subparsers.add_parser('delete')
    parser_delete.add_argument("session", help="Session Name")
    parser_delete.add_argument("volume", help="Volume Name")
    parser_delete.add_argument("--debug", help="Debug", action="store_true")

    # list [--session <SESSION>] [--volume <VOLUME>]
    parser_list = subparsers.add_parser('list')
    parser_list.add_argument("--session", help="Session Name", default="")
    parser_list.add_argument("--volume", help="Volume Name", default="")
    parser_list.add_argument("--debug", help="Debug", action="store_true")

    # pre <SESSION> <VOLUME> <OUTFILE>
    #     [--output-prefix <OUTPUT_PREFIX>] [--full]
    parser_pre = subparsers.add_parser('pre')
    parser_pre.add_argument("session", help="Session Name")
    parser_pre.add_argument("volume", help="Volume Name")
    parser_pre.add_argument("outfile", help="Output File", action=StoreAbsPath)
    parser_pre.add_argument("--debug", help="Debug", action="store_true")
    parser_pre.add_argument("--no-encode",
                            help="Do not encode path in output file",
                            action="store_true")
    parser_pre.add_argument("--full", help="Full find", action="store_true")
    parser_pre.add_argument("--disable-partial", help="Disable Partial find, "
                            "Fail when one node fails", action="store_true")
    parser_pre.add_argument("--output-prefix", help="File prefix in output",
                            default=".")
    parser_pre.add_argument("--regenerate-outfile",
                            help="Regenerate outfile, discard the outfile "
                            "generated from last pre command",
                            action="store_true")
    parser_pre.add_argument("-N", "--only-namespace-changes",
                            help="List only namespace changes",
                            action="store_true")
    parser_pre.add_argument("--tag-for-full-find",
                            help="Tag prefix for file names emitted during"
                            " a full find operation; default: \"NEW\"",
                            default="NEW")
    parser_pre.add_argument('--type', help="type: f, f-files only"
                            " d, d-directories only, by default = both",
                            default='both', choices=["f", "d", "both"])
    parser_pre.add_argument("--field-separator", help="Field separator string",
                            default=" ")

    # query <VOLUME> <OUTFILE> --since-time <SINCE_TIME>
    #       [--output-prefix <OUTPUT_PREFIX>] [--full]
    parser_query = subparsers.add_parser('query')
    parser_query.add_argument("volume", help="Volume Name")
    parser_query.add_argument("outfile", help="Output File",
                              action=StoreAbsPath)
    parser_query.add_argument("--since-time", help="UNIX epoch time since "
                              "which listing is required", type=int)
    parser_query.add_argument("--end-time", help="UNIX epoch time up to "
                              "which listing is required", type=int)
    parser_query.add_argument("--no-encode",
                              help="Do not encode path in output file",
                              action="store_true")
    parser_query.add_argument("--full", help="Full find", action="store_true")
    parser_query.add_argument("--debug", help="Debug", action="store_true")
    parser_query.add_argument("--disable-partial", help="Disable Partial find,"
                              " Fail when one node fails", action="store_true")
    parser_query.add_argument("--output-prefix", help="File prefix in output",
                              default=".")
    parser_query.add_argument("-N", "--only-namespace-changes",
                              help="List only namespace changes",
                              action="store_true")
    parser_query.add_argument("--tag-for-full-find",
                              help="Tag prefix for file names emitted during"
                              " a full find operation; default: \"NEW\"",
                              default="NEW")
    parser_query.add_argument('--type', help="type: f, f-files only"
                              " d, d-directories only, by default = both",
                              default='both', choices=["f", "d", "both"])
    parser_query.add_argument("--field-separator",
                              help="Field separator string",
                              default=" ")

    # post <SESSION> <VOLUME>
    parser_post = subparsers.add_parser('post')
    parser_post.add_argument("session", help="Session Name")
    parser_post.add_argument("volume", help="Volume Name")
    parser_post.add_argument("--debug", help="Debug", action="store_true")

    return parser.parse_args()


def ssh_setup(args):
    pem_key_path = get_pem_key_path(args.session, args.volume)

    if not os.path.exists(pem_key_path):
        # Generate ssh-key
        cmd = ["ssh-keygen",
               "-N",
               "",
               "-f",
               pem_key_path]
        execute(cmd,
                exit_msg="Unable to generate ssh key %s"
                % pem_key_path,
                logger=logger)

        logger.info("Ssh key generated %s" % pem_key_path)

    try:
        shutil.copyfile(pem_key_path + ".pub",
                        os.path.join(conf.get_opt("session_dir"),
                                     ".keys",
                                     "%s_%s_secret.pem.pub" % (args.session,
                                                               args.volume)))
    except (IOError, OSError) as e:
        fail("Failed to copy public key to %s: %s"
             % (os.path.join(conf.get_opt("session_dir"), ".keys"), e),
             logger=logger)

    # Copy pub file to all nodes
    cmd = ["gluster",
           "system::",
           "copy",
           "file",
           "/glusterfind/.keys/%s.pub" % os.path.basename(pem_key_path)]

    execute(cmd, exit_msg="Failed to distribute ssh keys", logger=logger)

    logger.info("Distributed ssh key to all nodes of Volume")

    # Add to authorized_keys file in each node
    cmd = ["gluster",
           "system::",
           "execute",
           "add_secret_pub",
           "root",
           "/glusterfind/.keys/%s.pub" % os.path.basename(pem_key_path)]
    execute(cmd,
            exit_msg="Failed to add ssh keys to authorized_keys file",
            logger=logger)

    logger.info("Ssh key added to authorized_keys of Volume nodes")


def enable_volume_options(args):
    execute(["gluster", "volume", "set",
             args.volume, "build-pgfid", "on"],
            exit_msg="Failed to set volume option build-pgfid on",
            logger=logger)
    logger.info("Volume option set %s, build-pgfid on" % args.volume)

    execute(["gluster", "volume", "set",
             args.volume, "changelog.changelog", "on"],
            exit_msg="Failed to set volume option "
            "changelog.changelog on", logger=logger)
    logger.info("Volume option set %s, changelog.changelog on"
                % args.volume)

    execute(["gluster", "volume", "set",
             args.volume, "changelog.capture-del-path", "on"],
            exit_msg="Failed to set volume option "
            "changelog.capture-del-path on", logger=logger)
    logger.info("Volume option set %s, changelog.capture-del-path on"
                % args.volume)


def write_output(outfile, outfilemerger, field_separator):
    with codecs.open(outfile, "a", encoding="utf-8") as f:
        for row in outfilemerger.get():
            # Multiple paths in case of Hardlinks
            paths = row[1].split(",")
            row_2_rep = None
            for p in paths:
                if p == "":
                    continue
                p_rep = p.replace("//", "/")
                if not row_2_rep:
                    row_2_rep = row[2].replace("//", "/")
                if p_rep == row_2_rep:
                    continue

                if row_2_rep and row_2_rep != "":
                    gfind_write_row(f, row[0], field_separator, p_rep, row_2_rep)

                else:
                    gfind_write(f, row[0], field_separator, p_rep)

def validate_volume(volume):
    cmd = ["gluster", 'volume', 'info', volume, "--xml"]
    _, data, _ = execute(cmd,
                         exit_msg="Failed to Run Gluster Volume Info",
                         logger=logger)
    try:
        tree = etree.fromstring(data)
        statusStr = tree.find('volInfo/volumes/volume/statusStr').text
    except (ParseError, AttributeError) as e:
        fail("Invalid Volume: Check the Volume name! %s" % e)
    if statusStr != "Started":
        fail("Volume %s is not online" % volume)

# The rules for a valid session name.
SESSION_NAME_RULES = {
    'min_length': 2,
    'max_length': 256,  # same as maximum volume length
    # Specifies all alphanumeric characters, underscore, hyphen.
    'valid_chars': r'0-9a-zA-Z_-',
}


# checks valid session name, fail otherwise
def validate_session_name(session):
    # Check for minimum length
    if len(session) < SESSION_NAME_RULES['min_length']:
        fail('session_name must be at least ' +
                 str(SESSION_NAME_RULES['min_length']) + ' characters long.')
    # Check for maximum length
    if len(session) > SESSION_NAME_RULES['max_length']:
        fail('session_name must not exceed ' +
                 str(SESSION_NAME_RULES['max_length']) + ' characters length.')

    # Matches strings composed entirely of characters specified within
    if not re.match(r'^[' + SESSION_NAME_RULES['valid_chars'] +
                        ']+$', session):
        fail('Session name can only contain these characters: ' +
                         SESSION_NAME_RULES['valid_chars'])


def mode_create(session_dir, args):
    validate_session_name(args.session)

    logger.debug("Init is called - Session: %s, Volume: %s"
                 % (args.session, args.volume))
    mkdirp(session_dir, exit_on_err=True, logger=logger)
    mkdirp(os.path.join(session_dir, args.volume), exit_on_err=True,
           logger=logger)
    status_file = os.path.join(session_dir, args.volume, "status")

    if os.path.exists(status_file) and not args.force:
        fail("Session %s already created" % args.session, logger=logger)

    if not os.path.exists(status_file) or args.force:
        ssh_setup(args)
        enable_volume_options(args)

    # Add Rollover time to current time to make sure changelogs
    # will be available if we use this time as start time
    time_to_update = int(time.time()) + get_changelog_rollover_time(
        args.volume)

    run_cmd_nodes("create", args, time_to_update=str(time_to_update))

    if not os.path.exists(status_file) or args.reset_session_time:
        with open(status_file, "w") as f:
            f.write(str(time_to_update))

    sys.stdout.write("Session %s created with volume %s\n" %
                     (args.session, args.volume))

    sys.exit(0)


def mode_query(session_dir, args):
    global gtmpfilename
    global g_pid_nodefile_map

    # Verify volume status
    cmd = ["gluster", 'volume', 'info', args.volume, "--xml"]
    _, data, _ = execute(cmd,
                         exit_msg="Failed to Run Gluster Volume Info",
                         logger=logger)
    try:
        tree = etree.fromstring(data)
        statusStr = tree.find('volInfo/volumes/volume/statusStr').text
    except (ParseError, AttributeError) as e:
        fail("Invalid Volume: %s" % e, logger=logger)

    if statusStr != "Started":
        fail("Volume %s is not online" % args.volume, logger=logger)

    mkdirp(session_dir, exit_on_err=True, logger=logger)
    mkdirp(os.path.join(session_dir, args.volume), exit_on_err=True,
           logger=logger)
    mkdirp(os.path.dirname(args.outfile), exit_on_err=True, logger=logger)

    # Configure cluster for pasword-less SSH
    ssh_setup(args)

    # Enable volume options for changelog capture
    enable_volume_options(args)

    # Test options
    if not args.full and args.type in ["f", "d"]:
        fail("--type can only be used with --full")
    if not args.since_time and not args.end_time and not args.full:
        fail("Please specify either {--since-time and optionally --end-time} "
             "or --full", logger=logger)

    if args.since_time and args.end_time and args.full:
        fail("Please specify either {--since-time and optionally --end-time} "
             "or --full, but not both",
             logger=logger)

    if args.end_time and not args.since_time:
        fail("Please specify --since-time as well", logger=logger)

    # Start query command processing
    start = -1
    end = -1
    if args.since_time:
        start = args.since_time
        if args.end_time:
            end = args.end_time
    else:
        start = 0  # --full option is handled separately

    logger.debug("Query is called - Session: %s, Volume: %s, "
                 "Start time: %s, End time: %s"
                 % ("default", args.volume, start, end))

    prefix = datetime.now().strftime("%Y%m%d-%H%M%S-%f-")
    gtmpfilename = prefix + next(tempfile._get_candidate_names())

    run_cmd_nodes("query", args, start=start, end=end,
                  tmpfilename=gtmpfilename)

    # Merger
    if args.full:
        if len(g_pid_nodefile_map) > 0:
            cmd = ["sort", "-u"] + list(g_pid_nodefile_map.values()) + \
                  ["-o", args.outfile]
            execute(cmd,
                    exit_msg="Failed to merge output files "
                    "collected from nodes", logger=logger)
        else:
            fail("Failed to collect any output files from peers. "
                 "Looks like all bricks are offline.", logger=logger)
    else:
        # Read each Changelogs db and generate finaldb
        create_file(args.outfile, exit_on_err=True, logger=logger)
        outfilemerger = OutputMerger(args.outfile + ".db",
                                     list(g_pid_nodefile_map.values()))
        write_output(args.outfile, outfilemerger, args.field_separator)

    try:
        os.remove(args.outfile + ".db")
    except (IOError, OSError):
        pass

    run_cmd_nodes("cleanup", args, tmpfilename=gtmpfilename)

    sys.stdout.write("Generated output file %s\n" % args.outfile)


def mode_pre(session_dir, args):
    global gtmpfilename
    global g_pid_nodefile_map

    """
    Read from Session file and write to session.pre file
    """
    endtime_to_update = int(time.time()) - get_changelog_rollover_time(
        args.volume)
    status_file = os.path.join(session_dir, args.volume, "status")
    status_file_pre = status_file + ".pre"

    mkdirp(os.path.dirname(args.outfile), exit_on_err=True, logger=logger)

    if not args.full and args.type in ["f", "d"]:
        fail("--type can only be used with --full")

    # If Pre status file exists and running pre command again
    if os.path.exists(status_file_pre) and not args.regenerate_outfile:
        fail("Post command is not run after last pre, "
             "use --regenerate-outfile")

    start = 0
    try:
        with open(status_file) as f:
            start = int(f.read().strip())
    except ValueError:
        pass
    except (OSError, IOError) as e:
        fail("Error Opening Session file %s: %s"
             % (status_file, e), logger=logger)

    logger.debug("Pre is called - Session: %s, Volume: %s, "
                 "Start time: %s, End time: %s"
                 % (args.session, args.volume, start, endtime_to_update))

    prefix = datetime.now().strftime("%Y%m%d-%H%M%S-%f-")
    gtmpfilename = prefix + next(tempfile._get_candidate_names())

    run_cmd_nodes("pre", args, start=start, end=-1, tmpfilename=gtmpfilename)

    # Merger
    if args.full:
        if len(g_pid_nodefile_map) > 0:
            cmd = ["sort", "-u"] + list(g_pid_nodefile_map.values()) + \
                  ["-o", args.outfile]
            execute(cmd,
                    exit_msg="Failed to merge output files "
                    "collected from nodes", logger=logger)
        else:
            fail("Failed to collect any output files from peers. "
                 "Looks like all bricks are offline.", logger=logger)
    else:
        # Read each Changelogs db and generate finaldb
        create_file(args.outfile, exit_on_err=True, logger=logger)
        outfilemerger = OutputMerger(args.outfile + ".db",
                                     list(g_pid_nodefile_map.values()))
        write_output(args.outfile, outfilemerger, args.field_separator)

    try:
        os.remove(args.outfile + ".db")
    except (IOError, OSError):
        pass

    run_cmd_nodes("cleanup", args, tmpfilename=gtmpfilename)

    with open(status_file_pre, "w") as f:
        f.write(str(endtime_to_update))

    sys.stdout.write("Generated output file %s\n" % args.outfile)


def mode_post(session_dir, args):
    """
    If pre session file exists, overwrite session file
    If pre session file does not exists, return ERROR
    """
    status_file = os.path.join(session_dir, args.volume, "status")
    logger.debug("Post is called - Session: %s, Volume: %s"
                 % (args.session, args.volume))
    status_file_pre = status_file + ".pre"

    if os.path.exists(status_file_pre):
        run_cmd_nodes("post", args)
        os.rename(status_file_pre, status_file)
        sys.stdout.write("Session %s with volume %s updated\n" %
                         (args.session, args.volume))
        sys.exit(0)
    else:
        fail("Pre script is not run", logger=logger)


def mode_delete(session_dir, args):
    run_cmd_nodes("delete", args)
    shutil.rmtree(os.path.join(session_dir, args.volume),
                  onerror=handle_rm_error)
    sys.stdout.write("Session %s with volume %s deleted\n" %
                     (args.session, args.volume))

    # If the session contains only this volume, then cleanup the
    # session directory. If a session contains multiple volumes
    # then os.rmdir will fail with ENOTEMPTY
    try:
        os.rmdir(session_dir)
    except OSError as e:
        if not e.errno == ENOTEMPTY:
            logger.warn("Failed to delete session directory: %s" % e)


def mode_list(session_dir, args):
    """
    List available sessions to stdout, if session name is set
    only list that session.
    """
    if args.session:
        if not os.path.exists(os.path.join(session_dir, args.session)):
            fail("Invalid Session", logger=logger)
        sessions = [args.session]
    else:
        sessions = []
        for d in os.listdir(session_dir):
            if d != ".keys":
                sessions.append(d)

    output = []
    for session in sessions:
        # Session Volume Last Processed
        volnames = os.listdir(os.path.join(session_dir, session))

        for volname in volnames:
            if args.volume and args.volume != volname:
                continue

            status_file = os.path.join(session_dir, session, volname, "status")
            last_processed = None
            try:
                with open(status_file) as f:
                    last_processed = f.read().strip()
            except (OSError, IOError) as e:
                if e.errno == ENOENT:
                    continue
                else:
                    raise
            output.append((session, volname, last_processed))

    if output:
        sys.stdout.write("%s %s %s\n" % ("SESSION".ljust(25),
                                         "VOLUME".ljust(25),
                                         "SESSION TIME".ljust(25)))
        sys.stdout.write("-"*75)
        sys.stdout.write("\n")
    for session, volname, last_processed in output:
        sess_time = 'Session Corrupted'
        if last_processed:
            try:
                sess_time = human_time(last_processed)
            except TypeError:
                sess_time = 'Session Corrupted'
        sys.stdout.write("%s %s %s\n" % (session.ljust(25),
                                         volname.ljust(25),
                                         sess_time.ljust(25)))

    if not output:
        if args.session or args.volume:
            fail("Invalid Session", logger=logger)
        else:
            sys.stdout.write("No sessions found.\n")


def main():
    global gtmpfilename

    args = None

    try:
        args = _get_args()
        mkdirp(conf.get_opt("session_dir"), exit_on_err=True)

        # force the default session name if mode is "query"
        if args.mode == "query":
            args.session = "default"

        if args.mode == "list":
            session_dir = conf.get_opt("session_dir")
        else:
            session_dir = os.path.join(conf.get_opt("session_dir"),
                                       args.session)

        if not os.path.exists(session_dir) and \
                args.mode not in ["create", "list", "query"]:
            fail("Invalid session %s" % args.session)

        # volume involved, validate the volume first
        if args.mode not in ["list"]:
            validate_volume(args.volume)


        # "default" is a system defined session name
        if args.mode in ["create", "post", "pre", "delete"] and \
                args.session == "default":
            fail("Invalid session %s" % args.session)

        vol_dir = os.path.join(session_dir, args.volume)
        if not os.path.exists(vol_dir) and args.mode not in \
                ["create", "list", "query"]:
            fail("Session %s not created with volume %s" %
                 (args.session, args.volume))

        mkdirp(os.path.join(conf.get_opt("log_dir"),
                            args.session,
                            args.volume),
               exit_on_err=True)
        log_file = os.path.join(conf.get_opt("log_dir"),
                                args.session,
                                args.volume,
                                "cli.log")
        setup_logger(logger, log_file, args.debug)

        # globals() will have all the functions already defined.
        # mode_<args.mode> will be the function name to be called
        globals()["mode_" + args.mode](session_dir, args)
    except KeyboardInterrupt:
        if args is not None:
            if args.mode == "pre" or args.mode == "query":
                # cleanup session
                if gtmpfilename is not None:
                    # no more interrupts until we clean up
                    signal.signal(signal.SIGINT, signal.SIG_IGN)
                    run_cmd_nodes("cleanup", args, tmpfilename=gtmpfilename)

        # Interrupted, exit with non zero error code
        sys.exit(2)
