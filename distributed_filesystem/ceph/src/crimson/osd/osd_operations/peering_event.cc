// -*- mode:C++; tab-width:8; c-basic-offset:2; indent-tabs-mode:t -*-
// vim: ts=8 sw=2 smarttab

#include <seastar/core/future.hh>
#include <seastar/core/sleep.hh>

#include "messages/MOSDPGLog.h"

#include "common/Formatter.h"
#include "crimson/osd/pg.h"
#include "crimson/osd/osd.h"
#include "crimson/osd/osd_operations/peering_event.h"
#include "crimson/osd/osd_connection_priv.h"

namespace {
  seastar::logger& logger() {
    return crimson::get_logger(ceph_subsys_osd);
  }
}

namespace crimson::osd {

void PeeringEvent::print(std::ostream &lhs) const
{
  lhs << "PeeringEvent("
      << "from=" << from
      << " pgid=" << pgid
      << " sent=" << evt.get_epoch_sent()
      << " requested=" << evt.get_epoch_requested()
      << " evt=" << evt.get_desc()
      << ")";
}

void PeeringEvent::dump_detail(Formatter *f) const
{
  f->open_object_section("PeeringEvent");
  f->dump_stream("from") << from;
  f->dump_stream("pgid") << pgid;
  f->dump_int("sent", evt.get_epoch_sent());
  f->dump_int("requested", evt.get_epoch_requested());
  f->dump_string("evt", evt.get_desc());
  f->close_section();
}


PeeringEvent::PGPipeline &PeeringEvent::pp(PG &pg)
{
  return pg.peering_request_pg_pipeline;
}

seastar::future<> PeeringEvent::start()
{

  logger().debug("{}: start", *this);

  IRef ref = this;
  auto maybe_delay = seastar::now();
  if (delay) {
    maybe_delay = seastar::sleep(
      std::chrono::milliseconds(std::lround(delay * 1000)));
  }
  return maybe_delay.then([this] {
    return get_pg();
  }).then([this](Ref<PG> pg) {
    if (!pg) {
      logger().warn("{}: pg absent, did not create", *this);
      on_pg_absent();
      handle.exit();
      return complete_rctx_no_pg();
    }
    return interruptor::with_interruption([this, pg] {
      logger().debug("{}: pg present", *this);
      return with_blocking_future_interruptible<interruptor::condition>(
        handle.enter(pp(*pg).await_map)
      ).then_interruptible([this, pg] {
        return with_blocking_future_interruptible<interruptor::condition>(
          pg->osdmap_gate.wait_for_map(evt.get_epoch_sent()));
      }).then_interruptible([this, pg](auto) {
        return with_blocking_future_interruptible<interruptor::condition>(
          handle.enter(pp(*pg).process));
      }).then_interruptible([this, pg] {
        // TODO: likely we should synchronize also with the pg log-based
        // recovery.
        return with_blocking_future_interruptible<interruptor::condition>(
          handle.enter(BackfillRecovery::bp(*pg).process));
      }).then_interruptible([this, pg] {
        pg->do_peering_event(evt, ctx);
        handle.exit();
        return complete_rctx(pg);
      }).then_interruptible([this, pg] () -> PeeringEvent::interruptible_future<> {
        if (!pg->get_need_up_thru()) {
          return seastar::now();
        }
        return shard_services.send_alive(pg->get_same_interval_since());
      }).then_interruptible([this] {
        return shard_services.send_pg_temp();
      });
    },
    [this](std::exception_ptr ep) {
      logger().debug("{}: interrupted with {}", *this, ep);
      return seastar::now();
    },
    pg);
  }).finally([ref=std::move(ref)] {
    logger().debug("{}: complete", *ref);
  });
}

void PeeringEvent::on_pg_absent()
{
  logger().debug("{}: pg absent, dropping", *this);
}

PeeringEvent::interruptible_future<> PeeringEvent::complete_rctx(Ref<PG> pg)
{
  logger().debug("{}: submitting ctx", *this);
  return shard_services.dispatch_context(
    pg->get_collection_ref(),
    std::move(ctx));
}

RemotePeeringEvent::ConnectionPipeline &RemotePeeringEvent::cp()
{
  return get_osd_priv(conn.get()).peering_request_conn_pipeline;
}

RemotePeeringEvent::OSDPipeline &RemotePeeringEvent::op()
{
  return osd.peering_request_osd_pipeline;
}

void RemotePeeringEvent::on_pg_absent()
{
  if (auto& e = get_event().get_event();
      e.dynamic_type() == MQuery::static_type()) {
    const auto map_epoch =
      shard_services.get_osdmap_service().get_map()->get_epoch();
    const auto& q = static_cast<const MQuery&>(e);
    const pg_info_t empty{spg_t{pgid.pgid, q.query.to}};
    if (q.query.type == q.query.LOG ||
	q.query.type == q.query.FULLLOG)  {
      auto m = crimson::make_message<MOSDPGLog>(q.query.from, q.query.to,
					     map_epoch, empty,
					     q.query.epoch_sent);
      ctx.send_osd_message(q.from.osd, std::move(m));
    } else {
      ctx.send_notify(q.from.osd, {q.query.from, q.query.to,
				   q.query.epoch_sent,
				   map_epoch, empty,
				   PastIntervals{}});
    }
  }
}

PeeringEvent::interruptible_future<> RemotePeeringEvent::complete_rctx(Ref<PG> pg)
{
  if (pg) {
    return PeeringEvent::complete_rctx(pg);
  } else {
    logger().debug("{}: OSDState is {}", *this, osd.state);
    return osd.state.when_active().then([this] {
      assert(osd.state.is_active());
      return shard_services.dispatch_context_messages(std::move(ctx));
    });
  }
}

seastar::future<> RemotePeeringEvent::complete_rctx_no_pg()
{
  logger().debug("{}: OSDState is {}", *this, osd.state);
  return osd.state.when_active().then([this] {
    assert(osd.state.is_active());
    return shard_services.dispatch_context_messages(std::move(ctx));
  });
}

seastar::future<Ref<PG>> RemotePeeringEvent::get_pg()
{
  return with_blocking_future(
    handle.enter(op().await_active)
  ).then([this] {
    return osd.state.when_active();
  }).then([this] {
    return with_blocking_future(handle.enter(cp().await_map));
  }).then([this] {
    return with_blocking_future(
      osd.osdmap_gate.wait_for_map(evt.get_epoch_sent()));
  }).then([this](auto epoch) {
    logger().debug("{}: got map {}", *this, epoch);
    return with_blocking_future(handle.enter(cp().get_pg));
  }).then([this] {
    return with_blocking_future(
      osd.get_or_create_pg(
	pgid, evt.get_epoch_sent(), std::move(evt.create_info)));
  });
}

seastar::future<Ref<PG>> LocalPeeringEvent::get_pg() {
  return seastar::make_ready_future<Ref<PG>>(pg);
}

LocalPeeringEvent::~LocalPeeringEvent() {}

}
