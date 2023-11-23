// -*- mode:C++; tab-width:8; c-basic-offset:2; indent-tabs-mode:t -*-
// vim: ts=8 sw=2 smarttab

#include <sys/mman.h>
#include <string.h>

#include "include/buffer.h"

#include "crimson/common/config_proxy.h"
#include "crimson/common/errorator-loop.h"

#include "crimson/os/seastore/logging.h"
#include "crimson/os/seastore/segment_manager/block.h"

SET_SUBSYS(seastore_device);
/*
 * format:
 * - D<device-id> S<segment-id> offset=<off>~<len> poffset=<off> information
 * - D<device-id> poffset=<off>~<len> information
 *
 * levels:
 * - INFO:  major initiation, closing and segment operations
 * - DEBUG: INFO details, major read and write operations
 * - TRACE: DEBUG details
 */

namespace crimson::os::seastore::segment_manager::block {

static write_ertr::future<> do_write(
  device_id_t device_id,
  seastar::file &device,
  uint64_t offset,
  bufferptr &bptr)
{
  LOG_PREFIX(block_do_write);
  auto len = bptr.length();
  TRACE("D{} poffset={}~{} ...", device_id, offset, len);
  return device.dma_write(
    offset,
    bptr.c_str(),
    len
  ).handle_exception(
    [FNAME, device_id, offset, len](auto e) -> write_ertr::future<size_t> {
    ERROR("D{} poffset={}~{} got error -- {}",
          device_id, offset, len, e);
    return crimson::ct_error::input_output_error::make();
  }).then([FNAME, device_id, offset, len](auto result) -> write_ertr::future<> {
    if (result != len) {
      ERROR("D{} poffset={}~{} write len={} inconsistent",
            device_id, offset, len, result);
      return crimson::ct_error::input_output_error::make();
    }
    TRACE("D{} poffset={}~{} done", device_id, offset, len);
    return write_ertr::now();
  });
}

static write_ertr::future<> do_writev(
  device_id_t device_id,
  seastar::file &device,
  uint64_t offset,
  bufferlist&& bl,
  size_t block_size)
{
  LOG_PREFIX(block_do_writev);
  TRACE("D{} poffset={}~{}, {} buffers",
        device_id, offset, bl.length(), bl.get_num_buffers());

  // writev requires each buffer to be aligned to the disks' block
  // size, we need to rebuild here
  bl.rebuild_aligned(block_size);

  return seastar::do_with(
    bl.prepare_iovs(),
    std::move(bl),
    [&device, device_id, offset, FNAME](auto& iovs, auto& bl)
  {
    return write_ertr::parallel_for_each(
      iovs,
      [&device, device_id, offset, FNAME](auto& p) mutable
    {
      auto off = offset + p.offset;
      auto len = p.length;
      auto& iov = p.iov;
      TRACE("D{} poffset={}~{} dma_write ...",
            device_id, off, len);
      return device.dma_write(off, std::move(iov)
      ).handle_exception(
        [FNAME, device_id, off, len](auto e) -> write_ertr::future<size_t>
      {
        ERROR("D{} poffset={}~{} dma_write got error -- {}",
              device_id, off, len, e);
	return crimson::ct_error::input_output_error::make();
      }).then([FNAME, device_id, off, len](size_t written) -> write_ertr::future<> {
	if (written != len) {
          ERROR("D{} poffset={}~{} dma_write len={} inconsistent",
                device_id, off, len, written);
	  return crimson::ct_error::input_output_error::make();
	}
        TRACE("D{} poffset={}~{} dma_write done",
              device_id, off, len);
	return write_ertr::now();
      });
    });
  });
}

static read_ertr::future<> do_read(
  device_id_t device_id,
  seastar::file &device,
  uint64_t offset,
  size_t len,
  bufferptr &bptr)
{
  LOG_PREFIX(block_do_read);
  TRACE("D{} poffset={}~{} ...", device_id, offset, len);
  assert(len <= bptr.length());
  return device.dma_read(
    offset,
    bptr.c_str(),
    len
  ).handle_exception(
    //FIXME: this is a little bit tricky, since seastar::future<T>::handle_exception
    //	returns seastar::future<T>, to return an crimson::ct_error, we have to create
    //	a seastar::future<T> holding that crimson::ct_error. This is not necessary
    //	once seastar::future<T>::handle_exception() returns seastar::futurize_t<T>
    [FNAME, device_id, offset, len](auto e) -> read_ertr::future<size_t>
  {
    ERROR("D{} poffset={}~{} got error -- {}",
          device_id, offset, len, e);
    return crimson::ct_error::input_output_error::make();
  }).then([FNAME, device_id, offset, len](auto result) -> read_ertr::future<> {
    if (result != len) {
      ERROR("D{} poffset={}~{} read len={} inconsistent",
            device_id, offset, len, result);
      return crimson::ct_error::input_output_error::make();
    }
    TRACE("D{} poffset={}~{} done", device_id, offset, len);
    return read_ertr::now();
  });
}

write_ertr::future<>
SegmentStateTracker::write_out(
  device_id_t device_id,
  seastar::file &device,
  uint64_t offset)
{
  LOG_PREFIX(SegmentStateTracker::write_out);
  DEBUG("D{} poffset={}~{}", device_id, offset, bptr.length());
  return do_write(device_id, device, offset, bptr);
}

write_ertr::future<>
SegmentStateTracker::read_in(
  device_id_t device_id,
  seastar::file &device,
  uint64_t offset)
{
  LOG_PREFIX(SegmentStateTracker::read_in);
  DEBUG("D{} poffset={}~{}", device_id, offset, bptr.length());
  return do_read(
    device_id,
    device,
    offset,
    bptr.length(),
    bptr);
}

static
block_sm_superblock_t make_superblock(
  device_id_t device_id,
  segment_manager_config_t sm_config,
  const seastar::stat_data &data)
{
  LOG_PREFIX(block_make_superblock);
  using crimson::common::get_conf;

  auto config_size = get_conf<Option::size_t>(
    "seastore_device_size");

  size_t size = (data.size == 0) ? config_size : data.size;

  auto config_segment_size = get_conf<Option::size_t>(
    "seastore_segment_size");
  size_t raw_segments = size / config_segment_size;
  size_t tracker_size = SegmentStateTracker::get_raw_size(
    raw_segments,
    data.block_size);
  size_t tracker_off = data.block_size;
  size_t first_seg_off = tracker_size + tracker_off;
  size_t segments = (size - first_seg_off) / config_segment_size;

  INFO("D{} disk_size={}, segment_size={}, segments={}, block_size={}, "
       "tracker_off={}, first_seg_off={}",
       device_id,
       size,
       config_segment_size,
       segments,
       data.block_size,
       tracker_off,
       first_seg_off);

  return block_sm_superblock_t{
    size,
    config_segment_size,
    data.block_size,
    segments,
    tracker_off,
    first_seg_off,
    sm_config.major_dev,
    sm_config.magic,
    sm_config.dtype,
    sm_config.device_id,
    sm_config.meta,
    std::move(sm_config.secondary_devices)
  };
}

using check_create_device_ertr = BlockSegmentManager::access_ertr;
using check_create_device_ret = check_create_device_ertr::future<>;
static check_create_device_ret check_create_device(
  const std::string &path,
  size_t size)
{
  LOG_PREFIX(block_check_create_device);
  INFO("path={}, size={}", path, size);
  return seastar::open_file_dma(
    path,
    seastar::open_flags::exclusive |
    seastar::open_flags::rw |
    seastar::open_flags::create
  ).then([size, FNAME, &path](auto file) {
    return seastar::do_with(
      file,
      [size, FNAME, &path](auto &f) -> seastar::future<>
    {
      DEBUG("path={} created, truncating to {}", path, size);
      ceph_assert(f);
      return f.truncate(
        size
      ).then([&f, size] {
        return f.allocate(0, size);
      }).finally([&f] {
        return f.close();
      });
    });
  }).then_wrapped([&path, FNAME](auto f) -> check_create_device_ret {
    if (f.failed()) {
      try {
	f.get();
	return seastar::now();
      } catch (const std::system_error &e) {
	if (e.code().value() == EEXIST) {
          ERROR("path={} exists", path);
	  return seastar::now();
	} else {
          ERROR("path={} creation error -- {}", path, e);
	  return crimson::ct_error::input_output_error::make();
	}
      } catch (...) {
        ERROR("path={} creation error", path);
	return crimson::ct_error::input_output_error::make();
      }
    }

    DEBUG("path={} complete", path);
    std::ignore = f.discard_result();
    return seastar::now();
  });
}

using open_device_ret = 
  BlockSegmentManager::access_ertr::future<
  std::pair<seastar::file, seastar::stat_data>
  >;
static
open_device_ret open_device(
  const std::string &path)
{
  LOG_PREFIX(block_open_device);
  return seastar::file_stat(path, seastar::follow_symlink::yes
  ).then([&path, FNAME](auto stat) mutable {
    return seastar::open_file_dma(
      path,
      seastar::open_flags::rw | seastar::open_flags::dsync
    ).then([=, &path](auto file) {
      INFO("path={} successful, size={}", path, stat.size);
      return std::make_pair(file, stat);
    });
  }).handle_exception([FNAME, &path](auto e) -> open_device_ret {
    ERROR("path={} got error -- {}", path, e);
    return crimson::ct_error::input_output_error::make();
  });
}


static
BlockSegmentManager::access_ertr::future<>
write_superblock(
    device_id_t device_id,
    seastar::file &device,
    block_sm_superblock_t sb)
{
  LOG_PREFIX(block_write_superblock);
  DEBUG("D{} write {}", device_id, sb);
  sb.validate();
  assert(ceph::encoded_sizeof<block_sm_superblock_t>(sb) <
	 sb.block_size);
  return seastar::do_with(
    bufferptr(ceph::buffer::create_page_aligned(sb.block_size)),
    [=, &device](auto &bp)
  {
    bufferlist bl;
    encode(sb, bl);
    auto iter = bl.begin();
    assert(bl.length() < sb.block_size);
    iter.copy(bl.length(), bp.c_str());
    return do_write(device_id, device, 0, bp);
  });
}

static
BlockSegmentManager::access_ertr::future<block_sm_superblock_t>
read_superblock(seastar::file &device, seastar::stat_data sd)
{
  LOG_PREFIX(block_read_superblock);
  DEBUG("reading superblock ...");
  return seastar::do_with(
    bufferptr(ceph::buffer::create_page_aligned(sd.block_size)),
    [=, &device](auto &bp)
  {
    return do_read(
      DEVICE_ID_NULL, // unknown
      device,
      0,
      bp.length(),
      bp
    ).safe_then([=, &bp] {
      bufferlist bl;
      bl.push_back(bp);
      block_sm_superblock_t ret;
      auto bliter = bl.cbegin();
      try {
        decode(ret, bliter);
      } catch (...) {
        ERROR("got decode error!");
        ceph_assert(0 == "invalid superblock");
      }
      assert(ceph::encoded_sizeof<block_sm_superblock_t>(ret) <
             sd.block_size);
      return BlockSegmentManager::access_ertr::future<block_sm_superblock_t>(
        BlockSegmentManager::access_ertr::ready_future_marker{},
        ret);
    });
  });
}

BlockSegment::BlockSegment(
  BlockSegmentManager &manager, segment_id_t id)
  : manager(manager), id(id) {}

seastore_off_t BlockSegment::get_write_capacity() const
{
  return manager.get_segment_size();
}

Segment::close_ertr::future<> BlockSegment::close()
{
  return manager.segment_close(id, write_pointer);
}

Segment::write_ertr::future<> BlockSegment::write(
  seastore_off_t offset, ceph::bufferlist bl)
{
  LOG_PREFIX(BlockSegment::write);
  auto paddr = paddr_t::make_seg_paddr(id, offset);
  DEBUG("D{} S{} offset={}~{} poffset={} ...",
    id.device_id(),
    id.device_segment_id(),
    offset,
    bl.length(),
    manager.get_offset(paddr));

  if (offset < write_pointer ||
      offset % manager.superblock.block_size != 0 ||
      bl.length() % manager.superblock.block_size != 0) {
    ERROR("D{} S{} offset={}~{} poffset={} invalid write",
          id.device_id(),
          id.device_segment_id(),
          offset,
          bl.length(),
          manager.get_offset(paddr));
    return crimson::ct_error::invarg::make();
  }

  if (offset + bl.length() > manager.superblock.segment_size) {
    ERROR("D{} S{} offset={}~{} poffset={} write out of the range {}",
          id.device_id(),
          id.device_segment_id(),
          offset,
          bl.length(),
          manager.get_offset(paddr),
          manager.superblock.segment_size);
    return crimson::ct_error::enospc::make();
  }

  write_pointer = offset + bl.length();
  return manager.segment_write(paddr, bl);
}

Segment::close_ertr::future<> BlockSegmentManager::segment_close(
    segment_id_t id, seastore_off_t write_pointer)
{
  LOG_PREFIX(BlockSegmentManager::segment_close);
  auto s_id = id.device_segment_id();
  int unused_bytes = get_segment_size() - write_pointer;
  INFO("D{} S{} unused_bytes={} ...",
       get_device_id(), s_id, unused_bytes);

  assert(unused_bytes >= 0);
  assert(id.device_id() == get_device_id());
  assert(tracker);

  tracker->set(s_id, segment_state_t::CLOSED);
  ++stats.closed_segments;
  stats.closed_segments_unused_bytes += unused_bytes;
  stats.metadata_write.increment(tracker->get_size());
  return tracker->write_out(
      get_device_id(), device, superblock.tracker_offset);
}

Segment::write_ertr::future<> BlockSegmentManager::segment_write(
  paddr_t addr,
  ceph::bufferlist bl,
  bool ignore_check)
{
  assert(addr.get_device_id() == get_device_id());
  assert((bl.length() % superblock.block_size) == 0);
  stats.data_write.increment(bl.length());
  return do_writev(
      get_device_id(),
      device,
      get_offset(addr),
      std::move(bl),
      superblock.block_size);
}

BlockSegmentManager::~BlockSegmentManager()
{
}

BlockSegmentManager::mount_ret BlockSegmentManager::mount()
{
  LOG_PREFIX(BlockSegmentManager::mount);
  return open_device(
    device_path
  ).safe_then([=](auto p) {
    device = std::move(p.first);
    auto sd = p.second;
    return read_superblock(device, sd);
  }).safe_then([=](auto sb) {
    set_device_id(sb.device_id);
    INFO("D{} read {}", get_device_id(), sb);
    sb.validate();
    superblock = sb;
    stats.data_read.increment(
        ceph::encoded_sizeof<block_sm_superblock_t>(superblock));
    tracker = std::make_unique<SegmentStateTracker>(
      superblock.segments,
      superblock.block_size);
    stats.data_read.increment(tracker->get_size());
    return tracker->read_in(
      get_device_id(),
      device,
      superblock.tracker_offset
    ).safe_then([this] {
      for (device_segment_id_t i = 0; i < tracker->get_capacity(); ++i) {
	if (tracker->get(i) == segment_state_t::OPEN) {
	  tracker->set(i, segment_state_t::CLOSED);
	}
      }
      stats.metadata_write.increment(tracker->get_size());
      return tracker->write_out(
          get_device_id(), device, superblock.tracker_offset);
    });
  }).safe_then([this, FNAME] {
    INFO("D{} complete", get_device_id());
    register_metrics();
  });
}

BlockSegmentManager::mkfs_ret BlockSegmentManager::mkfs(
  segment_manager_config_t sm_config)
{
  LOG_PREFIX(BlockSegmentManager::mkfs);
  set_device_id(sm_config.device_id);
  INFO("D{} path={}, {}", get_device_id(), device_path, sm_config);
  return seastar::do_with(
    seastar::file{},
    seastar::stat_data{},
    block_sm_superblock_t{},
    std::unique_ptr<SegmentStateTracker>(),
    [=](auto &device, auto &stat, auto &sb, auto &tracker)
  {
    check_create_device_ret maybe_create = check_create_device_ertr::now();
    using crimson::common::get_conf;
    if (get_conf<bool>("seastore_block_create")) {
      auto size = get_conf<Option::size_t>("seastore_device_size");
      maybe_create = check_create_device(device_path, size);
    }

    return maybe_create.safe_then([this] {
      return open_device(device_path);
    }).safe_then([&, sm_config](auto p) {
      device = p.first;
      stat = p.second;
      sb = make_superblock(get_device_id(), sm_config, stat);
      stats.metadata_write.increment(
          ceph::encoded_sizeof<block_sm_superblock_t>(sb));
      return write_superblock(get_device_id(), device, sb);
    }).safe_then([&, FNAME, this] {
      DEBUG("D{} superblock written", get_device_id());
      tracker.reset(new SegmentStateTracker(sb.segments, sb.block_size));
      stats.metadata_write.increment(tracker->get_size());
      return tracker->write_out(
          get_device_id(), device, sb.tracker_offset);
    }).finally([&] {
      return device.close();
    }).safe_then([FNAME, this] {
      INFO("D{} complete", get_device_id());
      return mkfs_ertr::now();
    });
  });
}

BlockSegmentManager::close_ertr::future<> BlockSegmentManager::close()
{
  LOG_PREFIX(BlockSegmentManager::close);
  INFO("D{}", get_device_id());
  metrics.clear();
  return device.close();
}

SegmentManager::open_ertr::future<SegmentRef> BlockSegmentManager::open(
  segment_id_t id)
{
  LOG_PREFIX(BlockSegmentManager::open);
  auto s_id = id.device_segment_id();
  INFO("D{} S{} ...", get_device_id(), s_id);

  assert(id.device_id() == get_device_id());

  if (s_id >= get_num_segments()) {
    ERROR("D{} S{} segment-id out of range {}",
          get_device_id(), s_id, get_num_segments());
    return crimson::ct_error::invarg::make();
  }

  if (tracker->get(s_id) != segment_state_t::EMPTY) {
    ERROR("D{} S{} invalid state {} != EMPTY",
          get_device_id(), s_id, tracker->get(s_id));
    return crimson::ct_error::invarg::make();
  }

  tracker->set(s_id, segment_state_t::OPEN);
  stats.metadata_write.increment(tracker->get_size());
  return tracker->write_out(
      get_device_id(), device, superblock.tracker_offset
  ).safe_then([this, id, FNAME] {
    ++stats.opened_segments;
    DEBUG("D{} S{} done", get_device_id(), id.device_segment_id());
    return open_ertr::future<SegmentRef>(
      open_ertr::ready_future_marker{},
      SegmentRef(new BlockSegment(*this, id)));
  });
}

SegmentManager::release_ertr::future<> BlockSegmentManager::release(
  segment_id_t id)
{
  LOG_PREFIX(BlockSegmentManager::release);
  auto s_id = id.device_segment_id();
  INFO("D{} S{} ...", get_device_id(), s_id);

  assert(id.device_id() == get_device_id());

  if (s_id >= get_num_segments()) {
    ERROR("D{} S{} segment-id out of range {}",
          get_device_id(), s_id, get_num_segments());
    return crimson::ct_error::invarg::make();
  }

  if (tracker->get(s_id) != segment_state_t::CLOSED) {
    ERROR("D{} S{} invalid state {} != CLOSED",
          get_device_id(), s_id, tracker->get(s_id));
    return crimson::ct_error::invarg::make();
  }

  tracker->set(s_id, segment_state_t::EMPTY);
  ++stats.released_segments;
  stats.metadata_write.increment(tracker->get_size());
  return tracker->write_out(
      get_device_id(), device, superblock.tracker_offset);
}

SegmentManager::read_ertr::future<> BlockSegmentManager::read(
  paddr_t addr,
  size_t len,
  ceph::bufferptr &out)
{
  LOG_PREFIX(BlockSegmentManager::read);
  auto& seg_addr = addr.as_seg_paddr();
  auto s_id = seg_addr.get_segment_id().device_segment_id();
  auto s_off = seg_addr.get_segment_off();
  auto p_off = get_offset(addr);
  DEBUG("D{} S{} offset={}~{} poffset={} ...",
        get_device_id(), s_id, s_off, len, p_off);

  assert(addr.get_device_id() == get_device_id());

  if (s_off % superblock.block_size != 0 ||
      len % superblock.block_size != 0) {
    ERROR("D{} S{} offset={}~{} poffset={} invalid read",
          get_device_id(), s_id, s_off, len, p_off);
    return crimson::ct_error::invarg::make();
  }

  if (s_id >= get_num_segments()) {
    ERROR("D{} S{} offset={}~{} poffset={} segment-id out of range {}",
          get_device_id(), s_id, s_off, len, p_off,
          get_num_segments());
    return crimson::ct_error::invarg::make();
  }

  if (s_off + len > superblock.segment_size) {
    ERROR("D{} S{} offset={}~{} poffset={} read out of range {}",
          get_device_id(), s_id, s_off, len, p_off,
          superblock.segment_size);
    return crimson::ct_error::invarg::make();
  }

  if (tracker->get(s_id) == segment_state_t::EMPTY) {
    // XXX: not an error during scanning,
    // might need refactor to increase the log level
    DEBUG("D{} S{} offset={}~{} poffset={} invalid state {}",
          get_device_id(), s_id, s_off, len, p_off,
          tracker->get(s_id));
    return crimson::ct_error::enoent::make();
  }

  stats.data_read.increment(len);
  return do_read(
    get_device_id(),
    device,
    p_off,
    len,
    out);
}

void BlockSegmentManager::register_metrics()
{
  LOG_PREFIX(BlockSegmentManager::register_metrics);
  DEBUG("D{}", get_device_id());
  namespace sm = seastar::metrics;
  sm::label label("device_id");
  std::vector<sm::label_instance> label_instances;
  label_instances.push_back(label(get_device_id()));
  stats.reset();
  metrics.add_group(
    "segment_manager",
    {
      sm::make_counter(
        "data_read_num",
        stats.data_read.num,
        sm::description("total number of data read"),
	label_instances
      ),
      sm::make_counter(
        "data_read_bytes",
        stats.data_read.bytes,
        sm::description("total bytes of data read"),
	label_instances
      ),
      sm::make_counter(
        "data_write_num",
        stats.data_write.num,
        sm::description("total number of data write"),
	label_instances
      ),
      sm::make_counter(
        "data_write_bytes",
        stats.data_write.bytes,
        sm::description("total bytes of data write"),
	label_instances
      ),
      sm::make_counter(
        "metadata_write_num",
        stats.metadata_write.num,
        sm::description("total number of metadata write"),
	label_instances
      ),
      sm::make_counter(
        "metadata_write_bytes",
        stats.metadata_write.bytes,
        sm::description("total bytes of metadata write"),
	label_instances
      ),
      sm::make_counter(
        "opened_segments",
        stats.opened_segments,
        sm::description("total segments opened"),
	label_instances
      ),
      sm::make_counter(
        "closed_segments",
        stats.closed_segments,
        sm::description("total segments closed"),
	label_instances
      ),
      sm::make_counter(
        "closed_segments_unused_bytes",
        stats.closed_segments_unused_bytes,
        sm::description("total unused bytes of closed segments"),
	label_instances
      ),
      sm::make_counter(
        "released_segments",
        stats.released_segments,
        sm::description("total segments released"),
	label_instances
      ),
    }
  );
}

}
