// -*- mode:C++; tab-width:8; c-basic-offset:2; indent-tabs-mode:t -*-
// vim: ts=8 sw=2 smarttab

#pragma once

#include <random>

#include "crimson/os/seastore/transaction_manager.h"

namespace crimson::os::seastore {

struct test_extent_desc_t {
  size_t len = 0;
  unsigned checksum = 0;

  bool operator==(const test_extent_desc_t &rhs) const {
    return (len == rhs.len &&
	    checksum == rhs.checksum);
  }
  bool operator!=(const test_extent_desc_t &rhs) const {
    return !(*this == rhs);
  }
};

struct test_block_delta_t {
  int8_t val = 0;
  uint16_t offset = 0;
  uint16_t len = 0;


  DENC(test_block_delta_t, v, p) {
    DENC_START(1, 1, p);
    denc(v.val, p);
    denc(v.offset, p);
    denc(v.len, p);
    DENC_FINISH(p);
  }
};

inline std::ostream &operator<<(
  std::ostream &lhs, const test_extent_desc_t &rhs) {
  return lhs << "test_extent_desc_t(len=" << rhs.len
	     << ", checksum=" << rhs.checksum << ")";
}

struct TestBlock : crimson::os::seastore::LogicalCachedExtent {
  constexpr static seastore_off_t SIZE = 4<<10;
  using Ref = TCachedExtentRef<TestBlock>;

  std::vector<test_block_delta_t> delta = {};

  TestBlock(ceph::bufferptr &&ptr)
    : LogicalCachedExtent(std::move(ptr)) {}
  TestBlock(const TestBlock &other)
    : LogicalCachedExtent(other) {}

  CachedExtentRef duplicate_for_write() final {
    return CachedExtentRef(new TestBlock(*this));
  };

  static constexpr extent_types_t TYPE = extent_types_t::TEST_BLOCK;
  extent_types_t get_type() const final {
    return TYPE;
  }

  ceph::bufferlist get_delta() final;

  void set_contents(char c, uint16_t offset, uint16_t len) {
    ::memset(get_bptr().c_str() + offset, c, len);
    delta.push_back({c, offset, len});
  }

  void set_contents(char c) {
    set_contents(c, 0, get_length());
  }

  test_extent_desc_t get_desc() {
    return { get_length(), get_crc32c() };
  }

  void apply_delta(const ceph::bufferlist &bl) final;
};
using TestBlockRef = TCachedExtentRef<TestBlock>;

struct TestBlockPhysical : crimson::os::seastore::CachedExtent{
  constexpr static seastore_off_t SIZE = 4<<10;
  using Ref = TCachedExtentRef<TestBlockPhysical>;

  std::vector<test_block_delta_t> delta = {};

  TestBlockPhysical(ceph::bufferptr &&ptr)
    : CachedExtent(std::move(ptr)) {}
  TestBlockPhysical(const TestBlockPhysical &other)
    : CachedExtent(other) {}

  CachedExtentRef duplicate_for_write() final {
    return CachedExtentRef(new TestBlockPhysical(*this));
  };

  static constexpr extent_types_t TYPE = extent_types_t::TEST_BLOCK_PHYSICAL;
  extent_types_t get_type() const final {
    return TYPE;
  }

  void set_contents(char c, uint16_t offset, uint16_t len) {
    ::memset(get_bptr().c_str() + offset, c, len);
    delta.push_back({c, offset, len});
  }

  void set_contents(char c) {
    set_contents(c, 0, get_length());
  }

  ceph::bufferlist get_delta() final;

  void apply_delta_and_adjust_crc(paddr_t, const ceph::bufferlist &bl) final;
};
using TestBlockPhysicalRef = TCachedExtentRef<TestBlockPhysical>;

struct test_block_mutator_t {
  std::uniform_int_distribution<int8_t>
  contents_distribution = std::uniform_int_distribution<int8_t>(
    std::numeric_limits<int8_t>::min(),
    std::numeric_limits<int8_t>::max());

  std::uniform_int_distribution<uint16_t>
  offset_distribution = std::uniform_int_distribution<uint16_t>(
    0, TestBlock::SIZE - 1);

  std::uniform_int_distribution<uint16_t> length_distribution(uint16_t offset) {
    return std::uniform_int_distribution<uint16_t>(
      0, TestBlock::SIZE - offset - 1);
  }


  template <typename generator_t>
  void mutate(TestBlock &block, generator_t &gen) {
    auto offset = offset_distribution(gen);
    block.set_contents(
      contents_distribution(gen),
      offset,
      length_distribution(offset)(gen));
  }
};

}

WRITE_CLASS_DENC_BOUNDED(crimson::os::seastore::test_block_delta_t)
