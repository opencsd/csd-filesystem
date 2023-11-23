// -*- mode:C++; tab-width:8; c-basic-offset:2; indent-tabs-mode:t -*-
// vim: ts=8 sw=2 smarttab

#include "osd_operation.h"
#include "common/Formatter.h"

namespace crimson::osd {

OperationThrottler::OperationThrottler(ConfigProxy &conf)
  : scheduler(crimson::osd::scheduler::make_scheduler(conf))
{
  conf.add_observer(this);
  update_from_config(conf);
}

void OperationThrottler::wake()
{
  while ((!max_in_progress || in_progress < max_in_progress) &&
	 !scheduler->empty()) {
    auto item = scheduler->dequeue();
    item.wake.set_value();
    ++in_progress;
    --pending;
  }
}

void OperationThrottler::release_throttle()
{
  ceph_assert(in_progress > 0);
  --in_progress;
  wake();
}

blocking_future<> OperationThrottler::acquire_throttle(
  crimson::osd::scheduler::params_t params)
{
  crimson::osd::scheduler::item_t item{params, seastar::promise<>()};
  auto fut = item.wake.get_future();
  scheduler->enqueue(std::move(item));
  return make_blocking_future(std::move(fut));
}

void OperationThrottler::dump_detail(Formatter *f) const
{
  f->dump_unsigned("max_in_progress", max_in_progress);
  f->dump_unsigned("in_progress", in_progress);
  f->open_object_section("scheduler");
  {
    scheduler->dump(*f);
  }
  f->close_section();
}

void OperationThrottler::update_from_config(const ConfigProxy &conf)
{
  max_in_progress = conf.get_val<uint64_t>("crimson_osd_scheduler_concurrency");
  wake();
}

const char** OperationThrottler::get_tracked_conf_keys() const
{
  static const char* KEYS[] = {
    "crimson_osd_scheduler_concurrency",
    NULL
  };
  return KEYS;
}

void OperationThrottler::handle_conf_change(
  const ConfigProxy& conf,
  const std::set<std::string> &changed)
{
  update_from_config(conf);
}

}
