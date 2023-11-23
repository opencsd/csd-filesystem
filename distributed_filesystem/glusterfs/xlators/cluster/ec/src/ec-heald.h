/*
  Copyright (c) 2015 Red Hat, Inc. <http://www.redhat.com>
  This file is part of GlusterFS.

  This file is licensed to you under your choice of the GNU Lesser
  General Public License, version 3 or any later version (LGPLv3 or
  later), or the GNU General Public License, version 2 (GPLv2), in all
  cases as published by the Free Software Foundation.
*/

#ifndef __EC_HEALD_H__
#define __EC_HEALD_H__

#include "ec-types.h"           // for ec_t
#include "glusterfs/dict.h"     // for dict_t
#include "glusterfs/globals.h"  // for xlator_t

int
ec_xl_op(xlator_t *this, dict_t *input, dict_t *output);

int
ec_selfheal_daemon_init(xlator_t *this);

void
ec_shd_index_healer_wake(ec_t *ec);

void
ec_selfheal_daemon_fini(xlator_t *this);

#endif /* __EC_HEALD_H__ */
