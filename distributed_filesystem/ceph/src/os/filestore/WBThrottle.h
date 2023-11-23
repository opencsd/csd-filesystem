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

#ifndef WBTHROTTLE_H
#define WBTHROTTLE_H

#include "include/unordered_map.h"
#include <boost/tuple/tuple.hpp>
#include "common/Formatter.h"
#include "common/hobject.h"
#include "include/interval_set.h"
#include "include/common_fwd.h"
#include "FDCache.h"
#include "common/Thread.h"
#include "common/ceph_context.h"

enum {
  l_wbthrottle_first = 999090,
  l_wbthrottle_bytes_dirtied,
  l_wbthrottle_bytes_wb,
  l_wbthrottle_ios_dirtied,
  l_wbthrottle_ios_wb,
  l_wbthrottle_inodes_dirtied,
  l_wbthrottle_inodes_wb,
  l_wbthrottle_last
};

/**
 * WBThrottle
 *
 * Tracks, throttles, and flushes outstanding IO
 */
class WBThrottle : Thread, public md_config_obs_t {
  ghobject_t clearing;
  /* *_limits.first is the start_flusher limit and
   * *_limits.second is the hard limit
   */

  /// Limits on unflushed bytes
  std::pair<uint64_t, uint64_t> size_limits;

  /// Limits on unflushed ios
  std::pair<uint64_t, uint64_t> io_limits;

  /// Limits on unflushed objects
  std::pair<uint64_t, uint64_t> fd_limits;

  uint64_t cur_ios;  /// Currently unflushed IOs
  uint64_t cur_size; /// Currently unflushed bytes

  /**
   * PendingWB tracks the ios pending on an object.
   */
  class PendingWB {
  public:
    bool nocache;
    uint64_t size;
    uint64_t ios;
    PendingWB() : nocache(true), size(0), ios(0) {}
    void add(bool _nocache, uint64_t _size, uint64_t _ios) {
      if (!_nocache)
	nocache = false; // only nocache if all writes are nocache
      size += _size;
      ios += _ios;
    }
  };

  CephContext *cct;
  PerfCounters *logger;
  bool stopping;
  ceph::mutex lock = ceph::make_mutex("WBThrottle::lock");
  ceph::condition_variable cond;


  /**
   * Flush objects in lru order
   */
  std::list<ghobject_t> lru;
  ceph::unordered_map<ghobject_t, std::list<ghobject_t>::iterator> rev_lru;
  void remove_object(const ghobject_t &oid) {
    ceph_assert(ceph_mutex_is_locked(lock));
    ceph::unordered_map<ghobject_t, std::list<ghobject_t>::iterator>::iterator iter =
      rev_lru.find(oid);
    if (iter == rev_lru.end())
      return;

    lru.erase(iter->second);
    rev_lru.erase(iter);
  }
  ghobject_t pop_object() {
    ceph_assert(!lru.empty());
    ghobject_t oid(lru.front());
    lru.pop_front();
    rev_lru.erase(oid);
    return oid;
  }
  void insert_object(const ghobject_t &oid) {
    ceph_assert(rev_lru.find(oid) == rev_lru.end());
    lru.push_back(oid);
    rev_lru.insert(make_pair(oid, --lru.end()));
  }

  ceph::unordered_map<ghobject_t, std::pair<PendingWB, FDRef> > pending_wbs;

  /// get next flush to perform
  bool get_next_should_flush(
    std::unique_lock<ceph::mutex>& locker,
    boost::tuple<ghobject_t, FDRef, PendingWB> *next ///< [out] next to flush
    ); ///< @return false if we are shutting down
public:
  enum FS {
    BTRFS,
    XFS
  };

private:
  FS fs;

  void set_from_conf();
  bool beyond_limit() const {
    if (cur_ios < io_limits.first &&
	pending_wbs.size() < fd_limits.first &&
	cur_size < size_limits.first)
      return false;
    else
      return true;
  }
  bool need_flush() const {
    if (cur_ios < io_limits.second &&
	pending_wbs.size() < fd_limits.second &&
	cur_size < size_limits.second)
      return false;
    else
      return true;
  }

public:
  explicit WBThrottle(CephContext *cct);
  ~WBThrottle() override;

  void start();
  void stop();
  /// Set fs as XFS or BTRFS
  void set_fs(FS new_fs) {
    std::lock_guard l{lock};
    fs = new_fs;
    set_from_conf();
  }

  /// Queue wb on oid, fd taking throttle (does not block)
  void queue_wb(
    FDRef fd,              ///< [in] FDRef to oid
    const ghobject_t &oid, ///< [in] object
    uint64_t offset,       ///< [in] offset written
    uint64_t len,          ///< [in] length written
    bool nocache           ///< [in] try to clear out of cache after write
    );

  /// Clear all wb (probably due to sync)
  void clear();

  /// Clear object
  void clear_object(const ghobject_t &oid);

  /// Block until there is throttle available
  void throttle();

  /// md_config_obs_t
  const char** get_tracked_conf_keys() const override;
  void handle_conf_change(const ConfigProxy& conf,
			  const std::set<std::string> &changed) override;

  /// Thread
  void *entry() override;
};

#endif
