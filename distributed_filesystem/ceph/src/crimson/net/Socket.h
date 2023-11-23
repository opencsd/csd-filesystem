// -*- mode:C++; tab-width:8; c-basic-offset:2; indent-tabs-mode:t -*-
// vim: ts=8 sw=2 smarttab

#pragma once

#include <seastar/core/gate.hh>
#include <seastar/core/reactor.hh>
#include <seastar/core/sharded.hh>
#include <seastar/net/packet.hh>

#include "include/buffer.h"

#include "crimson/common/log.h"
#include "Errors.h"
#include "Fwd.h"

#ifdef UNIT_TESTS_BUILT
#include "Interceptor.h"
#endif

namespace crimson::net {

class Socket;
using SocketRef = std::unique_ptr<Socket>;

class Socket
{
  struct construct_tag {};

 public:
  // if acceptor side, peer is using a different port (ephemeral_port)
  // if connector side, I'm using a different port (ephemeral_port)
  enum class side_t {
    acceptor,
    connector
  };

  Socket(seastar::connected_socket&& _socket, side_t _side, uint16_t e_port, construct_tag)
    : sid{seastar::this_shard_id()},
      socket(std::move(_socket)),
      in(socket.input()),
      // the default buffer size 8192 is too small that may impact our write
      // performance. see seastar::net::connected_socket::output()
      out(socket.output(65536)),
      side(_side),
      ephemeral_port(e_port) {}

  ~Socket() {
#ifndef NDEBUG
    assert(closed);
#endif
  }

  Socket(Socket&& o) = delete;

  static seastar::future<SocketRef>
  connect(const entity_addr_t& peer_addr) {
    inject_failure();
    return inject_delay(
    ).then([peer_addr] {
      return seastar::connect(peer_addr.in4_addr());
    }).then([] (seastar::connected_socket socket) {
      return std::make_unique<Socket>(
        std::move(socket), side_t::connector, 0, construct_tag{});
    });
  }

  /// read the requested number of bytes into a bufferlist
  seastar::future<bufferlist> read(size_t bytes);
  using tmp_buf = seastar::temporary_buffer<char>;
  using packet = seastar::net::packet;
  seastar::future<tmp_buf> read_exactly(size_t bytes);

  seastar::future<> write(packet&& buf) {
#ifdef UNIT_TESTS_BUILT
    return try_trap_pre(next_trap_write
    ).then([buf = std::move(buf), this] () mutable {
#endif
      inject_failure();
      return inject_delay(
      ).then([buf = std::move(buf), this] () mutable {
        return out.write(std::move(buf));
      });
#ifdef UNIT_TESTS_BUILT
    }).then([this] {
      return try_trap_post(next_trap_write);
    });
#endif
  }
  seastar::future<> flush() {
    inject_failure();
    return inject_delay().then([this] {
      return out.flush();
    });
  }
  seastar::future<> write_flush(packet&& buf) {
#ifdef UNIT_TESTS_BUILT
    return try_trap_pre(next_trap_write).then([buf = std::move(buf), this] () mutable {
#endif
      inject_failure();
      return inject_delay(
      ).then([buf = std::move(buf), this] () mutable {
        return out.write(std::move(buf)).then([this] { return out.flush(); });
      });
#ifdef UNIT_TESTS_BUILT
    }).then([this] {
      return try_trap_post(next_trap_write);
    });
#endif
  }

  // preemptively disable further reads or writes, can only be shutdown once.
  void shutdown();

  /// Socket can only be closed once.
  seastar::future<> close();

  static seastar::future<> inject_delay();

  static void inject_failure();

  // shutdown input_stream only, for tests
  void force_shutdown_in() {
    socket.shutdown_input();
  }

  // shutdown output_stream only, for tests
  void force_shutdown_out() {
    socket.shutdown_output();
  }

  side_t get_side() const {
    return side;
  }

  uint16_t get_ephemeral_port() const {
    return ephemeral_port;
  }

  // learn my ephemeral_port as connector.
  // unfortunately, there's no way to identify which port I'm using as
  // connector with current seastar interface.
  void learn_ephemeral_port_as_connector(uint16_t port) {
    assert(side == side_t::connector &&
           (ephemeral_port == 0 || ephemeral_port == port));
    ephemeral_port = port;
  }

  seastar::socket_address get_local_address() const {
    return socket.local_address();
  }

 private:
  const seastar::shard_id sid;
  seastar::connected_socket socket;
  seastar::input_stream<char> in;
  seastar::output_stream<char> out;
  side_t side;
  uint16_t ephemeral_port;

#ifndef NDEBUG
  bool closed = false;
#endif

  /// buffer state for read()
  struct {
    bufferlist buffer;
    size_t remaining;
  } r;

#ifdef UNIT_TESTS_BUILT
 public:
  void set_trap(bp_type_t type, bp_action_t action, socket_blocker* blocker_);

 private:
  bp_action_t next_trap_read = bp_action_t::CONTINUE;
  bp_action_t next_trap_write = bp_action_t::CONTINUE;
  socket_blocker* blocker = nullptr;
  seastar::future<> try_trap_pre(bp_action_t& trap);
  seastar::future<> try_trap_post(bp_action_t& trap);

#endif
  friend class FixedCPUServerSocket;
};

using listen_ertr = crimson::errorator<
  crimson::ct_error::address_in_use, // The address is already bound
  crimson::ct_error::address_not_available // https://techoverflow.net/2021/08/06/how-i-fixed-python-oserror-errno-99-cannot-assign-requested-address/
  >;

class FixedCPUServerSocket
    : public seastar::peering_sharded_service<FixedCPUServerSocket> {
  const seastar::shard_id cpu;
  entity_addr_t addr;
  std::optional<seastar::server_socket> listener;
  seastar::gate shutdown_gate;

  using sharded_service_t = seastar::sharded<FixedCPUServerSocket>;
  std::unique_ptr<sharded_service_t> service;

  struct construct_tag {};

  static seastar::logger& logger() {
    return crimson::get_logger(ceph_subsys_ms);
  }

  seastar::future<> reset() {
    return container().invoke_on_all([] (auto& ss) {
      assert(ss.shutdown_gate.is_closed());
      ss.addr = entity_addr_t();
      ss.listener.reset();
    });
  }

public:
  FixedCPUServerSocket(seastar::shard_id cpu, construct_tag) : cpu{cpu} {}
  ~FixedCPUServerSocket() {
    assert(!listener);
    // detect whether user have called destroy() properly
    ceph_assert(!service);
  }

  FixedCPUServerSocket(FixedCPUServerSocket&&) = delete;
  FixedCPUServerSocket(const FixedCPUServerSocket&) = delete;
  FixedCPUServerSocket& operator=(const FixedCPUServerSocket&) = delete;

  listen_ertr::future<> listen(entity_addr_t addr);

  // fn_accept should be a nothrow function of type
  // seastar::future<>(SocketRef, entity_addr_t)
  template <typename Func>
  seastar::future<> accept(Func&& fn_accept) {
    assert(seastar::this_shard_id() == cpu);
    logger().trace("FixedCPUServerSocket({})::accept()...", addr);
    return container().invoke_on_all(
        [fn_accept = std::move(fn_accept)] (auto& ss) mutable {
      assert(ss.listener);
      // gate accepting
      // FixedCPUServerSocket::shutdown() will drain the continuations in the gate
      // so ignore the returned future
      std::ignore = seastar::with_gate(ss.shutdown_gate,
          [&ss, fn_accept = std::move(fn_accept)] () mutable {
        return seastar::keep_doing([&ss, fn_accept = std::move(fn_accept)] () mutable {
          return ss.listener->accept().then(
              [&ss, fn_accept = std::move(fn_accept)]
              (seastar::accept_result accept_result) mutable {
            // assert seastar::listen_options::set_fixed_cpu() works
            assert(seastar::this_shard_id() == ss.cpu);
            auto [socket, paddr] = std::move(accept_result);
            entity_addr_t peer_addr;
            peer_addr.set_sockaddr(&paddr.as_posix_sockaddr());
            peer_addr.set_type(ss.addr.get_type());
            SocketRef _socket = std::make_unique<Socket>(
                std::move(socket), Socket::side_t::acceptor,
                peer_addr.get_port(), Socket::construct_tag{});
            std::ignore = seastar::with_gate(ss.shutdown_gate,
                [socket = std::move(_socket), peer_addr,
                 &ss, fn_accept = std::move(fn_accept)] () mutable {
              logger().trace("FixedCPUServerSocket({})::accept(): "
                             "accepted peer {}", ss.addr, peer_addr);
              return fn_accept(std::move(socket), peer_addr
              ).handle_exception([&ss, peer_addr] (auto eptr) {
                logger().error("FixedCPUServerSocket({})::accept(): "
                               "fn_accept(s, {}) got unexpected exception {}",
                               ss.addr, peer_addr, eptr);
                ceph_abort();
              });
            });
          });
        }).handle_exception_type([&ss] (const std::system_error& e) {
          if (e.code() == std::errc::connection_aborted ||
              e.code() == std::errc::invalid_argument) {
            logger().trace("FixedCPUServerSocket({})::accept(): stopped ({})",
                           ss.addr, e);
          } else {
            throw;
          }
        }).handle_exception([&ss] (auto eptr) {
          logger().error("FixedCPUServerSocket({})::accept(): "
                         "got unexpected exception {}", ss.addr, eptr);
          ceph_abort();
        });
      });
    });
  }

  seastar::future<> shutdown();
  seastar::future<> destroy();
  static seastar::future<FixedCPUServerSocket*> create();
};

} // namespace crimson::net
