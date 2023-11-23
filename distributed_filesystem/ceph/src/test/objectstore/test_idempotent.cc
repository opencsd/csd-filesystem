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

#include <iostream>
#include <iterator>
#include <sstream>
#include <boost/scoped_ptr.hpp>
#include "os/filestore/FileStore.h"
#include "global/global_init.h"
#include "common/ceph_argparse.h"
#include "common/debug.h"
#include "test/common/ObjectContents.h"
#include "FileStoreTracker.h"
#include "kv/KeyValueDB.h"
#include "os/ObjectStore.h"

using namespace std;

void usage(const string &name) {
  std::cerr << "Usage: " << name << " [new|continue] store_path store_journal db_path"
	    << std::endl;
}

template <typename T>
typename T::iterator rand_choose(T &cont) {
  if (std::empty(cont)) {
    return std::end(cont);
  }
  return std::next(std::begin(cont), rand() % cont.size());
}

int main(int argc, char **argv) {
  auto args = argv_to_vec(argc, argv);
  auto cct = global_init(NULL, args, CEPH_ENTITY_TYPE_CLIENT,
			 CODE_ENVIRONMENT_UTILITY,
			 CINIT_FLAG_NO_DEFAULT_CONFIG_FILE);
  common_init_finish(g_ceph_context);
  cct->_conf.apply_changes(nullptr);

  std::cerr << "args: " << args << std::endl;
  if (args.size() < 4) {
    usage(argv[0]);
    return 1;
  }

  string store_path(args[1]);
  string store_dev(args[2]);
  string db_path(args[3]);

  bool start_new = false;
  if (string(args[0]) == string("new")) start_new = true;

  KeyValueDB *_db = KeyValueDB::create(g_ceph_context, "leveldb", db_path);
  ceph_assert(!_db->create_and_open(std::cerr));
  boost::scoped_ptr<KeyValueDB> db(_db);
  boost::scoped_ptr<ObjectStore> store(new FileStore(cct.get(), store_path,
						     store_dev));

  coll_t coll(spg_t(pg_t(0,12),shard_id_t::NO_SHARD));
  ObjectStore::CollectionHandle ch;

  if (start_new) {
    std::cerr << "mkfs" << std::endl;
    ceph_assert(!store->mkfs());
    ObjectStore::Transaction t;
    ceph_assert(!store->mount());
    ch = store->create_new_collection(coll);
    t.create_collection(coll, 0);
    store->queue_transaction(ch, std::move(t));
  } else {
    ceph_assert(!store->mount());
    ch = store->open_collection(coll);
  }

  FileStoreTracker tracker(store.get(), db.get());

  set<string> objects;
  for (unsigned i = 0; i < 10; ++i) {
    stringstream stream;
    stream << "Object_" << i;
    tracker.verify(coll, stream.str(), true);
    objects.insert(stream.str());
  }

  while (1) {
    FileStoreTracker::Transaction t;
    for (unsigned j = 0; j < 100; ++j) {
      int val = rand() % 100;
      if (val < 30) {
	t.write(coll, *rand_choose(objects));
      } else if (val < 60) {
	t.clone(coll, *rand_choose(objects),
		*rand_choose(objects));
      } else if (val < 70) {
	t.remove(coll, *rand_choose(objects));
      } else {
	t.clone_range(coll, *rand_choose(objects),
		      *rand_choose(objects));
      }
    }
    tracker.submit_transaction(t);
    tracker.verify(coll, *rand_choose(objects));
  }
  return 0;
}
