/*
  Copyright (c) 2017 Red Hat, Inc. <http://www.redhat.com>
  This file is part of GlusterFS.

  This file is licensed to you under your choice of the GNU Lesser
  General Public License, version 3 or any later version (LGPLv3 or
  later), or the GNU General Public License, version 2 (GPLv2), in all
  cases as published by the Free Software Foundation.
*/

#ifndef _SELINUX_MESSAGES_H__
#define _SELINUX_MESSAGES_H__

#include <glusterfs/glfs-message-id.h>

/* To add new message IDs, append new identifiers at the end of the list.
 *
 * Never remove a message ID. If it's not used anymore, you can rename it or
 * leave it as it is, but not delete it. This is to prevent reutilization of
 * IDs by other messages.
 *
 * The component name must match one of the entries defined in
 * glfs-message-id.h.
 */

GLFS_MSGID(SL, SL_MSG_INVALID_VOLFILE, SL_MSG_ENOMEM,
           SL_MSG_MEM_ACCT_INIT_FAILED, SL_MSG_SELINUX_GLUSTER_XATTR_MISSING,
           SL_MSG_SELINUX_XATTR_MISSING);

#endif /*_SELINUX_MESSAGES_H */
