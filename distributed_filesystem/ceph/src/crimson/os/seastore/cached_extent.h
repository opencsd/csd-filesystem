// -*- mode:C++; tab-width:8; c-basic-offset:2; indent-tabs-mode:t -*-
// vim: ts=8 sw=2 smarttab

#pragma once

#include <iostream>

#include <boost/intrusive/list.hpp>
#include <boost/intrusive_ptr.hpp>
#include <boost/smart_ptr/intrusive_ref_counter.hpp>

#include "seastar/core/shared_future.hh"

#include "include/buffer.h"
#include "crimson/common/errorator.h"
#include "crimson/os/seastore/seastore_types.h"

namespace crimson::os::seastore {

class ool_record_t;
class Transaction;
class CachedExtent;
using CachedExtentRef = boost::intrusive_ptr<CachedExtent>;
class SegmentedAllocator;
class TransactionManager;
class ExtentPlacementManager;

// #define DEBUG_CACHED_EXTENT_REF
#ifdef DEBUG_CACHED_EXTENT_REF

void intrusive_ptr_add_ref(CachedExtent *);
void intrusive_ptr_release(CachedExtent *);

#endif

template <typename T>
using TCachedExtentRef = boost::intrusive_ptr<T>;

/**
 * CachedExtent
 */
namespace onode {
  class DummyNodeExtent;
  class TestReplayExtent;
}

template <typename T>
class read_set_item_t {
  boost::intrusive::list_member_hook<> list_hook;
  using list_hook_options = boost::intrusive::member_hook<
    read_set_item_t,
    boost::intrusive::list_member_hook<>,
    &read_set_item_t::list_hook>;

public:
  struct cmp_t {
    using is_transparent = paddr_t;
    bool operator()(const read_set_item_t<T> &lhs, const read_set_item_t &rhs) const;
    bool operator()(const paddr_t &lhs, const read_set_item_t<T> &rhs) const;
    bool operator()(const read_set_item_t<T> &lhs, const paddr_t &rhs) const;
  };

  using list =  boost::intrusive::list<
    read_set_item_t,
    list_hook_options>;

  T *t = nullptr;
  CachedExtentRef ref;

  read_set_item_t(T *t, CachedExtentRef ref);
  read_set_item_t(const read_set_item_t &) = delete;
  read_set_item_t(read_set_item_t &&) = default;
  ~read_set_item_t();
};
template <typename T>
using read_set_t = std::set<
  read_set_item_t<T>,
  typename read_set_item_t<T>::cmp_t>;

class ExtentIndex;
class CachedExtent : public boost::intrusive_ref_counter<
  CachedExtent, boost::thread_unsafe_counter> {
  enum class extent_state_t : uint8_t {
    INITIAL_WRITE_PENDING, // In Transaction::write_set and fresh_block_list
    MUTATION_PENDING,      // In Transaction::write_set and mutated_block_list
    CLEAN_PENDING,         // CLEAN, but not yet read out
    CLEAN,                 // In Cache::extent_index, Transaction::read_set
                           //  during write, contents match disk, version == 0
    DIRTY,                 // Same as CLEAN, but contents do not match disk,
                           //  version > 0
    INVALID                // Part of no ExtentIndex set
  } state = extent_state_t::INVALID;
  friend std::ostream &operator<<(std::ostream &, extent_state_t);
  // allow a dummy extent to pretend it is at a specific state
  friend class onode::DummyNodeExtent;
  friend class onode::TestReplayExtent;

  uint32_t last_committed_crc = 0;

  // Points at current version while in state MUTATION_PENDING
  CachedExtentRef prior_instance;

public:
  /**
   *  duplicate_for_write
   *
   * Implementation should return a fresh CachedExtentRef
   * which represents a copy of *this until on_delta_write()
   * is complete, at which point the user may assume *this
   * will be in state INVALID.  As such, the implementation
   * may involve a copy of get_bptr(), or an ancillary
   * structure which defers updating the actual buffer until
   * on_delta_write().
   */
  virtual CachedExtentRef duplicate_for_write() = 0;

  /**
   * prepare_write
   *
   * Called prior to reading buffer.
   * Implemenation may use this callback to fully write out
   * updates to the buffer.
   */
  virtual void prepare_write() {}

  /**
   * on_initial_write
   *
   * Called after commit of extent.  State will be CLEAN.
   * Implentation may use this call to fixup the buffer
   * with the newly available absolute get_paddr().
   */
  virtual void on_initial_write() {}

  /**
   * on_clean_read
   *
   * Called after read of initially written extent.
   *  State will be CLEAN. Implentation may use this
   * call to fixup the buffer with the newly available
   * absolute get_paddr().
   */
  virtual void on_clean_read() {}

  /**
   * on_delta_write
   *
   * Called after commit of delta.  State will be DIRTY.
   * Implentation may use this call to fixup any relative
   * references in the the buffer with the passed
   * record_block_offset record location.
   */
  virtual void on_delta_write(paddr_t record_block_offset) {}

  /**
   * get_type
   *
   * Returns concrete type.
   */
  virtual extent_types_t get_type() const = 0;

  virtual bool is_logical() const {
    return false;
  }

  friend std::ostream &operator<<(std::ostream &, extent_state_t);
  virtual std::ostream &print_detail(std::ostream &out) const { return out; }
  std::ostream &print(std::ostream &out) const {
    out << "CachedExtent(addr=" << this
	<< ", type=" << get_type()
	<< ", version=" << version
	<< ", dirty_from_or_retired_at=" << dirty_from_or_retired_at
	<< ", paddr=" << get_paddr()
	<< ", length=" << get_length()
	<< ", state=" << state
	<< ", last_committed_crc=" << last_committed_crc
	<< ", refcount=" << use_count();
    if (state != extent_state_t::INVALID &&
        state != extent_state_t::CLEAN_PENDING) {
      print_detail(out);
    }
    return out << ")";
  }

  /**
   * get_delta
   *
   * Must return a valid delta usable in apply_delta() in submit_transaction
   * if state == MUTATION_PENDING.
   */
  virtual ceph::bufferlist get_delta() = 0;

  /**
   * apply_delta
   *
   * bl is a delta obtained previously from get_delta.  The versions will
   * match.  Implementation should mutate buffer based on bl.  base matches
   * the address passed on_delta_write.
   *
   * Implementation *must* use set_last_committed_crc to update the crc to
   * what the crc of the buffer would have been at submission.  For physical
   * extents that use base to adjust internal record-relative deltas, this
   * means that the crc should be of the buffer after applying the delta,
   * but before that adjustment.  We do it this way because the crc in the
   * commit path does not yet know the record base address.
   *
   * LogicalCachedExtent overrides this method and provides a simpler
   * apply_delta override for LogicalCachedExtent implementers.
   */
  virtual void apply_delta_and_adjust_crc(
    paddr_t base, const ceph::bufferlist &bl) = 0;

  /**
   * Called on dirty CachedExtent implementation after replay.
   * Implementation should perform any reads/in-memory-setup
   * necessary. (for instance, the lba implementation will use this
   * to load in lba_manager blocks)
   */
  using complete_load_ertr = crimson::errorator<
    crimson::ct_error::input_output_error>;
  virtual complete_load_ertr::future<> complete_load() {
    return complete_load_ertr::now();
  }

  /**
   * cast
   *
   * Returns a TCachedExtentRef of the specified type.
   * TODO: add dynamic check that the requested type is actually correct.
   */
  template <typename T>
  TCachedExtentRef<T> cast() {
    return TCachedExtentRef<T>(static_cast<T*>(this));
  }
  template <typename T>
  TCachedExtentRef<const T> cast() const {
    return TCachedExtentRef<const T>(static_cast<const T*>(this));
  }

  /// Returns true if extent is part of an open transaction
  bool is_pending() const {
    return state == extent_state_t::INITIAL_WRITE_PENDING ||
      state == extent_state_t::MUTATION_PENDING;
  }

  /// Returns true if extent has a pending delta
  bool is_mutation_pending() const {
    return state == extent_state_t::MUTATION_PENDING;
  }

  /// Returns true if extent is a fresh extent
  bool is_initial_pending() const {
    return state == extent_state_t::INITIAL_WRITE_PENDING;
  }

  /// Returns true if extent is clean (does not have deltas on disk)
  bool is_clean() const {
    ceph_assert(is_valid());
    return state == extent_state_t::INITIAL_WRITE_PENDING ||
           state == extent_state_t::CLEAN ||
           state == extent_state_t::CLEAN_PENDING;
  }

  /// Returns true if extent is dirty (has deltas on disk)
  bool is_dirty() const {
    ceph_assert(is_valid());
    return !is_clean();
  }

  /// Returns true if extent has not been superceded or retired
  bool is_valid() const {
    return state != extent_state_t::INVALID;
  }

  /// Returns true if extent or prior_instance has been invalidated
  bool has_been_invalidated() const {
    return !is_valid() || (prior_instance && !prior_instance->is_valid());
  }

  /// Returns true if extent is a plcaeholder
  bool is_placeholder() const {
    return get_type() == extent_types_t::RETIRED_PLACEHOLDER;
  }

  /// Return journal location of oldest relevant delta, only valid while DIRTY
  auto get_dirty_from() const {
    ceph_assert(is_dirty());
    return dirty_from_or_retired_at;
  }

  /// Return journal location of oldest relevant delta, only valid while RETIRED
  auto get_retired_at() const {
    ceph_assert(!is_valid());
    return dirty_from_or_retired_at;
  }

  /**
   * get_paddr
   *
   * Returns current address of extent.  If is_initial_pending(), address will
   * be relative, otherwise address will be absolute.
   */
  paddr_t get_paddr() const { return poffset; }

  /// Returns length of extent
  virtual extent_len_t get_length() const { return ptr.length(); }

  /// Returns version, get_version() == 0 iff is_clean()
  extent_version_t get_version() const {
    return version;
  }

  /// Returns crc32c of buffer
  uint32_t get_crc32c() {
    return ceph_crc32c(
      1,
      reinterpret_cast<const unsigned char *>(get_bptr().c_str()),
      get_length());
  }

  /// Get ref to raw buffer
  bufferptr &get_bptr() { return ptr; }
  const bufferptr &get_bptr() const { return ptr; }

  /// Compare by paddr
  friend bool operator< (const CachedExtent &a, const CachedExtent &b) {
    return a.poffset < b.poffset;
  }
  friend bool operator> (const CachedExtent &a, const CachedExtent &b) {
    return a.poffset > b.poffset;
  }
  friend bool operator== (const CachedExtent &a, const CachedExtent &b) {
    return a.poffset == b.poffset;
  }

  virtual ~CachedExtent();

  /// hint for allocators
  placement_hint_t hint = placement_hint_t::NUM_HINTS;

  bool is_inline() const {
    return poffset.is_relative();
  }
private:
  template <typename T>
  friend class read_set_item_t;

  friend struct paddr_cmp;
  friend struct ref_paddr_cmp;
  friend class ExtentIndex;

  /// Pointer to containing index (or null)
  ExtentIndex *parent_index = nullptr;

  /// hook for intrusive extent_index
  boost::intrusive::set_member_hook<> extent_index_hook;
  using index_member_options = boost::intrusive::member_hook<
    CachedExtent,
    boost::intrusive::set_member_hook<>,
    &CachedExtent::extent_index_hook>;
  using index = boost::intrusive::set<CachedExtent, index_member_options>;
  friend class ExtentIndex;
  friend class Transaction;

  bool is_linked() {
    return extent_index_hook.is_linked();
  }

  /// hook for intrusive ref list (mainly dirty or lru list)
  boost::intrusive::list_member_hook<> primary_ref_list_hook;
  using primary_ref_list_member_options = boost::intrusive::member_hook<
    CachedExtent,
    boost::intrusive::list_member_hook<>,
    &CachedExtent::primary_ref_list_hook>;
  using list = boost::intrusive::list<
    CachedExtent,
    primary_ref_list_member_options>;

  /**
   * dirty_from_or_retired_at
   *
   * Encodes ordering token for primary_ref_list -- dirty_from when
   * dirty or retired_at if retired.
   */
  journal_seq_t dirty_from_or_retired_at;

  /// Actual data contents
  ceph::bufferptr ptr;

  /// number of deltas since initial write
  extent_version_t version = EXTENT_VERSION_NULL;

  /// address of original block -- relative iff is_pending() and is_clean()
  paddr_t poffset;

  /// used to wait while in-progress commit completes
  std::optional<seastar::shared_promise<>> io_wait_promise;
  void set_io_wait() {
    ceph_assert(!io_wait_promise);
    io_wait_promise = seastar::shared_promise<>();
  }
  void complete_io() {
    ceph_assert(io_wait_promise);
    io_wait_promise->set_value();
    io_wait_promise = std::nullopt;
  }

  seastar::future<> wait_io() {
    if (!io_wait_promise) {
      return seastar::now();
    } else {
      return io_wait_promise->get_shared_future();
    }
  }

  read_set_item_t<Transaction>::list transactions;

protected:
  CachedExtent(CachedExtent &&other) = delete;
  CachedExtent(ceph::bufferptr &&ptr) : ptr(std::move(ptr)) {}
  CachedExtent(const CachedExtent &other)
    : state(other.state),
      dirty_from_or_retired_at(other.dirty_from_or_retired_at),
      ptr(other.ptr.c_str(), other.ptr.length()),
      version(other.version),
      poffset(other.poffset) {}

  struct share_buffer_t {};
  CachedExtent(const CachedExtent &other, share_buffer_t) :
    state(other.state),
    dirty_from_or_retired_at(other.dirty_from_or_retired_at),
    ptr(other.ptr),
    version(other.version),
    poffset(other.poffset) {}

  struct retired_placeholder_t{};
  CachedExtent(retired_placeholder_t) : state(extent_state_t::INVALID) {}

  friend class Cache;
  template <typename T, typename... Args>
  static TCachedExtentRef<T> make_cached_extent_ref(
    Args&&... args) {
    return new T(std::forward<Args>(args)...);
  }

  CachedExtentRef get_prior_instance() {
    return prior_instance;
  }

  /// Sets last_committed_crc
  void set_last_committed_crc(uint32_t crc) {
    last_committed_crc = crc;
  }

  void set_paddr(paddr_t offset) { poffset = offset; }

  /**
   * maybe_generate_relative
   *
   * There are three kinds of addresses one might want to
   * store within an extent:
   * - addr for a block within the same transaction relative to the
   *   physical location of this extent in the
   *   event that we will read it in the initial read of the extent
   * - addr relative to the physical location of the next record to a
   *   block within that record to contain a delta for this extent in
   *   the event that we'll read it from a delta and overlay it onto a
   *   dirty representation of the extent.
   * - absolute addr to a block already written outside of the current
   *   transaction.
   *
   * This helper checks addr and the current state to create the correct
   * reference.
   */
  paddr_t maybe_generate_relative(paddr_t addr) {
    if (is_initial_pending() && addr.is_record_relative()) {
      return addr - get_paddr();
    } else {
      ceph_assert(!addr.is_record_relative() || is_mutation_pending());
      return addr;
    }
  }

  friend class crimson::os::seastore::ool_record_t;
  friend class crimson::os::seastore::SegmentedAllocator;
  friend class crimson::os::seastore::TransactionManager;
  friend class crimson::os::seastore::ExtentPlacementManager;
};

std::ostream &operator<<(std::ostream &, CachedExtent::extent_state_t);
std::ostream &operator<<(std::ostream &, const CachedExtent&);

/// Compare extents by paddr
struct paddr_cmp {
  bool operator()(paddr_t lhs, const CachedExtent &rhs) const {
    return lhs < rhs.poffset;
  }
  bool operator()(const CachedExtent &lhs, paddr_t rhs) const {
    return lhs.poffset < rhs;
  }
};

/// Compare extent refs by paddr
struct ref_paddr_cmp {
  using is_transparent = paddr_t;
  bool operator()(const CachedExtentRef &lhs, const CachedExtentRef &rhs) const {
    return lhs->poffset < rhs->poffset;
  }
  bool operator()(const paddr_t &lhs, const CachedExtentRef &rhs) const {
    return lhs < rhs->poffset;
  }
  bool operator()(const CachedExtentRef &lhs, const paddr_t &rhs) const {
    return lhs->poffset < rhs;
  }
};

template <typename T, typename C>
class addr_extent_list_base_t
  : public std::list<std::pair<T, C>> {};

using pextent_list_t = addr_extent_list_base_t<paddr_t, CachedExtentRef>;

template <typename T, typename C, typename Cmp>
class addr_extent_set_base_t
  : public std::set<C, Cmp> {};

using pextent_set_t = addr_extent_set_base_t<
  paddr_t,
  CachedExtentRef,
  ref_paddr_cmp
  >;

template <typename T>
using t_pextent_list_t = addr_extent_list_base_t<paddr_t, TCachedExtentRef<T>>;

/**
 * ExtentIndex
 *
 * Index of CachedExtent & by poffset, does not hold a reference,
 * user must ensure each extent is removed prior to deletion
 */
class ExtentIndex {
  friend class Cache;
  CachedExtent::index extent_index;
public:
  auto get_overlap(paddr_t addr, seastore_off_t len) {
    auto bottom = extent_index.upper_bound(addr, paddr_cmp());
    if (bottom != extent_index.begin())
      --bottom;
    if (bottom != extent_index.end() &&
	bottom->get_paddr().add_offset(bottom->get_length()) <= addr)
      ++bottom;

    auto top = extent_index.lower_bound(addr.add_offset(len), paddr_cmp());
    return std::make_pair(
      bottom,
      top
    );
  }

  void clear() {
    struct cached_extent_disposer {
      void operator() (CachedExtent* extent) {
	extent->parent_index = nullptr;
      }
    };
    extent_index.clear_and_dispose(cached_extent_disposer());
    bytes = 0;
  }

  void insert(CachedExtent &extent) {
    // sanity check
    ceph_assert(!extent.parent_index);
    auto [a, b] = get_overlap(
      extent.get_paddr(),
      extent.get_length());
    ceph_assert(a == b);

    [[maybe_unused]] auto [iter, inserted] = extent_index.insert(extent);
    assert(inserted);
    extent.parent_index = this;

    bytes += extent.get_length();
  }

  void erase(CachedExtent &extent) {
    assert(extent.parent_index);
    assert(extent.is_linked());
    [[maybe_unused]] auto erased = extent_index.erase(
      extent_index.s_iterator_to(extent));
    extent.parent_index = nullptr;

    assert(erased);
    bytes -= extent.get_length();
  }

  void replace(CachedExtent &to, CachedExtent &from) {
    assert(to.get_length() == from.get_length());
    extent_index.replace_node(extent_index.s_iterator_to(from), to);
    from.parent_index = nullptr;
    to.parent_index = this;
  }

  bool empty() const {
    return extent_index.empty();
  }

  auto find_offset(paddr_t offset) {
    return extent_index.find(offset, paddr_cmp());
  }

  auto begin() {
    return extent_index.begin();
  }

  auto end() {
    return extent_index.end();
  }

  auto size() const {
    return extent_index.size();
  }

  auto get_bytes() const {
    return bytes;
  }

  ~ExtentIndex() {
    assert(extent_index.empty());
    assert(bytes == 0);
  }

private:
  uint64_t bytes = 0;
};

class LogicalCachedExtent;
class LBAPin;
using LBAPinRef = std::unique_ptr<LBAPin>;
class LBAPin {
public:
  virtual void link_extent(LogicalCachedExtent *ref) = 0;
  virtual void take_pin(LBAPin &pin) = 0;
  virtual extent_len_t get_length() const = 0;
  virtual paddr_t get_paddr() const = 0;
  virtual laddr_t get_laddr() const = 0;
  virtual LBAPinRef duplicate() const = 0;
  virtual bool has_been_invalidated() const = 0;

  virtual ~LBAPin() {}
};
std::ostream &operator<<(std::ostream &out, const LBAPin &rhs);

using lba_pin_list_t = std::list<LBAPinRef>;

std::ostream &operator<<(std::ostream &out, const lba_pin_list_t &rhs);

/**
 * RetiredExtentPlaceholder
 *
 * Cache::retire_extent_addr(Transaction&, paddr_t, extent_len_t) can retire an
 * extent not currently in cache. In that case, in order to detect transaction
 * invalidation, we need to add a placeholder to the cache to create the
 * mapping back to the transaction. And whenever there is a transaction tries
 * to read the placeholder extent out, Cache is responsible to replace the
 * placeholder by the real one. Anyway, No placeholder extents should escape
 * the Cache interface boundary.
 */
class RetiredExtentPlaceholder : public CachedExtent {
  extent_len_t length;

public:
  RetiredExtentPlaceholder(extent_len_t length)
    : CachedExtent(CachedExtent::retired_placeholder_t{}),
      length(length) {}

  extent_len_t get_length() const final { return length; }

  CachedExtentRef duplicate_for_write() final {
    ceph_assert(0 == "Should never happen for a placeholder");
    return CachedExtentRef();
  }

  ceph::bufferlist get_delta() final {
    ceph_assert(0 == "Should never happen for a placeholder");
    return ceph::bufferlist();
  }

  static constexpr extent_types_t TYPE = extent_types_t::RETIRED_PLACEHOLDER;
  extent_types_t get_type() const final {
    return TYPE;
  }

  void apply_delta_and_adjust_crc(
    paddr_t base, const ceph::bufferlist &bl) final {
    ceph_assert(0 == "Should never happen for a placeholder");
  }

  bool is_logical() const final {
    return false;
  }

  std::ostream &print_detail(std::ostream &out) const final {
    return out << ", RetiredExtentPlaceholder";
  }

  void on_delta_write(paddr_t record_block_offset) final {
    ceph_assert(0 == "Should never happen for a placeholder");
  }
};

/**
 * LogicalCachedExtent
 *
 * CachedExtent with associated lba mapping.
 *
 * Users of TransactionManager should be using extents derived from
 * LogicalCachedExtent.
 */
class LogicalCachedExtent : public CachedExtent {
public:
  template <typename... T>
  LogicalCachedExtent(T&&... t) : CachedExtent(std::forward<T>(t)...) {}

  void set_pin(LBAPinRef &&npin) {
    assert(!pin);
    pin = std::move(npin);
    laddr = pin->get_laddr();
    pin->link_extent(this);
  }

  bool has_pin() const {
    return !!pin;
  }

  LBAPin &get_pin() {
    assert(pin);
    return *pin;
  }

  laddr_t get_laddr() const {
    assert(laddr != L_ADDR_NULL);
    return laddr;
  }

  void set_laddr(laddr_t nladdr) {
    laddr = nladdr;
  }

  void apply_delta_and_adjust_crc(
    paddr_t base, const ceph::bufferlist &bl) final {
    apply_delta(bl);
    set_last_committed_crc(get_crc32c());
  }

  bool is_logical() const final {
    return true;
  }

  std::ostream &print_detail(std::ostream &out) const final;
protected:
  virtual void apply_delta(const ceph::bufferlist &bl) = 0;
  virtual std::ostream &print_detail_l(std::ostream &out) const {
    return out;
  }

  virtual void logical_on_delta_write() {}

  void on_delta_write(paddr_t record_block_offset) final {
    assert(get_prior_instance());
    pin->take_pin(*(get_prior_instance()->cast<LogicalCachedExtent>()->pin));
    logical_on_delta_write();
  }

private:
  laddr_t laddr = L_ADDR_NULL;
  LBAPinRef pin;
};

using LogicalCachedExtentRef = TCachedExtentRef<LogicalCachedExtent>;
struct ref_laddr_cmp {
  using is_transparent = laddr_t;
  bool operator()(const LogicalCachedExtentRef &lhs,
		  const LogicalCachedExtentRef &rhs) const {
    return lhs->get_laddr() < rhs->get_laddr();
  }
  bool operator()(const laddr_t &lhs,
		  const LogicalCachedExtentRef &rhs) const {
    return lhs < rhs->get_laddr();
  }
  bool operator()(const LogicalCachedExtentRef &lhs,
		  const laddr_t &rhs) const {
    return lhs->get_laddr() < rhs;
  }
};

template <typename T>
read_set_item_t<T>::read_set_item_t(T *t, CachedExtentRef ref)
  : t(t), ref(ref)
{
  ref->transactions.push_back(*this);
}

template <typename T>
read_set_item_t<T>::~read_set_item_t()
{
  ref->transactions.erase(ref->transactions.s_iterator_to(*this));
}

template <typename T>
inline bool read_set_item_t<T>::cmp_t::operator()(
  const read_set_item_t<T> &lhs, const read_set_item_t<T> &rhs) const {
  return lhs.ref->poffset < rhs.ref->poffset;
}
template <typename T>
inline bool read_set_item_t<T>::cmp_t::operator()(
  const paddr_t &lhs, const read_set_item_t<T> &rhs) const {
  return lhs < rhs.ref->poffset;
}
template <typename T>
inline bool read_set_item_t<T>::cmp_t::operator()(
  const read_set_item_t<T> &lhs, const paddr_t &rhs) const {
  return lhs.ref->poffset < rhs;
}

using lextent_set_t = addr_extent_set_base_t<
  laddr_t,
  LogicalCachedExtentRef,
  ref_laddr_cmp
  >;

template <typename T>
using lextent_list_t = addr_extent_list_base_t<
  laddr_t, TCachedExtentRef<T>>;

}
