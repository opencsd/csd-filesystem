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

#ifndef CEPH_JOURNALINGOBJECTSTORE_H
#define CEPH_JOURNALINGOBJECTSTORE_H

#include "os/ObjectStore.h"
#include "Journal.h"
#include "FileJournal.h"
#include "osd/OpRequest.h"

class JournalingObjectStore : public ObjectStore {
protected:
  Journal *journal;
  Finisher finisher;


  class SubmitManager {
    CephContext* cct;
    ceph::mutex lock = ceph::make_mutex("JOS::SubmitManager::lock");
    uint64_t op_seq;
    uint64_t op_submitted;
  public:
    SubmitManager(CephContext* cct) :
      cct(cct),
      op_seq(0), op_submitted(0)
    {}
    uint64_t op_submit_start();
    void op_submit_finish(uint64_t op);
    void set_op_seq(uint64_t seq) {
      std::lock_guard l{lock};
      op_submitted = op_seq = seq;
    }
    uint64_t get_op_seq() {
      return op_seq;
    }
  } submit_manager;

  class ApplyManager {
    CephContext* cct;
    Journal *&journal;
    Finisher &finisher;

    ceph::mutex apply_lock = ceph::make_mutex("JOS::ApplyManager::apply_lock");
    bool blocked;
    ceph::condition_variable blocked_cond;
    int open_ops;
    uint64_t max_applied_seq;

    ceph::mutex com_lock = ceph::make_mutex("JOS::ApplyManager::com_lock");
    std::map<version_t, std::vector<Context*> > commit_waiters;
    uint64_t committing_seq, committed_seq;

  public:
    ApplyManager(CephContext* cct, Journal *&j, Finisher &f) :
      cct(cct), journal(j), finisher(f),
      blocked(false),
      open_ops(0),
      max_applied_seq(0),
      committing_seq(0), committed_seq(0) {}
    void reset() {
      ceph_assert(open_ops == 0);
      ceph_assert(blocked == false);
      max_applied_seq = 0;
      committing_seq = 0;
      committed_seq = 0;
    }
    void add_waiter(uint64_t, Context*);
    uint64_t op_apply_start(uint64_t op);
    void op_apply_finish(uint64_t op);
    bool commit_start();
    void commit_started();
    void commit_finish();
    bool is_committing() {
      std::lock_guard l{com_lock};
      return committing_seq != committed_seq;
    }
    uint64_t get_committed_seq() {
      std::lock_guard l{com_lock};
      return committed_seq;
    }
    uint64_t get_committing_seq() {
      std::lock_guard l{com_lock};
      return committing_seq;
    }
    void init_seq(uint64_t fs_op_seq) {
      {
	std::lock_guard l{com_lock};
	committed_seq = fs_op_seq;
	committing_seq = fs_op_seq;
      }
      {
	std::lock_guard l{apply_lock};
	max_applied_seq = fs_op_seq;
      }
    }
  } apply_manager;

  bool replaying;

protected:
  void journal_start();
  void journal_stop();
  void journal_write_close();
  int journal_replay(uint64_t fs_op_seq);

  void _op_journal_transactions(ceph::buffer::list& tls, uint32_t orig_len, uint64_t op,
				Context *onjournal, TrackedOpRef osd_op);

  virtual int do_transactions(std::vector<ObjectStore::Transaction>& tls, uint64_t op_seq) = 0;

public:
  bool is_committing() {
    return apply_manager.is_committing();
  }
  uint64_t get_committed_seq() {
    return apply_manager.get_committed_seq();
  }

public:
  JournalingObjectStore(CephContext* cct, const std::string& path)
    : ObjectStore(cct, path),
      journal(NULL),
      finisher(cct, "JournalObjectStore", "fn_jrn_objstore"),
      submit_manager(cct),
      apply_manager(cct, journal, finisher),
      replaying(false) {}

  ~JournalingObjectStore() override {
  }
};

#endif
