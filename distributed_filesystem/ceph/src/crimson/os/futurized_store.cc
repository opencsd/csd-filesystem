// -*- mode:C++; tab-width:8; c-basic-offset:2; indent-tabs-mode:t -*-
// vim: ts=8 sw=2 smarttab

#include "futurized_store.h"
#include "cyanstore/cyan_store.h"
#ifdef WITH_BLUESTORE
#include "alienstore/alien_store.h"
#endif
#include "seastore/seastore.h"

namespace crimson::os {

seastar::future<std::unique_ptr<FuturizedStore>>
FuturizedStore::create(const std::string& type,
                       const std::string& data,
                       const ConfigValues& values)
{
  if (type == "cyanstore") {
    return seastar::make_ready_future<std::unique_ptr<FuturizedStore>>(
      std::make_unique<crimson::os::CyanStore>(data));
  } else if (type == "seastore") {
    return crimson::os::seastore::make_seastore(
      data, values
    ).then([] (auto seastore) {
      return seastar::make_ready_future<std::unique_ptr<FuturizedStore>>(
	seastore.release());
    });
  } else {
#ifdef WITH_BLUESTORE
    // use AlienStore as a fallback. It adapts e.g. BlueStore.
    return seastar::make_ready_future<std::unique_ptr<FuturizedStore>>(
      std::make_unique<crimson::os::AlienStore>(type, data, values));
#else
    ceph_abort_msgf("unsupported objectstore type: %s", type.c_str());
    return {};
#endif
  }
}

}
