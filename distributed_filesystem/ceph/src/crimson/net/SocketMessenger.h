// -*- mode:C++; tab-width:8; c-basic-offset:2; indent-tabs-mode:t -*-
// vim: ts=8 sw=2 smarttab
/*
 * Ceph - scalable distributed file system
 *
 * Copyright (C) 2017 Red Hat, Inc
 *
 * This is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License version 2.1, as published by the Free Software
 * Foundation.  See file COPYING.
 *
 */

#pragma once

#include <map>
#include <set>
#include <vector>
#include <seastar/core/gate.hh>
#include <seastar/core/reactor.hh>
#include <seastar/core/sharded.hh>
#include <seastar/core/shared_future.hh>

#include "crimson/net/chained_dispatchers.h"
#include "Messenger.h"
#include "Socket.h"
#include "SocketConnection.h"

namespace crimson::net {

class FixedCPUServerSocket;

class SocketMessenger final : public Messenger {
  const seastar::shard_id master_sid;
  seastar::promise<> shutdown_promise;

  FixedCPUServerSocket* listener = nullptr;
  ChainedDispatchers dispatchers;
  std::map<entity_addr_t, SocketConnectionRef> connections;
  std::set<SocketConnectionRef> accepting_conns;
  std::vector<SocketConnectionRef> closing_conns;
  ceph::net::PolicySet<Throttle> policy_set;
  // Distinguish messengers with meaningful names for debugging
  const std::string logic_name;
  const uint32_t nonce;
  // specifying we haven't learned our addr; set false when we find it.
  bool need_addr = true;
  uint32_t global_seq = 0;
  bool started = false;

  listen_ertr::future<> do_listen(const entity_addrvec_t& addr);
  /// try to bind to the first unused port of given address
  bind_ertr::future<> try_bind(const entity_addrvec_t& addr,
                               uint32_t min_port, uint32_t max_port);


 public:
  SocketMessenger(const entity_name_t& myname,
                  const std::string& logic_name,
                  uint32_t nonce);
  ~SocketMessenger() override;

  seastar::future<> set_myaddrs(const entity_addrvec_t& addr) override;

  bool set_addr_unknowns(const entity_addrvec_t &addr) override;
  // Messenger interfaces are assumed to be called from its own shard, but its
  // behavior should be symmetric when called from any shard.
  bind_ertr::future<> bind(const entity_addrvec_t& addr) override;

  seastar::future<> start(const dispatchers_t& dispatchers) override;

  ConnectionRef connect(const entity_addr_t& peer_addr,
                        const entity_name_t& peer_name) override;
  // can only wait once
  seastar::future<> wait() override {
    assert(seastar::this_shard_id() == master_sid);
    return shutdown_promise.get_future();
  }

  void stop() override {
    dispatchers.clear();
  }

  bool is_started() const override {
    return !dispatchers.empty();
  }

  seastar::future<> shutdown() override;

  void print(std::ostream& out) const override {
    out << get_myname()
        << "(" << logic_name
        << ") " << get_myaddr();
  }

  SocketPolicy get_policy(entity_type_t peer_type) const override;

  SocketPolicy get_default_policy() const override;

  void set_default_policy(const SocketPolicy& p) override;

  void set_policy(entity_type_t peer_type, const SocketPolicy& p) override;

  void set_policy_throttler(entity_type_t peer_type, Throttle* throttle) override;

 public:
  seastar::future<uint32_t> get_global_seq(uint32_t old=0);
  seastar::future<> learned_addr(const entity_addr_t &peer_addr_for_me,
                                 const SocketConnection& conn);

  SocketConnectionRef lookup_conn(const entity_addr_t& addr);
  void accept_conn(SocketConnectionRef);
  void unaccept_conn(SocketConnectionRef);
  void register_conn(SocketConnectionRef);
  void unregister_conn(SocketConnectionRef);
  void closing_conn(SocketConnectionRef);
  void closed_conn(SocketConnectionRef);
  seastar::shard_id shard_id() const {
    assert(seastar::this_shard_id() == master_sid);
    return master_sid;
  }
};

} // namespace crimson::net
