// -*- mode:C++; tab-width:8; c-basic-offset:2; indent-tabs-mode:t -*-
// vim: ts=8 sw=2 smarttab
/*
 * Ceph - scalable distributed file system
 *
 * Copyright (C) 2004-2006 Sage Weil <sage@newdream.net>
 *
 * This is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License version 2.1, as published by the Free Software
 * Foundation.  See file COPYING.
 *
 */

#ifndef CEPH_BTRFSFILESTOREBACKEDN_H
#define CEPH_BTRFSFILESTOREBACKEDN_H

#if defined(__linux__)
#include "GenericFileStoreBackend.h"

class BtrfsFileStoreBackend : public GenericFileStoreBackend {
private:
  bool has_clone_range;       ///< clone range ioctl is supported
  bool has_snap_create;       ///< snap create ioctl is supported
  bool has_snap_destroy;      ///< snap destroy ioctl is supported
  bool has_snap_create_v2;    ///< snap create v2 ioctl (async!) is supported
  bool has_wait_sync;         ///< wait sync ioctl is supported
  bool stable_commits;
  bool m_filestore_btrfs_clone_range;
  bool m_filestore_btrfs_snap;
public:
  explicit BtrfsFileStoreBackend(FileStore *fs);
  ~BtrfsFileStoreBackend() override {}
  const char *get_name() override {
    return "btrfs";
  }
  int detect_features() override;
  bool can_checkpoint() override;
  int create_current() override;
  int list_checkpoints(std::list<std::string>& ls) override;
  int create_checkpoint(const std::string& name, uint64_t *cid) override;
  int sync_checkpoint(uint64_t cid) override;
  int rollback_to(const std::string& name) override;
  int destroy_checkpoint(const std::string& name) override;
  int syncfs() override;
  int clone_range(int from, int to, uint64_t srcoff, uint64_t len, uint64_t dstoff) override;
};
#endif
#endif
