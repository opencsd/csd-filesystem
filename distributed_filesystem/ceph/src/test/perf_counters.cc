// -*- mode:C++; tab-width:8; c-basic-offset:2; indent-tabs-mode:t -*-
// vim: ts=8 sw=2 smarttab
/*
 * Ceph - scalable distributed file system
 *
 * Copyright (C) 2011 New Dream Network
 *
 * This is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License version 2.1, as published by the Free Software
 * Foundation.  See file COPYING.
 *
 */
#include "include/int_types.h"
#include "include/types.h" // FIXME: ordering shouldn't be important, but right 
                           // now, this include has to come before the others.


#include "common/perf_counters_collection.h"
#include "common/admin_socket_client.h"
#include "common/ceph_context.h"
#include "common/config.h"
#include "common/errno.h"
#include "common/safe_io.h"

#include "common/code_environment.h"
#include "global/global_context.h"
#include "global/global_init.h"
#include "include/msgr.h" // for CEPH_ENTITY_TYPE_CLIENT
#include "gtest/gtest.h"

#include <errno.h>
#include <fcntl.h>
#include <map>
#include <poll.h>
#include <sstream>
#include <stdint.h>
#include <string.h>
#include <string>
#include <sys/socket.h>
#include <sys/types.h>
#include <sys/un.h>
#include <time.h>
#include <unistd.h>
#include <thread>

#include "common/common_init.h"

using namespace std;

int main(int argc, char **argv) {
  map<string,string> defaults = {
    { "admin_socket", get_rand_socket_path() }
  };
  std::vector<const char*> args;
  auto cct = global_init(&defaults, args, CEPH_ENTITY_TYPE_CLIENT,
			 CODE_ENVIRONMENT_UTILITY,
			 CINIT_FLAG_NO_DEFAULT_CONFIG_FILE|
			 CINIT_FLAG_NO_CCT_PERF_COUNTERS);
  common_init_finish(g_ceph_context);
  ::testing::InitGoogleTest(&argc, argv);
  return RUN_ALL_TESTS();
}

TEST(PerfCounters, SimpleTest) {
  AdminSocketClient client(get_rand_socket_path());
  std::string message;
  ASSERT_EQ("", client.do_request("{ \"prefix\": \"perf dump\" }", &message));
  ASSERT_EQ("{}\n", message);
}

enum {
  TEST_PERFCOUNTERS1_ELEMENT_FIRST = 200,
  TEST_PERFCOUNTERS1_ELEMENT_1,
  TEST_PERFCOUNTERS1_ELEMENT_2,
  TEST_PERFCOUNTERS1_ELEMENT_3,
  TEST_PERFCOUNTERS1_ELEMENT_LAST,
};

std::string sd(const char *c)
{
  std::string ret(c);
  std::string::size_type sz = ret.size();
  for (std::string::size_type i = 0; i < sz; ++i) {
    if (ret[i] == '\'') {
      ret[i] = '\"';
    }
  }
  return ret;
}

static PerfCounters* setup_test_perfcounters1(CephContext *cct)
{
  PerfCountersBuilder bld(cct, "test_perfcounter_1",
	  TEST_PERFCOUNTERS1_ELEMENT_FIRST, TEST_PERFCOUNTERS1_ELEMENT_LAST);
  bld.add_u64(TEST_PERFCOUNTERS1_ELEMENT_1, "element1");
  bld.add_time(TEST_PERFCOUNTERS1_ELEMENT_2, "element2");
  bld.add_time_avg(TEST_PERFCOUNTERS1_ELEMENT_3, "element3");
  return bld.create_perf_counters();
}

TEST(PerfCounters, SinglePerfCounters) {
  PerfCountersCollection *coll = g_ceph_context->get_perfcounters_collection();
  PerfCounters* fake_pf = setup_test_perfcounters1(g_ceph_context);
  coll->add(fake_pf);
  AdminSocketClient client(get_rand_socket_path());
  std::string msg;
  ASSERT_EQ("", client.do_request("{ \"prefix\": \"perf dump\", \"format\": \"json\" }", &msg));
  ASSERT_EQ(sd("{\"test_perfcounter_1\":{\"element1\":0,"
	    "\"element2\":0.000000000,\"element3\":{\"avgcount\":0,\"sum\":0.000000000,\"avgtime\":0.000000000}}}"), msg);
  fake_pf->inc(TEST_PERFCOUNTERS1_ELEMENT_1);
  fake_pf->tset(TEST_PERFCOUNTERS1_ELEMENT_2, utime_t(0, 500000000));
  fake_pf->tinc(TEST_PERFCOUNTERS1_ELEMENT_3, utime_t(100, 0));
  ASSERT_EQ("", client.do_request("{ \"prefix\": \"perf dump\", \"format\": \"json\" }", &msg));
  ASSERT_EQ(sd("{\"test_perfcounter_1\":{\"element1\":1,"
	    "\"element2\":0.500000000,\"element3\":{\"avgcount\":1,\"sum\":100.000000000,\"avgtime\":100.000000000}}}"), msg);
  fake_pf->tinc(TEST_PERFCOUNTERS1_ELEMENT_3, utime_t());
  fake_pf->tinc(TEST_PERFCOUNTERS1_ELEMENT_3, utime_t(20,0));
  ASSERT_EQ("", client.do_request("{ \"prefix\": \"perf dump\", \"format\": \"json\" }", &msg));
  ASSERT_EQ(sd("{\"test_perfcounter_1\":{\"element1\":1,\"element2\":0.500000000,"
	    "\"element3\":{\"avgcount\":3,\"sum\":120.000000000,\"avgtime\":40.000000000}}}"), msg);

  fake_pf->reset();
  msg.clear();
  ASSERT_EQ("", client.do_request("{ \"prefix\": \"perf dump\", \"format\": \"json\" }", &msg));
  ASSERT_EQ(sd("{\"test_perfcounter_1\":{\"element1\":1,"
	    "\"element2\":0.000000000,\"element3\":{\"avgcount\":0,\"sum\":0.000000000,\"avgtime\":0.000000000}}}"), msg);

}

enum {
  TEST_PERFCOUNTERS2_ELEMENT_FIRST = 400,
  TEST_PERFCOUNTERS2_ELEMENT_FOO,
  TEST_PERFCOUNTERS2_ELEMENT_BAR,
  TEST_PERFCOUNTERS2_ELEMENT_LAST,
};

static PerfCounters* setup_test_perfcounter2(CephContext *cct)
{
  PerfCountersBuilder bld(cct, "test_perfcounter_2",
	  TEST_PERFCOUNTERS2_ELEMENT_FIRST, TEST_PERFCOUNTERS2_ELEMENT_LAST);
  bld.add_u64(TEST_PERFCOUNTERS2_ELEMENT_FOO, "foo");
  bld.add_time(TEST_PERFCOUNTERS2_ELEMENT_BAR, "bar");
  return bld.create_perf_counters();
}

TEST(PerfCounters, MultiplePerfCounters) {
  PerfCountersCollection *coll = g_ceph_context->get_perfcounters_collection();
  coll->clear();
  PerfCounters* fake_pf1 = setup_test_perfcounters1(g_ceph_context);
  PerfCounters* fake_pf2 = setup_test_perfcounter2(g_ceph_context);
  coll->add(fake_pf1);
  coll->add(fake_pf2);
  AdminSocketClient client(get_rand_socket_path());
  std::string msg;

  ASSERT_EQ("", client.do_request("{ \"prefix\": \"perf dump\", \"format\": \"json\" }", &msg));
  ASSERT_EQ(sd("{\"test_perfcounter_1\":{\"element1\":0,\"element2\":0.000000000,\"element3\":"
	    "{\"avgcount\":0,\"sum\":0.000000000,\"avgtime\":0.000000000}},\"test_perfcounter_2\":{\"foo\":0,\"bar\":0.000000000}}"), msg);

  fake_pf1->inc(TEST_PERFCOUNTERS1_ELEMENT_1);
  fake_pf1->inc(TEST_PERFCOUNTERS1_ELEMENT_1, 5);
  ASSERT_EQ("", client.do_request("{ \"prefix\": \"perf dump\", \"format\": \"json\" }", &msg));
  ASSERT_EQ(sd("{\"test_perfcounter_1\":{\"element1\":6,\"element2\":0.000000000,\"element3\":"
	    "{\"avgcount\":0,\"sum\":0.000000000,\"avgtime\":0.000000000}},\"test_perfcounter_2\":{\"foo\":0,\"bar\":0.000000000}}"), msg);

  coll->reset(string("test_perfcounter_1"));
  ASSERT_EQ("", client.do_request("{ \"prefix\": \"perf dump\", \"format\": \"json\" }", &msg));
  ASSERT_EQ(sd("{\"test_perfcounter_1\":{\"element1\":6,\"element2\":0.000000000,\"element3\":"
	    "{\"avgcount\":0,\"sum\":0.000000000,\"avgtime\":0.000000000}},\"test_perfcounter_2\":{\"foo\":0,\"bar\":0.000000000}}"), msg);

  fake_pf1->inc(TEST_PERFCOUNTERS1_ELEMENT_1);
  fake_pf1->inc(TEST_PERFCOUNTERS1_ELEMENT_1, 6);
  ASSERT_EQ("", client.do_request("{ \"prefix\": \"perf dump\", \"format\": \"json\" }", &msg));
  ASSERT_EQ(sd("{\"test_perfcounter_1\":{\"element1\":13,\"element2\":0.000000000,\"element3\":"
	    "{\"avgcount\":0,\"sum\":0.000000000,\"avgtime\":0.000000000}},\"test_perfcounter_2\":{\"foo\":0,\"bar\":0.000000000}}"), msg);

  coll->reset(string("all"));
  msg.clear();
  ASSERT_EQ("", client.do_request("{ \"prefix\": \"perf dump\", \"format\": \"json\" }", &msg));
  ASSERT_EQ(sd("{\"test_perfcounter_1\":{\"element1\":13,\"element2\":0.000000000,\"element3\":"
	    "{\"avgcount\":0,\"sum\":0.000000000,\"avgtime\":0.000000000}},\"test_perfcounter_2\":{\"foo\":0,\"bar\":0.000000000}}"), msg);

  coll->remove(fake_pf2);
  ASSERT_EQ("", client.do_request("{ \"prefix\": \"perf dump\", \"format\": \"json\" }", &msg));
  ASSERT_EQ(sd("{\"test_perfcounter_1\":{\"element1\":13,\"element2\":0.000000000,"
	    "\"element3\":{\"avgcount\":0,\"sum\":0.000000000,\"avgtime\":0.000000000}}}"), msg);
  ASSERT_EQ("", client.do_request("{ \"prefix\": \"perf schema\", \"format\": \"json\" }", &msg));
  ASSERT_EQ(sd("{\"test_perfcounter_1\":{\"element1\":{\"type\":2,\"metric_type\":\"gauge\",\"value_type\":\"integer\",\"description\":\"\",\"nick\":\"\",\"priority\":0,\"units\":\"none\"},\"element2\":{\"type\":1,\"metric_type\":\"gauge\",\"value_type\":\"real\",\"description\":\"\",\"nick\":\"\",\"priority\":0,\"units\":\"none\"},\"element3\":{\"type\":5,\"metric_type\":\"gauge\",\"value_type\":\"real-integer-pair\",\"description\":\"\",\"nick\":\"\",\"priority\":0,\"units\":\"none\"}}}"), msg);
  coll->clear();
  ASSERT_EQ("", client.do_request("{ \"prefix\": \"perf dump\", \"format\": \"json\" }", &msg));
  ASSERT_EQ("{}", msg);
}

TEST(PerfCounters, ResetPerfCounters) {
  AdminSocketClient client(get_rand_socket_path());
  std::string msg;
  PerfCountersCollection *coll = g_ceph_context->get_perfcounters_collection();
  coll->clear();
  PerfCounters* fake_pf1 = setup_test_perfcounters1(g_ceph_context);
  coll->add(fake_pf1);

  ASSERT_EQ("", client.do_request("{ \"prefix\": \"perf reset\", \"var\": \"all\", \"format\": \"json\" }", &msg));
  ASSERT_EQ(sd("{\"success\":\"perf reset all\"}"), msg);

  ASSERT_EQ("", client.do_request("{ \"prefix\": \"perf reset\", \"var\": \"test_perfcounter_1\", \"format\": \"json\" }", &msg));
  ASSERT_EQ(sd("{\"success\":\"perf reset test_perfcounter_1\"}"), msg);

  coll->clear();
  ASSERT_EQ("", client.do_request("{ \"prefix\": \"perf reset\", \"var\": \"test_perfcounter_1\", \"format\": \"json\" }", &msg));
  ASSERT_EQ(sd("{\"error\":\"Not find: test_perfcounter_1\"}"), msg);
}

enum {
  TEST_PERFCOUNTERS3_ELEMENT_FIRST = 400,
  TEST_PERFCOUNTERS3_ELEMENT_READ,
  TEST_PERFCOUNTERS3_ELEMENT_LAST,
};

static std::shared_ptr<PerfCounters> setup_test_perfcounter3(CephContext* cct) {
  PerfCountersBuilder bld(cct, "test_percounter_3",
      TEST_PERFCOUNTERS3_ELEMENT_FIRST, TEST_PERFCOUNTERS3_ELEMENT_LAST);
  bld.add_time_avg(TEST_PERFCOUNTERS3_ELEMENT_READ, "read_avg");
  std::shared_ptr<PerfCounters> p(bld.create_perf_counters());
  return p;
}

static void counters_inc_test(std::shared_ptr<PerfCounters> fake_pf) {
  int i = 100000;
  utime_t t;

  // set to 1 nsec
  t.set_from_double(0.000000001);
  while (i--) {
    // increase by one, make sure data.u64 equal to data.avgcount
    fake_pf->tinc(TEST_PERFCOUNTERS3_ELEMENT_READ, t);
  }
}

static void counters_readavg_test(std::shared_ptr<PerfCounters> fake_pf) {
  int i = 100000;

  while (i--) {
    std::pair<uint64_t, uint64_t> dat = fake_pf->get_tavg_ns(TEST_PERFCOUNTERS3_ELEMENT_READ);
    // sum and count should be identical as we increment TEST_PERCOUNTERS_ELEMENT_READ by 1 nsec eveytime
    ASSERT_EQ(dat.first, dat.second);
  }
}

TEST(PerfCounters, read_avg) {
  std::shared_ptr<PerfCounters> fake_pf = setup_test_perfcounter3(g_ceph_context);

  std::thread t1(counters_inc_test, fake_pf);
  std::thread t2(counters_readavg_test, fake_pf);
  t2.join();
  t1.join();
}
