// -*- mode:C++; tab-width:8; c-basic-offset:2; indent-tabs-mode:t -*-
// vim: ts=8 sw=2 smarttab
/*
 * Ceph - scalable distributed file system
 *
 * Author: Myoungwon Oh <ohmyoungwon@gmail.com>
 *
 * This is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License version 2.1, as published by the Free Software
 * Foundation.  See file COPYING.
 *
 */
#include "include/types.h"

#include "include/rados/buffer.h"
#include "include/rados/librados.hpp"
#include "include/rados/rados_types.hpp"

#include "acconfig.h"

#include "common/Cond.h"
#include "common/Formatter.h"
#include "common/ceph_argparse.h"
#include "common/ceph_crypto.h"
#include "common/config.h"
#include "common/debug.h"
#include "common/errno.h"
#include "common/obj_bencher.h"
#include "global/global_init.h"

#include <iostream>
#include <fstream>
#include <stdlib.h>
#include <time.h>
#include <sstream>
#include <errno.h>
#include <dirent.h>
#include <stdexcept>
#include <climits>
#include <locale>
#include <memory>
#include <math.h>

#include "tools/RadosDump.h"
#include "cls/cas/cls_cas_client.h"
#include "cls/cas/cls_cas_internal.h"
#include "include/stringify.h"
#include "global/signal_handler.h"
#include "common/CDC.h"

using namespace std;

struct EstimateResult {
  std::unique_ptr<CDC> cdc;

  uint64_t chunk_size;

  ceph::mutex lock = ceph::make_mutex("EstimateResult::lock");

  // < key, <count, chunk_size> >
  map< string, pair <uint64_t, uint64_t> > chunk_statistics;
  uint64_t total_bytes = 0;
  std::atomic<uint64_t> total_objects = {0};

  EstimateResult(std::string alg, int chunk_size)
    : cdc(CDC::create(alg, chunk_size)),
      chunk_size(1ull << chunk_size) {}

  void add_chunk(bufferlist& chunk, const std::string& fp_algo) {
    string fp;
    if (fp_algo == "sha1") {
      sha1_digest_t sha1_val = crypto::digest<crypto::SHA1>(chunk);
      fp = sha1_val.to_str();
    } else if (fp_algo == "sha256") {
      sha256_digest_t sha256_val = crypto::digest<crypto::SHA256>(chunk);
      fp = sha256_val.to_str();
    } else if (fp_algo == "sha512") {
      sha512_digest_t sha512_val = crypto::digest<crypto::SHA512>(chunk);
      fp = sha512_val.to_str();
    } else {
      ceph_assert(0 == "no support fingerperint algorithm");
    }

    std::lock_guard l(lock);
    auto p = chunk_statistics.find(fp);
    if (p != chunk_statistics.end()) {
      p->second.first++;
      if (p->second.second != chunk.length()) {
	cerr << "warning: hash collision on " << fp
	     << ": was " << p->second.second
	     << " now " << chunk.length() << std::endl;
      }
    } else {
      chunk_statistics[fp] = make_pair(1, chunk.length());
    }
    total_bytes += chunk.length();
  }

  void dump(Formatter *f) const {
    f->dump_unsigned("target_chunk_size", chunk_size);

    uint64_t dedup_bytes = 0;
    uint64_t dedup_objects = chunk_statistics.size();
    for (auto& j : chunk_statistics) {
      dedup_bytes += j.second.second;
    }
    //f->dump_unsigned("dedup_bytes", dedup_bytes);
    //f->dump_unsigned("original_bytes", total_bytes);
    f->dump_float("dedup_bytes_ratio",
		  (double)dedup_bytes / (double)total_bytes);
    f->dump_float("dedup_objects_ratio",
		  (double)dedup_objects / (double)total_objects);

    uint64_t avg = total_bytes / dedup_objects;
    uint64_t sqsum = 0;
    for (auto& j : chunk_statistics) {
      sqsum += (avg - j.second.second) * (avg - j.second.second);
    }
    uint64_t stddev = sqrt(sqsum / dedup_objects);
    f->dump_unsigned("chunk_size_average", avg);
    f->dump_unsigned("chunk_size_stddev", stddev);
  }
};

map<uint64_t, EstimateResult> dedup_estimates;  // chunk size -> result

using namespace librados;
unsigned default_op_size = 1 << 26;
unsigned default_max_thread = 2;
int32_t default_report_period = 10;
ceph::mutex glock = ceph::make_mutex("glock");

void usage()
{
  cout <<
"usage: \n"
"  ceph-dedup-tool \n"
"    [--op estimate --pool POOL --chunk-size CHUNK_SIZE --chunk-algorithm ALGO --fingerprint-algorithm FP_ALGO] \n"
"    [--op chunk-scrub --op chunk-scrub --chunk-pool POOL] \n"
"    [--op chunk-get-ref --chunk-pool POOL --object OID --target-ref OID --target-ref-pool-id POOL_ID] \n"
"    [--op chunk-put-ref --chunk-pool POOL --object OID --target-ref OID --target-ref-pool-id POOL_ID] \n"
"    [--op chunk-repair --chunk-pool POOL --object OID --target-ref OID --target-ref-pool-id POOL_ID] \n"
"    [--op dump-chunk-refs --chunk-pool POOL --object OID] \n"
"    [--op chunk-dedup --pool POOL --object OID --chunk-pool POOL --fingerprint-algorithm FP --source-off OFFSET --source-length LENGTH] \n"
"    [--op object-dedup --pool POOL --object OID --chunk-pool POOL --fingerprint-algorithm FP --dedup-cdc-chunk-size CHUNK_SIZE] \n"
  << std::endl;
  cout << "optional arguments: " << std::endl;
  cout << "   --object <object_name> " << std::endl;
  cout << "   --chunk-size <size> chunk-size (byte) " << std::endl;
  cout << "   --chunk-algorithm <fixed|fastcdc> " << std::endl;
  cout << "   --fingerprint-algorithm <sha1|sha256|sha512> " << std::endl;
  cout << "   --chunk-pool <pool name> " << std::endl;
  cout << "   --max-thread <threads> " << std::endl;
  cout << "   --report-period <seconds> " << std::endl;
  cout << "   --max-seconds <seconds>" << std::endl;
  cout << "   --max-read-size <bytes> " << std::endl;
  cout << "explanations: " << std::endl;
  cout << "   chunk-dedup performs deduplication using a chunk generated by given source" << std::endl;
  cout << "   offset and length. object-dedup deduplicates the entire object, not a chunk" << std::endl;
  exit(1);
}

template <typename I, typename T>
static int rados_sistrtoll(I &i, T *val) {
  std::string err;
  *val = strict_iecstrtoll(i->second, &err);
  if (err != "") {
    cerr << "Invalid value for " << i->first << ": " << err << std::endl;
    return -EINVAL;
  } else {
    return 0;
  }
}

class EstimateDedupRatio;
class ChunkScrub;
class CrawlerThread : public Thread
{
  IoCtx io_ctx;
  int n;
  int m;
  ObjectCursor begin;
  ObjectCursor end;
  ceph::mutex m_lock = ceph::make_mutex("CrawlerThread::Locker");
  ceph::condition_variable m_cond;
  int32_t report_period;
  bool m_stop = false;
  uint64_t total_bytes = 0;
  uint64_t total_objects = 0;
  uint64_t examined_objects = 0;
  uint64_t examined_bytes = 0;
  uint64_t max_read_size = 0;
  bool debug = false;
#define COND_WAIT_INTERVAL 10

public:
  CrawlerThread(IoCtx& io_ctx, int n, int m,
		ObjectCursor begin, ObjectCursor end, int32_t report_period,
		uint64_t num_objects, uint64_t max_read_size = default_op_size):
    io_ctx(io_ctx), n(n), m(m), begin(begin), end(end), 
    report_period(report_period), total_objects(num_objects), max_read_size(max_read_size)
  {}
  void signal(int signum) {
    std::lock_guard l{m_lock};
    m_stop = true;
    m_cond.notify_all();
  }
  virtual void print_status(Formatter *f, ostream &out) {}
  uint64_t get_examined_objects() { return examined_objects; }
  uint64_t get_examined_bytes() { return examined_bytes; }
  uint64_t get_total_bytes() { return total_bytes; }
  uint64_t get_total_objects() { return total_objects; }
  void set_debug(const bool debug_) { debug = debug_; }
  friend class EstimateDedupRatio;
  friend class ChunkScrub;
};

class EstimateDedupRatio : public CrawlerThread
{
  string chunk_algo;
  string fp_algo;
  uint64_t chunk_size;
  uint64_t max_seconds;

public:
  EstimateDedupRatio(
    IoCtx& io_ctx, int n, int m, ObjectCursor begin, ObjectCursor end,
    string chunk_algo, string fp_algo, uint64_t chunk_size, int32_t report_period,
    uint64_t num_objects, uint64_t max_read_size,
    uint64_t max_seconds):
    CrawlerThread(io_ctx, n, m, begin, end, report_period, num_objects,
		  max_read_size),
    chunk_algo(chunk_algo),
    fp_algo(fp_algo),
    chunk_size(chunk_size),
    max_seconds(max_seconds) {
  }

  void* entry() {
    estimate_dedup_ratio();
    return NULL;
  }
  void estimate_dedup_ratio();
};

class ChunkScrub: public CrawlerThread
{
  IoCtx chunk_io_ctx;
  int damaged_objects = 0;

public:
  ChunkScrub(IoCtx& io_ctx, int n, int m, ObjectCursor begin, ObjectCursor end, 
	     IoCtx& chunk_io_ctx, int32_t report_period, uint64_t num_objects):
    CrawlerThread(io_ctx, n, m, begin, end, report_period, num_objects), chunk_io_ctx(chunk_io_ctx)
    { }
  void* entry() {
    chunk_scrub_common();
    return NULL;
  }
  void chunk_scrub_common();
  int get_damaged_objects() { return damaged_objects; }
  void print_status(Formatter *f, ostream &out);
};

vector<std::unique_ptr<CrawlerThread>> estimate_threads;

static void print_dedup_estimate(std::ostream& out, std::string chunk_algo)
{
  /*
  uint64_t total_bytes = 0;
  uint64_t total_objects = 0;
  */
  uint64_t examined_objects = 0;
  uint64_t examined_bytes = 0;

  for (auto &et : estimate_threads) {
    examined_objects += et->get_examined_objects();
    examined_bytes += et->get_examined_bytes();
  }

  auto f = Formatter::create("json-pretty");
  f->open_object_section("results");
  f->dump_string("chunk_algo", chunk_algo);
  f->open_array_section("chunk_sizes");
  for (auto& i : dedup_estimates) {
    f->dump_object("chunker", i.second);
  }
  f->close_section();

  f->open_object_section("summary");
  f->dump_unsigned("examined_objects", examined_objects);
  f->dump_unsigned("examined_bytes", examined_bytes);
  /*
  f->dump_unsigned("total_objects", total_objects);
  f->dump_unsigned("total_bytes", total_bytes);
  f->dump_float("examined_ratio", (float)examined_bytes / (float)total_bytes);
  */
  f->close_section();
  f->close_section();
  f->flush(out);
}

static void handle_signal(int signum) 
{
  std::lock_guard l{glock};
  for (auto &p : estimate_threads) {
    p->signal(signum);
  }
}

void EstimateDedupRatio::estimate_dedup_ratio()
{
  ObjectCursor shard_start;
  ObjectCursor shard_end;

  io_ctx.object_list_slice(
    begin,
    end,
    n,
    m,
    &shard_start,
    &shard_end);

  utime_t start = ceph_clock_now();
  utime_t end;
  if (max_seconds) {
    end = start;
    end += max_seconds;
  }

  utime_t next_report;
  if (report_period) {
    next_report = start;
    next_report += report_period;
  }

  ObjectCursor c(shard_start);
  while (c < shard_end)
  {
    std::vector<ObjectItem> result;
    int r = io_ctx.object_list(c, shard_end, 12, {}, &result, &c);
    if (r < 0 ){
      cerr << "error object_list : " << cpp_strerror(r) << std::endl;
      return;
    }

    unsigned op_size = max_read_size;

    for (const auto & i : result) {
      const auto &oid = i.oid;

      utime_t now = ceph_clock_now();
      if (max_seconds && now > end) {
	m_stop = true;
      }
      if (m_stop) {
	return;
      }

      if (n == 0 && // first thread only
	  next_report != utime_t() && now > next_report) {
	cerr << (int)(now - start) << "s : read "
	     << dedup_estimates.begin()->second.total_bytes << " bytes so far..."
	     << std::endl;
	print_dedup_estimate(cerr, chunk_algo);
	next_report = now;
	next_report += report_period;
      }

      // read entire object
      bufferlist bl;
      uint64_t offset = 0;
      while (true) {
	bufferlist t;
	int ret = io_ctx.read(oid, t, op_size, offset);
	if (ret <= 0) {
	  break;
	}
	offset += ret;
	bl.claim_append(t);
      }
      examined_objects++;
      examined_bytes += bl.length();

      // do the chunking
      for (auto& i : dedup_estimates) {
	vector<pair<uint64_t, uint64_t>> chunks;
	i.second.cdc->calc_chunks(bl, &chunks);
	for (auto& p : chunks) {
	  bufferlist chunk;
	  chunk.substr_of(bl, p.first, p.second);
	  i.second.add_chunk(chunk, fp_algo);
	  if (debug) {
	    cout << " " << oid <<  " " << p.first << "~" << p.second << std::endl;
	  }
	}
	++i.second.total_objects;
      }
    }
  }
}

void ChunkScrub::chunk_scrub_common()
{
  ObjectCursor shard_start;
  ObjectCursor shard_end;
  int ret;
  Rados rados;

  ret = rados.init_with_context(g_ceph_context);
  if (ret < 0) {
     cerr << "couldn't initialize rados: " << cpp_strerror(ret) << std::endl;
     return;
  }
  ret = rados.connect();
  if (ret) {
     cerr << "couldn't connect to cluster: " << cpp_strerror(ret) << std::endl;
     return;
  }

  chunk_io_ctx.object_list_slice(
    begin,
    end,
    n,
    m,
    &shard_start,
    &shard_end);

  ObjectCursor c(shard_start);
  while(c < shard_end)
  {
    std::vector<ObjectItem> result;
    int r = chunk_io_ctx.object_list(c, shard_end, 12, {}, &result, &c);
    if (r < 0 ){
      cerr << "error object_list : " << cpp_strerror(r) << std::endl;
      return;
    }

    for (const auto & i : result) {
      std::unique_lock l{m_lock};
      if (m_stop) {
	Formatter *formatter = Formatter::create("json-pretty");
	print_status(formatter, cout);
	delete formatter;
	return;
      }
      auto oid = i.oid;
      cout << oid << std::endl;
      chunk_refs_t refs;
      {
	bufferlist t;
	ret = chunk_io_ctx.getxattr(oid, CHUNK_REFCOUNT_ATTR, t);
	if (ret < 0) {
	  continue;
	}
	auto p = t.cbegin();
	decode(refs, p);
      }

      examined_objects++;
      if (refs.get_type() != chunk_refs_t::TYPE_BY_OBJECT) {
	// we can't do anything here
	continue;
      }

      // check all objects
      chunk_refs_by_object_t *byo =
	static_cast<chunk_refs_by_object_t*>(refs.r.get());
      set<hobject_t> real_refs;

      uint64_t pool_missing = 0;
      uint64_t object_missing = 0;
      uint64_t does_not_ref = 0;
      for (auto& pp : byo->by_object) {
	IoCtx target_io_ctx;
	ret = rados.ioctx_create2(pp.pool, target_io_ctx);
	if (ret < 0) {
	  cerr << oid << " ref " << pp
	       << ": referencing pool does not exist" << std::endl;
	  ++pool_missing;
	  continue;
	}

	ret = cls_cas_references_chunk(target_io_ctx, pp.oid.name, oid);
	if (ret == -ENOENT) {
	  cerr << oid << " ref " << pp
	       << ": referencing object missing" << std::endl;
	  ++object_missing;
	} else if (ret == -ENOLINK) {
	  cerr << oid << " ref " << pp
	       << ": referencing object does not reference chunk"
	       << std::endl;
	  ++does_not_ref;
	}
      }
      if (pool_missing || object_missing || does_not_ref) {
	++damaged_objects;
      }
    }
  }
  cout << "--done--" << std::endl;
}

void ChunkScrub::print_status(Formatter *f, ostream &out)
{
  if (f) {
    f->open_array_section("chunk_scrub");
    f->dump_string("PID", stringify(get_pid()));
    f->open_object_section("Status");
    f->dump_string("Total object", stringify(total_objects));
    f->dump_string("Examined objects", stringify(examined_objects));
    f->dump_string("damaged objects", stringify(damaged_objects));
    f->close_section();
    f->flush(out);
    cout << std::endl;
  }
}

int estimate_dedup_ratio(const std::map < std::string, std::string > &opts,
			  std::vector<const char*> &nargs)
{
  Rados rados;
  IoCtx io_ctx;
  std::string chunk_algo = "fastcdc";
  string fp_algo = "sha1";
  string pool_name;
  uint64_t chunk_size = 0;
  uint64_t min_chunk_size = 8192;
  uint64_t max_chunk_size = 4*1024*1024;
  unsigned max_thread = default_max_thread;
  uint32_t report_period = default_report_period;
  uint64_t max_read_size = default_op_size;
  uint64_t max_seconds = 0;
  int ret;
  std::map<std::string, std::string>::const_iterator i;
  bool debug = false;
  ObjectCursor begin;
  ObjectCursor end;
  librados::pool_stat_t s; 
  list<string> pool_names;
  map<string, librados::pool_stat_t> stats;

  i = opts.find("pool");
  if (i != opts.end()) {
    pool_name = i->second.c_str();
  }
  i = opts.find("chunk-algorithm");
  if (i != opts.end()) {
    chunk_algo = i->second.c_str();
    if (!CDC::create(chunk_algo, 12)) {
      cerr << "unrecognized chunk-algorithm " << chunk_algo << std::endl;
      exit(1);
    }
  } else {
    cerr << "must specify chunk-algorithm" << std::endl;
    exit(1);
  }

  i = opts.find("fingerprint-algorithm");
  if (i != opts.end()) {
    fp_algo = i->second.c_str();
    if (fp_algo != "sha1"
	&& fp_algo != "sha256" && fp_algo != "sha512") {
      cerr << "unrecognized fingerprint-algorithm " << fp_algo << std::endl;
      exit(1);
    }
  }

  i = opts.find("chunk-size");
  if (i != opts.end()) {
    if (rados_sistrtoll(i, &chunk_size)) {
      return -EINVAL;
    }
  }

  i = opts.find("min-chunk-size");
  if (i != opts.end()) {
    if (rados_sistrtoll(i, &min_chunk_size)) {
      return -EINVAL;
    }
  }
  i = opts.find("max-chunk-size");
  if (i != opts.end()) {
    if (rados_sistrtoll(i, &max_chunk_size)) {
      return -EINVAL;
    }
  }

  i = opts.find("max-thread");
  if (i != opts.end()) {
    if (rados_sistrtoll(i, &max_thread)) {
      return -EINVAL;
    }
  } 

  i = opts.find("report-period");
  if (i != opts.end()) {
    if (rados_sistrtoll(i, &report_period)) {
      return -EINVAL;
    }
  }
  i = opts.find("max-seconds");
  if (i != opts.end()) {
    if (rados_sistrtoll(i, &max_seconds)) {
      return -EINVAL;
    }
  }
  i = opts.find("max-read-size");
  if (i != opts.end()) {
    if (rados_sistrtoll(i, &max_read_size)) {
      return -EINVAL;
    }
  } 
  i = opts.find("debug");
  if (i != opts.end()) {
    debug = true;
  }

  i = opts.find("pgid");
  boost::optional<pg_t> pgid(i != opts.end(), pg_t());

  ret = rados.init_with_context(g_ceph_context);
  if (ret < 0) {
     cerr << "couldn't initialize rados: " << cpp_strerror(ret) << std::endl;
     goto out;
  }
  ret = rados.connect();
  if (ret) {
     cerr << "couldn't connect to cluster: " << cpp_strerror(ret) << std::endl;
     ret = -1;
     goto out;
  }
  if (pool_name.empty()) {
    cerr << "--create-pool requested but pool_name was not specified!" << std::endl;
    exit(1);
  }
  ret = rados.ioctx_create(pool_name.c_str(), io_ctx);
  if (ret < 0) {
    cerr << "error opening pool "
	 << pool_name << ": "
	 << cpp_strerror(ret) << std::endl;
    goto out;
  }

  // set up chunkers
  if (chunk_size) {
    dedup_estimates.emplace(std::piecewise_construct,
			    std::forward_as_tuple(chunk_size),
			    std::forward_as_tuple(chunk_algo, cbits(chunk_size)-1));
  } else {
    for (size_t cs = min_chunk_size; cs <= max_chunk_size; cs *= 2) {
      dedup_estimates.emplace(std::piecewise_construct,
			      std::forward_as_tuple(cs),
			      std::forward_as_tuple(chunk_algo, cbits(cs)-1));
    }
  }

  glock.lock();
  begin = io_ctx.object_list_begin();
  end = io_ctx.object_list_end();
  pool_names.push_back(pool_name);
  ret = rados.get_pool_stats(pool_names, stats);
  if (ret < 0) {
    cerr << "error fetching pool stats: " << cpp_strerror(ret) << std::endl;
    glock.unlock();
    return ret;
  }
  if (stats.find(pool_name) == stats.end()) {
    cerr << "stats can not find pool name: " << pool_name << std::endl;
    glock.unlock();
    return ret;
  }
  s = stats[pool_name];

  for (unsigned i = 0; i < max_thread; i++) {
    std::unique_ptr<CrawlerThread> ptr (
      new EstimateDedupRatio(io_ctx, i, max_thread, begin, end,
			     chunk_algo, fp_algo, chunk_size,
			     report_period, s.num_objects, max_read_size,
			     max_seconds));
    ptr->create("estimate_thread");
    ptr->set_debug(debug);
    estimate_threads.push_back(move(ptr));
  }
  glock.unlock();

  for (auto &p : estimate_threads) {
    p->join();
  }

  print_dedup_estimate(cout, chunk_algo);

 out:
  return (ret < 0) ? 1 : 0;
}

static void print_chunk_scrub()
{
  uint64_t total_objects = 0;
  uint64_t examined_objects = 0;
  int damaged_objects = 0;

  for (auto &et : estimate_threads) {
    if (!total_objects) {
      total_objects = et->get_total_objects();
    }
    examined_objects += et->get_examined_objects();
    ChunkScrub *ptr = static_cast<ChunkScrub*>(et.get());
    damaged_objects += ptr->get_damaged_objects();
  }

  cout << " Total object : " << total_objects << std::endl;
  cout << " Examined object : " << examined_objects << std::endl;
  cout << " Damaged object : " << damaged_objects << std::endl;
}

int chunk_scrub_common(const std::map < std::string, std::string > &opts,
			  std::vector<const char*> &nargs)
{
  Rados rados;
  IoCtx io_ctx, chunk_io_ctx;
  std::string object_name, target_object_name;
  string chunk_pool_name, op_name;
  int ret;
  unsigned max_thread = default_max_thread;
  std::map<std::string, std::string>::const_iterator i;
  uint32_t report_period = default_report_period;
  ObjectCursor begin;
  ObjectCursor end;
  librados::pool_stat_t s; 
  list<string> pool_names;
  map<string, librados::pool_stat_t> stats;

  i = opts.find("op_name");
  if (i != opts.end()) {
    op_name= i->second.c_str();
  } else {
    cerr << "must specify op" << std::endl;
    exit(1);
  }

  i = opts.find("chunk-pool");
  if (i != opts.end()) {
    chunk_pool_name = i->second.c_str();
  } else {
    cerr << "must specify --chunk-pool" << std::endl;
    exit(1);
  }
  i = opts.find("max-thread");
  if (i != opts.end()) {
    if (rados_sistrtoll(i, &max_thread)) {
      return -EINVAL;
    }
  } 
  i = opts.find("report-period");
  if (i != opts.end()) {
    if (rados_sistrtoll(i, &report_period)) {
      return -EINVAL;
    }
  } 
  i = opts.find("pgid");
  boost::optional<pg_t> pgid(i != opts.end(), pg_t());

  ret = rados.init_with_context(g_ceph_context);
  if (ret < 0) {
     cerr << "couldn't initialize rados: " << cpp_strerror(ret) << std::endl;
     goto out;
  }
  ret = rados.connect();
  if (ret) {
     cerr << "couldn't connect to cluster: " << cpp_strerror(ret) << std::endl;
     ret = -1;
     goto out;
  }
  ret = rados.ioctx_create(chunk_pool_name.c_str(), chunk_io_ctx);
  if (ret < 0) {
    cerr << "error opening pool "
	 << chunk_pool_name << ": "
	 << cpp_strerror(ret) << std::endl;
    goto out;
  }

  if (op_name == "chunk-get-ref" ||
      op_name == "chunk-put-ref" ||
      op_name == "chunk-repair") {
    string target_object_name;
    uint64_t pool_id;
    i = opts.find("object");
    if (i != opts.end()) {
      object_name = i->second.c_str();
    } else {
      cerr << "must specify object" << std::endl;
      exit(1);
    }
    i = opts.find("target-ref");
    if (i != opts.end()) {
      target_object_name = i->second.c_str();
    } else {
      cerr << "must specify target ref" << std::endl;
      exit(1);
    }
    i = opts.find("target-ref-pool-id");
    if (i != opts.end()) {
      if (rados_sistrtoll(i, &pool_id)) {
	return -EINVAL;
      }
    } else {
      cerr << "must specify target-ref-pool-id" << std::endl;
      exit(1);
    }

    uint32_t hash;
    ret = chunk_io_ctx.get_object_hash_position2(object_name, &hash);
    if (ret < 0) {
      return ret;
    }
    hobject_t oid(sobject_t(target_object_name, CEPH_NOSNAP), "", hash, pool_id, "");

    auto run_op = [] (ObjectWriteOperation& op, hobject_t& oid,
      string& object_name, IoCtx& chunk_io_ctx) -> int {
      int ret = chunk_io_ctx.operate(object_name, &op);
      if (ret < 0) {
	cerr << " operate fail : " << cpp_strerror(ret) << std::endl;
      }
      return ret;
    };

    ObjectWriteOperation op;
    if (op_name == "chunk-get-ref") {
      cls_cas_chunk_get_ref(op, oid);
      ret = run_op(op, oid, object_name, chunk_io_ctx);
    } else if (op_name == "chunk-put-ref") {
      cls_cas_chunk_put_ref(op, oid);
      ret = run_op(op, oid, object_name, chunk_io_ctx);
    } else if (op_name == "chunk-repair") {
      ret = rados.ioctx_create2(pool_id, io_ctx);
      if (ret < 0) {
	cerr << oid << " ref " << pool_id
	     << ": referencing pool does not exist" << std::endl;
	return ret;
      }
      int chunk_ref = -1, base_ref = -1;
      // read object on chunk pool to know how many reference the object has
      bufferlist t;
      ret = chunk_io_ctx.getxattr(object_name, CHUNK_REFCOUNT_ATTR, t);
      if (ret < 0) {
	return ret;
      }
      chunk_refs_t refs;
      auto p = t.cbegin();
      decode(refs, p);
      if (refs.get_type() != chunk_refs_t::TYPE_BY_OBJECT) {
	cerr << " does not supported chunk type " << std::endl;
	return -1;
      }
      chunk_ref =
	static_cast<chunk_refs_by_object_t*>(refs.r.get())->by_object.count(oid);
      if (chunk_ref < 0) {
	cerr << object_name << " has no reference of " << target_object_name
	     << std::endl;
	return chunk_ref;
      }
      cout << object_name << " has " << chunk_ref << " references for "
	   << target_object_name << std::endl;

      // read object on base pool to know the number of chunk object's references
      base_ref = cls_cas_references_chunk(io_ctx, target_object_name, object_name);
      if (base_ref < 0) {
	if (base_ref == -ENOENT || base_ref == -ENOLINK) {
	  base_ref = 0;
	} else {
	  return base_ref;
	}
      }
      cout << target_object_name << " has " << base_ref << " references for "
	   << object_name << std::endl;
      if (chunk_ref != base_ref) {
	if (base_ref > chunk_ref) {
	  cerr << "error : " << target_object_name << "'s ref. < " << object_name
	       << "' ref. " << std::endl;
	  return -EINVAL;
	}
	cout << " fix dangling reference from " << chunk_ref << " to " << base_ref
	     << std::endl;
	while (base_ref != chunk_ref) {
	  ObjectWriteOperation op;
	  cls_cas_chunk_put_ref(op, oid);
	  chunk_ref--;
	  ret = run_op(op, oid, object_name, chunk_io_ctx);
	  if (ret < 0) {
	    return ret;
	  }
	}
      }
    }
    return ret;

  } else if (op_name == "dump-chunk-refs") {
    i = opts.find("object");
    if (i != opts.end()) {
      object_name = i->second.c_str();
    } else {
      cerr << "must specify object" << std::endl;
      exit(1);
    }
    bufferlist t;
    ret = chunk_io_ctx.getxattr(object_name, CHUNK_REFCOUNT_ATTR, t);
    if (ret < 0) {
      return ret;
    }
    chunk_refs_t refs;
    auto p = t.cbegin();
    decode(refs, p);
    auto f = Formatter::create("json-pretty");
    f->dump_object("refs", refs);
    f->flush(cout);
    return 0;
  }

  glock.lock();
  begin = chunk_io_ctx.object_list_begin();
  end = chunk_io_ctx.object_list_end();
  pool_names.push_back(chunk_pool_name);
  ret = rados.get_pool_stats(pool_names, stats);
  if (ret < 0) {
    cerr << "error fetching pool stats: " << cpp_strerror(ret) << std::endl;
    glock.unlock();
    return ret;
  }
  if (stats.find(chunk_pool_name) == stats.end()) {
    cerr << "stats can not find pool name: " << chunk_pool_name << std::endl;
    glock.unlock();
    return ret;
  }
  s = stats[chunk_pool_name];

  for (unsigned i = 0; i < max_thread; i++) {
    std::unique_ptr<CrawlerThread> ptr (
      new ChunkScrub(io_ctx, i, max_thread, begin, end, chunk_io_ctx,
		     report_period, s.num_objects));
    ptr->create("estimate_thread");
    estimate_threads.push_back(move(ptr));
  }
  glock.unlock();

  for (auto &p : estimate_threads) {
    cout << "join " << std::endl;
    p->join();
    cout << "joined " << std::endl;
  }

  print_chunk_scrub();

out:
  return (ret < 0) ? 1 : 0;
}

string make_pool_str(string pool, string var, string val)
{
  return string("{\"prefix\": \"osd pool set\",\"pool\":\"") + pool
    + string("\",\"var\": \"") + var + string("\",\"val\": \"")
    + val + string("\"}");
}

string make_pool_str(string pool, string var, int val)
{
  return make_pool_str(pool, var, stringify(val));
}

int make_dedup_object(const std::map < std::string, std::string > &opts,
		      std::vector<const char*> &nargs)
{
  Rados rados;
  IoCtx io_ctx, chunk_io_ctx;
  std::string object_name, chunk_pool_name, op_name, pool_name, fp_algo;
  int ret;
  std::map<std::string, std::string>::const_iterator i;

  i = opts.find("op_name");
  if (i != opts.end()) {
    op_name = i->second;
  } else {
    cerr << "must specify op" << std::endl;
    exit(1);
  }
  i = opts.find("pool");
  if (i != opts.end()) {
    pool_name = i->second;
  } else {
    cerr << "must specify --pool" << std::endl;
    exit(1);
  }
  i = opts.find("object");
  if (i != opts.end()) {
    object_name = i->second;
  } else {
    cerr << "must specify object" << std::endl;
    exit(1);
  }

  i = opts.find("chunk-pool");
  if (i != opts.end()) {
    chunk_pool_name = i->second;
  } else {
    cerr << "must specify --chunk-pool" << std::endl;
    exit(1);
  }
  i = opts.find("pgid");
  boost::optional<pg_t> pgid(i != opts.end(), pg_t());

  ret = rados.init_with_context(g_ceph_context);
  if (ret < 0) {
     cerr << "couldn't initialize rados: " << cpp_strerror(ret) << std::endl;
     goto out;
  }
  ret = rados.connect();
  if (ret) {
     cerr << "couldn't connect to cluster: " << cpp_strerror(ret) << std::endl;
     ret = -1;
     goto out;
  }
  ret = rados.ioctx_create(pool_name.c_str(), io_ctx);
  if (ret < 0) {
    cerr << "error opening pool "
	 << chunk_pool_name << ": "
	 << cpp_strerror(ret) << std::endl;
    goto out;
  }
  ret = rados.ioctx_create(chunk_pool_name.c_str(), chunk_io_ctx);
  if (ret < 0) {
    cerr << "error opening pool "
	 << chunk_pool_name << ": "
	 << cpp_strerror(ret) << std::endl;
    goto out;
  }
  i = opts.find("fingerprint-algorithm");
  if (i != opts.end()) {
    fp_algo = i->second.c_str();
    if (fp_algo != "sha1"
	&& fp_algo != "sha256" && fp_algo != "sha512") {
      cerr << "unrecognized fingerprint-algorithm " << fp_algo << std::endl;
      exit(1);
    }
  }

  if (op_name == "chunk-dedup") {
    uint64_t offset, length;
    string chunk_object;
    i = opts.find("source-off");
    if (i != opts.end()) {
      if (rados_sistrtoll(i, &offset)) {
	return -EINVAL;
      }
    } else {
      cerr << "must specify --source-off" << std::endl;
      exit(1);
    }
    i = opts.find("source-length");
    if (i != opts.end()) {
      if (rados_sistrtoll(i, &length)) {
	return -EINVAL;
      }
    } else {
      cerr << "must specify --source-off" << std::endl;
      exit(1);
    }
    // 1. make a copy from manifest object to chunk object
    bufferlist bl;
    ret = io_ctx.read(object_name, bl, length, offset);
    if (ret < 0) {
      cerr << " reading object in base pool fails : " << cpp_strerror(ret) << std::endl;
      goto out;
    }
    chunk_object = [&fp_algo, &bl]() -> string {
      if (fp_algo == "sha1") {
        return ceph::crypto::digest<ceph::crypto::SHA1>(bl).to_str();
      } else if (fp_algo == "sha256") {
        return ceph::crypto::digest<ceph::crypto::SHA256>(bl).to_str();
      } else if (fp_algo == "sha512") {
        return ceph::crypto::digest<ceph::crypto::SHA512>(bl).to_str();
      } else {
        assert(0 == "unrecognized fingerprint type");
        return {};
      }
    }();
    ret = chunk_io_ctx.write(chunk_object, bl, length, offset);
    if (ret < 0) {
      cerr << " writing object in chunk pool fails : " << cpp_strerror(ret) << std::endl;
      goto out;
    }
    // 2. call set_chunk
    ObjectReadOperation op;
    op.set_chunk(offset, length, chunk_io_ctx, chunk_object, 0,
	CEPH_OSD_OP_FLAG_WITH_REFERENCE);
    ret = io_ctx.operate(object_name, &op, NULL);
    if (ret < 0) {
      cerr << " operate fail : " << cpp_strerror(ret) << std::endl;
      goto out;
    }
  } else if (op_name == "object-dedup") {
    unsigned chunk_size;
    i = opts.find("dedup-cdc-chunk-size");
    if (i != opts.end()) {
      if (rados_sistrtoll(i, &chunk_size)) {
	cerr << "unrecognized dedup_cdc_chunk_size " << chunk_size << std::endl;
	return -EINVAL;
      }
    }

    bufferlist inbl;
    ret = rados.mon_command(
	make_pool_str(pool_name, "fingerprint_algorithm", fp_algo),
	inbl, NULL, NULL);
    if (ret < 0) {
      cerr << " operate fail : " << cpp_strerror(ret) << std::endl;
      return ret;
    }
    ret = rados.mon_command(
	make_pool_str(pool_name, "dedup_tier", chunk_pool_name),
	inbl, NULL, NULL);
    if (ret < 0) {
      cerr << " operate fail : " << cpp_strerror(ret) << std::endl;
      return ret;
    }
    ret = rados.mon_command(
	make_pool_str(pool_name, "dedup_chunk_algorithm", "fastcdc"),
	inbl, NULL, NULL);
    if (ret < 0) {
      cerr << " operate fail : " << cpp_strerror(ret) << std::endl;
      return ret;
    }
    ret = rados.mon_command(
	make_pool_str(pool_name, "dedup_cdc_chunk_size", chunk_size),
	inbl, NULL, NULL);
    if (ret < 0) {
      cerr << " operate fail : " << cpp_strerror(ret) << std::endl;
      return ret;
    }

    /*
     * TODO: add a better way to make an object a manifest object.  
     * We're using set_chunk with an incorrect object here simply to make 
     * the object a manifest object, the tier_flush() will remove
     * it and replace it with the real contents.
     */
    // convert object to manifest object
    ObjectWriteOperation op;
    bufferlist temp;
    temp.append("temp");
    op.write_full(temp);

    auto gen_r_num = [] () -> string {
      std::random_device rd;
      std::mt19937 gen(rd());
      std::uniform_int_distribution<uint64_t> dist;
      uint64_t r_num = dist(gen);
      return to_string(r_num);
    };
    string temp_oid = gen_r_num();
    // create temp chunk object for set-chunk
    ret = chunk_io_ctx.operate(temp_oid, &op);
    if (ret == -EEXIST) {
      // one more try
      temp_oid = gen_r_num();
      ret = chunk_io_ctx.operate(temp_oid, &op);
    }
    if (ret < 0) {
      cerr << " operate fail : " << cpp_strerror(ret) << std::endl;
      goto out;
    }

    // set-chunk to make manifest object
    ObjectReadOperation chunk_op;
    chunk_op.set_chunk(0, 4, chunk_io_ctx, temp_oid, 0,
      CEPH_OSD_OP_FLAG_WITH_REFERENCE);
    ret = io_ctx.operate(object_name, &chunk_op, NULL);
    if (ret < 0) {
      cerr << " set_chunk fail : " << cpp_strerror(ret) << std::endl;
      goto out;
    }

    // tier-flush to perform deduplication
    ObjectReadOperation flush_op;
    flush_op.tier_flush();
    ret = io_ctx.operate(object_name, &flush_op, NULL);
    if (ret < 0) {
      cerr << " tier_flush fail : " << cpp_strerror(ret) << std::endl;
      goto out;
    }

    // tier-evict
    ObjectReadOperation evict_op;
    evict_op.tier_evict();
    ret = io_ctx.operate(object_name, &evict_op, NULL);
    if (ret < 0) {
      cerr << " tier_evict fail : " << cpp_strerror(ret) << std::endl;
      goto out;
    }
  }

out:
  return (ret < 0) ? 1 : 0;
}

int main(int argc, const char **argv)
{
  auto args = argv_to_vec(argc, argv);
  if (args.empty()) {
    cerr << argv[0] << ": -h or --help for usage" << std::endl;
    exit(1);
  }
  if (ceph_argparse_need_usage(args)) {
    usage();
    exit(0);
  }

  std::string fn;
  string op_name;

  auto cct = global_init(NULL, args, CEPH_ENTITY_TYPE_CLIENT,
			     CODE_ENVIRONMENT_UTILITY, 0);
  common_init_finish(g_ceph_context);
  init_async_signal_handler();
  register_async_signal_handler_oneshot(SIGINT, handle_signal);
  register_async_signal_handler_oneshot(SIGTERM, handle_signal);
  std::map < std::string, std::string > opts;
  std::string val;
  std::vector<const char*>::iterator i;
  for (i = args.begin(); i != args.end(); ) {
    if (ceph_argparse_double_dash(args, i)) {
      break;
    } else if (ceph_argparse_witharg(args, i, &val, "--op", (char*)NULL)) {
      opts["op_name"] = val;
      op_name = val;
    } else if (ceph_argparse_witharg(args, i, &val, "--pool", (char*)NULL)) {
      opts["pool"] = val;
    } else if (ceph_argparse_witharg(args, i, &val, "--object", (char*)NULL)) {
      opts["object"] = val;
    } else if (ceph_argparse_witharg(args, i, &val, "--chunk-algorithm", (char*)NULL)) {
      opts["chunk-algorithm"] = val;
    } else if (ceph_argparse_witharg(args, i, &val, "--chunk-size", (char*)NULL)) {
      opts["chunk-size"] = val;
    } else if (ceph_argparse_witharg(args, i, &val, "--fingerprint-algorithm", (char*)NULL)) {
      opts["fingerprint-algorithm"] = val;
    } else if (ceph_argparse_witharg(args, i, &val, "--chunk-pool", (char*)NULL)) {
      opts["chunk-pool"] = val;
    } else if (ceph_argparse_witharg(args, i, &val, "--target-ref", (char*)NULL)) {
      opts["target-ref"] = val;
    } else if (ceph_argparse_witharg(args, i, &val, "--target-ref-pool-id", (char*)NULL)) {
      opts["target-ref-pool-id"] = val;
    } else if (ceph_argparse_witharg(args, i, &val, "--max-thread", (char*)NULL)) {
      opts["max-thread"] = val;
    } else if (ceph_argparse_witharg(args, i, &val, "--report-period", (char*)NULL)) {
      opts["report-period"] = val;
    } else if (ceph_argparse_witharg(args, i, &val, "--max-read-size", (char*)NULL)) {
      opts["max-seconds"] = val;
    } else if (ceph_argparse_witharg(args, i, &val, "--max-seconds", (char*)NULL)) {
      opts["max-seconds"] = val;
    } else if (ceph_argparse_witharg(args, i, &val, "--min-chunk-size", (char*)NULL)) {
      opts["min-chunk-size"] = val;
    } else if (ceph_argparse_witharg(args, i, &val, "--max-chunk-size", (char*)NULL)) {
      opts["max-chunk-size"] = val;
    } else if (ceph_argparse_witharg(args, i, &val, "--chunk-object", (char*)NULL)) {
      opts["chunk-object"] = val;
    } else if (ceph_argparse_witharg(args, i, &val, "--source-off", (char*)NULL)) {
      opts["source-off"] = val;
    } else if (ceph_argparse_witharg(args, i, &val, "--source-length", (char*)NULL)) {
      opts["source-length"] = val;
    } else if (ceph_argparse_witharg(args, i, &val, "--dedup-cdc-chunk-size", (char*)NULL)) {
      opts["dedup-cdc-chunk-size"] = val;
    } else if (ceph_argparse_flag(args, i, "--debug", (char*)NULL)) {
      opts["debug"] = "true";
    } else {
      if (val[0] == '-') {
	cerr << "unrecognized option " << val << std::endl;
	exit(1);
      }
      ++i;
    }
  }

  if (op_name == "estimate") {
    return estimate_dedup_ratio(opts, args);
  } else if (op_name == "chunk-scrub" ||
	     op_name == "chunk-get-ref" ||
	     op_name == "chunk-put-ref" ||
	     op_name == "chunk-repair" ||
	     op_name == "dump-chunk-refs") {
    return chunk_scrub_common(opts, args);
  } else if (op_name == "chunk-dedup" ||
	     op_name == "object-dedup") {
    /*
     * chunk-dedup:
     * using a chunk generated by given source,
     * create a new object in the chunk pool or increase the reference 
     * if the object exists
     * 
     * object-dedup:
     * perform deduplication on the entire object, not a chunk.
     *
     */
    return make_dedup_object(opts, args);
  } else {
    cerr << "unrecognized op " << op_name << std::endl;
    exit(1);
  }

  unregister_async_signal_handler(SIGINT, handle_signal);
  unregister_async_signal_handler(SIGTERM, handle_signal);
  shutdown_async_signal_handler();
  
  return 0;
}
