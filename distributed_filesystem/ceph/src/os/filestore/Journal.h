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


#ifndef CEPH_JOURNAL_H
#define CEPH_JOURNAL_H

#include <errno.h>

#include "include/buffer_fwd.h"
#include "include/common_fwd.h"
#include "include/Context.h"
#include "common/Finisher.h"
#include "common/TrackedOp.h"
#include "os/ObjectStore.h"
#include "common/zipkin_trace.h"


class Journal {
protected:
  uuid_d fsid;
  Finisher *finisher;
public:
  CephContext* cct;
  PerfCounters *logger;
protected:
  ceph::condition_variable *do_sync_cond;
  bool wait_on_full;

public:
  Journal(CephContext* cct, uuid_d f, Finisher *fin, ceph::condition_variable *c=0) :
    fsid(f), finisher(fin), cct(cct), logger(NULL),
    do_sync_cond(c),
    wait_on_full(false) { }
  virtual ~Journal() { }

  virtual int check() = 0;   ///< check if journal appears valid
  virtual int create() = 0;  ///< create a fresh journal
  virtual int open(uint64_t fs_op_seq) = 0;  ///< open an existing journal
  virtual void close() = 0;  ///< close an open journal

  virtual void flush() = 0;

  virtual void get_devices(std::set<std::string> *ls) {}
  virtual void collect_metadata(std::map<std::string,std::string> *pm) {}
  /**
   * reserve_throttle_and_backoff
   *
   * Implementation may throttle or backoff based on ops
   * reserved here but not yet released using committed_thru.
   */
  virtual void reserve_throttle_and_backoff(uint64_t count) = 0;

  virtual int dump(std::ostream& out) { return -EOPNOTSUPP; }

  void set_wait_on_full(bool b) { wait_on_full = b; }

  // writes
  virtual bool is_writeable() = 0;
  virtual int make_writeable() = 0;
  virtual void submit_entry(uint64_t seq, ceph::buffer::list& e, uint32_t orig_len,
			    Context *oncommit,
			    TrackedOpRef osd_op = TrackedOpRef()) = 0;
  virtual void commit_start(uint64_t seq) = 0;
  virtual void committed_thru(uint64_t seq) = 0;

  /// Read next journal entry - asserts on invalid journal
  virtual bool read_entry(
    ceph::buffer::list &bl, ///< [out] payload on successful read
    uint64_t &seq   ///< [in,out] sequence number on last successful read
    ) = 0; ///< @return true on successful read, false on journal end

  virtual bool should_commit_now() = 0;

  virtual int prepare_entry(std::vector<ObjectStore::Transaction>& tls, ceph::buffer::list* tbl) = 0;

  virtual off64_t get_journal_size_estimate() { return 0; }

  // reads/recovery

};

#endif
