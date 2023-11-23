// -*- mode:C++; tab-width:8; c-basic-offset:2; indent-tabs-mode:t -*-
// vim: ts=8 sw=2 smarttab ft=cpp

#ifndef RGW_ASIO_FRONTEND_H
#define RGW_ASIO_FRONTEND_H

#include <memory>
#include "rgw_frontend.h"
#define REQUEST_TIMEOUT 65000

class RGWAsioFrontend : public RGWFrontend {
  class Impl;
  std::unique_ptr<Impl> impl;
public:
  RGWAsioFrontend(const RGWProcessEnv& env, RGWFrontendConfig* conf,
		  rgw::dmclock::SchedulerCtx& sched_ctx);
  ~RGWAsioFrontend() override;

  int init() override;
  int run() override;
  void stop() override;
  void join() override;

  void pause_for_new_config() override;
  void unpause_with_new_config(rgw::sal::Store* store,
                               rgw_auth_registry_ptr_t auth_registry) override;
};

#endif // RGW_ASIO_FRONTEND_H
