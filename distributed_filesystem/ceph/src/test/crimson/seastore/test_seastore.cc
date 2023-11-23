// -*- mode:C++; tab-width:8; c-basic-offset:2; indent-tabs-mode:t -*-
// vim: ts=8 sw=2 smarttab

#include <string>
#include <iostream>
#include <sstream>

#include "test/crimson/gtest_seastar.h"

#include "test/crimson/seastore/transaction_manager_test_state.h"

#include "crimson/os/futurized_collection.h"
#include "crimson/os/seastore/seastore.h"

using namespace crimson;
using namespace crimson::os;
using namespace crimson::os::seastore;
using CTransaction = ceph::os::Transaction;
using namespace std;

namespace {
  [[maybe_unused]] seastar::logger& logger() {
    return crimson::get_logger(ceph_subsys_test);
  }
}


struct seastore_test_t :
  public seastar_test_suite_t,
  SeaStoreTestState {

  coll_t coll_name{spg_t{pg_t{0, 0}}};
  CollectionRef coll;

  seastore_test_t() {}

  seastar::future<> set_up_fut() final {
    return tm_setup(
    ).then([this] {
      return seastore->create_new_collection(coll_name);
    }).then([this](auto coll_ref) {
      coll = coll_ref;
      CTransaction t;
      t.create_collection(coll_name, 4);
      return seastore->do_transaction(
	coll,
	std::move(t));
    });
  }

  seastar::future<> tear_down_fut() final {
    coll.reset();
    return tm_teardown();
  }

  void do_transaction(CTransaction &&t) {
    return seastore->do_transaction(
      coll,
      std::move(t)).get0();
  }

  void set_meta(
    const std::string& key,
    const std::string& value) {
    return seastore->write_meta(key, value).get0();
  }

  std::tuple<int, std::string> get_meta(
    const std::string& key) {
    return seastore->read_meta(key).get();
  }

  struct object_state_t {
    const coll_t cid;
    const CollectionRef coll;
    const ghobject_t oid;

    std::map<string, bufferlist> omap;
    bufferlist contents;

    void touch(
      CTransaction &t) {
      t.touch(cid, oid);
    }

    void touch(
      SeaStore &seastore) {
      CTransaction t;
      touch(t);
      seastore.do_transaction(
        coll,
        std::move(t)).get0();
    }

    void remove(
      CTransaction &t) {
      t.remove(cid, oid);
    }

    void remove(
      SeaStore &seastore) {
      CTransaction t;
      remove(t);
      seastore.do_transaction(
        coll,
        std::move(t)).get0();
    }

    void set_omap(
      CTransaction &t,
      const string &key,
      const bufferlist &val) {
      omap[key] = val;
      std::map<string, bufferlist> arg;
      arg[key] = val;
      t.omap_setkeys(
	cid,
	oid,
	arg);
    }

    void set_omap(
      SeaStore &seastore,
      const string &key,
      const bufferlist &val) {
      CTransaction t;
      set_omap(t, key, val);
      seastore.do_transaction(
	coll,
	std::move(t)).get0();
    }

    void write(
      SeaStore &seastore,
      CTransaction &t,
      uint64_t offset,
      bufferlist bl)  {
      bufferlist new_contents;
      if (offset > 0 && contents.length()) {
	new_contents.substr_of(
	  contents,
	  0,
	  std::min<size_t>(offset, contents.length())
	);
      }
      new_contents.append_zero(offset - new_contents.length());
      new_contents.append(bl);

      auto tail_offset = offset + bl.length();
      if (contents.length() > tail_offset) {
	bufferlist tail;
	tail.substr_of(
	  contents,
	  tail_offset,
	  contents.length() - tail_offset);
	new_contents.append(tail);
      }
      contents.swap(new_contents);

      t.write(
	cid,
	oid,
	offset,
	bl.length(),
	bl);
    }
    void write(
      SeaStore &seastore,
      uint64_t offset,
      bufferlist bl)  {
      CTransaction t;
      write(seastore, t, offset, bl);
      seastore.do_transaction(
	coll,
	std::move(t)).get0();
    }
    void write(
      SeaStore &seastore,
      uint64_t offset,
      size_t len,
      char fill)  {
      auto buffer = bufferptr(buffer::create(len));
      ::memset(buffer.c_str(), fill, len);
      bufferlist bl;
      bl.append(buffer);
      write(seastore, offset, bl);
    }

    void read(
      SeaStore &seastore,
      uint64_t offset,
      uint64_t len) {
      bufferlist to_check;
      to_check.substr_of(
	contents,
	offset,
	len);
      auto ret = seastore.read(
	coll,
	oid,
	offset,
	len).unsafe_get0();
      EXPECT_EQ(ret.length(), to_check.length());
      EXPECT_EQ(ret, to_check);
    }

    void check_size(SeaStore &seastore) {
      auto st = seastore.stat(
	coll,
	oid).get0();
      EXPECT_EQ(contents.length(), st.st_size);
    }

    void set_attr(
      SeaStore &seastore,
      std::string key,
      bufferlist& val) {
      CTransaction t;
      t.setattr(cid, oid, key, val);
      seastore.do_transaction(
        coll,
        std::move(t)).get0();
    }

    SeaStore::attrs_t get_attrs(
      SeaStore &seastore) {
      return seastore.get_attrs(coll, oid)
		     .handle_error(SeaStore::get_attrs_ertr::discard_all{})
		     .get();
    }

    ceph::bufferlist get_attr(
      SeaStore& seastore,
      std::string_view name) {
      return seastore.get_attr(coll, oid, name)
		      .handle_error(
			SeaStore::get_attr_errorator::discard_all{})
		      .get();
    }

    void check_omap_key(
      SeaStore &seastore,
      const string &key) {
      std::set<string> to_check;
      to_check.insert(key);
      auto result = seastore.omap_get_values(
	coll,
	oid,
	to_check).unsafe_get0();
      if (result.empty()) {
	EXPECT_EQ(omap.find(key), omap.end());
      } else {
	auto iter = omap.find(key);
	EXPECT_NE(iter, omap.end());
	if (iter != omap.end()) {
	  EXPECT_EQ(result.size(), 1);
	  EXPECT_EQ(iter->second, result.begin()->second);
	}
      }
    }

    void check_omap(SeaStore &seastore) {
      auto iter = seastore.get_omap_iterator(coll, oid).get0();
      iter->seek_to_first().get0();
      auto refiter = omap.begin();
      while (true) {
	if (!iter->valid() && refiter == omap.end())
	  break;

	if (!iter->valid() || refiter->first < iter->key()) {
	  logger().debug(
	    "check_omap: missing omap key {}",
	    refiter->first);
	  GTEST_FAIL() << "missing omap key " << refiter->first;
	  ++refiter;
	} else if (refiter == omap.end() || refiter->first > iter->key()) {
	  logger().debug(
	    "check_omap: extra omap key {}",
	    iter->key());
	  GTEST_FAIL() << "extra omap key" << iter->key();
	  iter->next().get0();
	} else {
	  EXPECT_EQ(iter->value(), refiter->second);
	  iter->next().get0();
	  ++refiter;
	}
      }
    }
  };

  map<ghobject_t, object_state_t> test_objects;
  object_state_t &get_object(
    const ghobject_t &oid) {
    return test_objects.emplace(
      std::make_pair(
	oid,
	object_state_t{coll_name, coll, oid})).first->second;
  }

  void remove_object(
    object_state_t &sobj) {

    sobj.remove(*seastore);
    auto erased = test_objects.erase(sobj.oid);
    ceph_assert(erased == 1);
  }

  void validate_objects() const {
    std::vector<ghobject_t> oids;
    for (auto& [oid, obj] : test_objects) {
      oids.emplace_back(oid);
    }
    auto ret = seastore->list_objects(
        coll,
        ghobject_t(),
        ghobject_t::get_max(),
        std::numeric_limits<uint64_t>::max()).get0();
    EXPECT_EQ(std::get<1>(ret), ghobject_t::get_max());
    EXPECT_EQ(std::get<0>(ret), oids);
  }
};

ghobject_t make_oid(int i) {
  stringstream ss;
  ss << "object_" << i;
  auto ret = ghobject_t(
    hobject_t(
      sobject_t(ss.str(), CEPH_NOSNAP)));
  ret.set_shard(shard_id_t(0));
  ret.hobj.nspace = "asdf";
  return ret;
}

template <typename T, typename V>
auto contains(const T &t, const V &v) {
  return std::find(
    t.begin(),
    t.end(),
    v) != t.end();
}

TEST_F(seastore_test_t, collection_create_list_remove)
{
  run_async([this] {
    coll_t test_coll{spg_t{pg_t{1, 0}}};
    {
      seastore->create_new_collection(test_coll).get0();
      {
	CTransaction t;
	t.create_collection(test_coll, 4);
	do_transaction(std::move(t));
      }
      auto collections = seastore->list_collections().get0();
      EXPECT_EQ(collections.size(), 2);
      EXPECT_TRUE(contains(collections, coll_name));
      EXPECT_TRUE(contains(collections,  test_coll));
    }

    {
      {
	CTransaction t;
	t.remove_collection(test_coll);
	do_transaction(std::move(t));
      }
      auto collections = seastore->list_collections().get0();
      EXPECT_EQ(collections.size(), 1);
      EXPECT_TRUE(contains(collections, coll_name));
    }
  });
}

TEST_F(seastore_test_t, meta) {
  run_async([this] {
    set_meta("key1", "value1");
    set_meta("key2", "value2");

    const auto [ret1, value1] = get_meta("key1");
    const auto [ret2, value2] = get_meta("key2");
    EXPECT_EQ(ret1, 0);
    EXPECT_EQ(ret2, 0);
    EXPECT_EQ(value1, "value1");
    EXPECT_EQ(value2, "value2");
  });
}

TEST_F(seastore_test_t, touch_stat_list_remove)
{
  run_async([this] {
    auto &test_obj = get_object(make_oid(0));
    test_obj.touch(*seastore);
    test_obj.check_size(*seastore);
    validate_objects();

    remove_object(test_obj);
    validate_objects();
  });
}

bufferlist make_bufferlist(size_t len) {
  bufferptr ptr(len);
  bufferlist bl;
  bl.append(ptr);
  return bl;
}

TEST_F(seastore_test_t, omap_test_simple)
{
  run_async([this] {
    auto &test_obj = get_object(make_oid(0));
    test_obj.set_omap(
      *seastore,
      "asdf",
      make_bufferlist(128));
    test_obj.check_omap_key(
      *seastore,
      "asdf");
  });
}

TEST_F(seastore_test_t, attr)
{
  run_async([this] {
    auto& test_obj = get_object(make_oid(0));

    std::string oi("asdfasdfasdf");
    bufferlist bl;
    encode(oi, bl);
    test_obj.set_attr(*seastore, OI_ATTR, bl);

    std::string ss("fdsfdsfs");
    bl.clear();
    encode(ss, bl);
    test_obj.set_attr(*seastore, SS_ATTR, bl);

    std::string test_val("ssssssssssss");
    bl.clear();
    encode(test_val, bl);
    test_obj.set_attr(*seastore, "test_key", bl);

    auto attrs = test_obj.get_attrs(*seastore);
    std::string oi2;
    bufferlist bl2 = attrs[OI_ATTR];
    decode(oi2, bl2);
    bl2.clear();
    bl2 = attrs[SS_ATTR];
    std::string ss2;
    decode(ss2, bl2);
    std::string test_val2;
    bl2.clear();
    bl2 = attrs["test_key"];
    decode(test_val2, bl2);
    EXPECT_EQ(ss, ss2);
    EXPECT_EQ(oi, oi2);
    EXPECT_EQ(test_val, test_val2);

    bl2.clear();
    bl2 = test_obj.get_attr(*seastore, "test_key");
    test_val2.clear();
    decode(test_val2, bl2);
    EXPECT_EQ(test_val, test_val2);

    std::cout << "test_key passed" << std::endl;
    char ss_array[256] = {0};
    std::string ss_str(&ss_array[0], 256);
    bl.clear();
    encode(ss_str, bl);
    test_obj.set_attr(*seastore, SS_ATTR, bl);

    attrs = test_obj.get_attrs(*seastore);
    std::cout << "got attr" << std::endl;
    bl2.clear();
    bl2 = attrs[SS_ATTR];
    std::string ss_str2;
    decode(ss_str2, bl2);
    EXPECT_EQ(ss_str, ss_str2);

    bl2.clear();
    ss_str2.clear();
    bl2 = test_obj.get_attr(*seastore, SS_ATTR);
    decode(ss_str2, bl2);
    EXPECT_EQ(ss_str, ss_str2);
  });
}

TEST_F(seastore_test_t, omap_test_iterator)
{
  run_async([this] {
    auto make_key = [](unsigned i) {
      std::stringstream ss;
      ss << "key" << i;
      return ss.str();
    };
    auto &test_obj = get_object(make_oid(0));
    for (unsigned i = 0; i < 20; ++i) {
      test_obj.set_omap(
	*seastore,
	make_key(i),
	make_bufferlist(128));
    }
    test_obj.check_omap(*seastore);
  });
}


TEST_F(seastore_test_t, simple_extent_test)
{
  run_async([this] {
    auto &test_obj = get_object(make_oid(0));
    test_obj.write(
      *seastore,
      1024,
      1024,
      'a');
    test_obj.read(
      *seastore,
      1024,
      1024);
    test_obj.check_size(*seastore);
  });
}
