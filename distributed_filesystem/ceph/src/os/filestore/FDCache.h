// -*- mode:C++; tab-width:8; c-basic-offset:2; indent-tabs-mode:t -*-
// vim: ts=8 sw=2 smarttab
/*
 * Ceph - scalable distributed file system
 *
 * Copyright (C) 2013 Inktank Storage, Inc.
 *
 * This is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License version 2.1, as published by the Free Software
 * Foundation.  See file COPYING.
 *
 */

#ifndef CEPH_FDCACHE_H
#define CEPH_FDCACHE_H

#include <memory>
#include <errno.h>
#include <cstdio>
#include "common/config_obs.h"
#include "common/hobject.h"
#include "common/shared_cache.hpp"
#include "include/compat.h"
#include "include/intarith.h"

/**
 * FD Cache
 */
class FDCache : public md_config_obs_t {
public:
  /**
   * FD
   *
   * Wrapper for an fd.  Destructor closes the fd.
   */
  class FD {
  public:
    const int fd;
    explicit FD(int _fd) : fd(_fd) {
      ceph_assert(_fd >= 0);
    }
    int operator*() const {
      return fd;
    }
    ~FD() {
      VOID_TEMP_FAILURE_RETRY(::close(fd));
    }
  };

private:
  CephContext *cct;
  const int registry_shards;
  SharedLRU<ghobject_t, FD> *registry;

public:
  explicit FDCache(CephContext *cct) : cct(cct),
  registry_shards(std::max<int64_t>(cct->_conf->filestore_fd_cache_shards, 1)) {
    ceph_assert(cct);
    cct->_conf.add_observer(this);
    registry = new SharedLRU<ghobject_t, FD>[registry_shards];
    for (int i = 0; i < registry_shards; ++i) {
      registry[i].set_cct(cct);
      registry[i].set_size(
          std::max<int64_t>((cct->_conf->filestore_fd_cache_size / registry_shards), 1));
    }
  }
  ~FDCache() override {
    cct->_conf.remove_observer(this);
    delete[] registry;
  }
  typedef std::shared_ptr<FD> FDRef;

  FDRef lookup(const ghobject_t &hoid) {
    int registry_id = hoid.hobj.get_hash() % registry_shards;
    return registry[registry_id].lookup(hoid);
  }

  FDRef add(const ghobject_t &hoid, int fd, bool *existed) {
    int registry_id = hoid.hobj.get_hash() % registry_shards;
    return registry[registry_id].add(hoid, new FD(fd), existed);
  }

  /// clear cached fd for hoid, subsequent lookups will get an empty FD
  void clear(const ghobject_t &hoid) {
    int registry_id = hoid.hobj.get_hash() % registry_shards;
    registry[registry_id].purge(hoid);
  }

  /// md_config_obs_t
  const char** get_tracked_conf_keys() const override {
    static const char* KEYS[] = {
      "filestore_fd_cache_size",
      NULL
    };
    return KEYS;
  }
  void handle_conf_change(const ConfigProxy& conf,
			  const std::set<std::string> &changed) override {
    if (changed.count("filestore_fd_cache_size")) {
      for (int i = 0; i < registry_shards; ++i)
        registry[i].set_size(
              std::max<int64_t>((conf->filestore_fd_cache_size / registry_shards), 1));
    }
  }

};
typedef FDCache::FDRef FDRef;

#endif
