// -*- mode:C++; tab-width:8; c-basic-offset:2; indent-tabs-mode:t -*-
// vim: ts=8 sw=2 smarttab

#include "crimson/os/seastore/seastore_types.h"
#include "crimson/common/log.h"

namespace {

seastar::logger& journal_logger() {
  return crimson::get_logger(ceph_subsys_seastore_journal);
}

}

namespace crimson::os::seastore {

bool is_aligned(uint64_t offset, uint64_t alignment)
{
  return (offset % alignment) == 0;
}

std::ostream& operator<<(std::ostream& out, const seastore_meta_t& meta)
{
  return out << meta.seastore_id;
}

std::ostream &segment_to_stream(std::ostream &out, const segment_id_t &t)
{
  if (t == NULL_SEG_ID)
    return out << "NULL_SEG";
  else if (t == FAKE_SEG_ID)
    return out << "FAKE_SEG";
  else
    return out << t;
}

std::ostream &offset_to_stream(std::ostream &out, const seastore_off_t &t)
{
  if (t == NULL_SEG_OFF)
    return out << "NULL_OFF";
  else
    return out << t;
}

std::ostream& operator<<(std::ostream& out, segment_type_t t)
{
  switch(t) {
  case segment_type_t::JOURNAL:
    return out << "JOURNAL";
  case segment_type_t::OOL:
    return out << "OOL";
  case segment_type_t::NULL_SEG:
    return out << "NULL_SEG";
  default:
    return out << "INVALID_SEGMENT_TYPE!";
  }
}

segment_type_t segment_seq_to_type(segment_seq_t seq)
{
  if (seq <= MAX_VALID_SEG_SEQ) {
    return segment_type_t::JOURNAL;
  } else if (seq == OOL_SEG_SEQ) {
    return segment_type_t::OOL;
  } else {
    assert(seq == NULL_SEG_SEQ);
    return segment_type_t::NULL_SEG;
  }
}

std::ostream& operator<<(std::ostream& out, segment_seq_printer_t seq)
{
  auto type = segment_seq_to_type(seq.seq);
  switch(type) {
  case segment_type_t::JOURNAL:
    return out << seq.seq;
  default:
    return out << type;
  }
}

std::ostream &operator<<(std::ostream &out, const segment_id_t& segment)
{
  return out << "[" << (uint64_t)segment.device_id() << ","
    << segment.device_segment_id() << "]";
}

std::ostream &block_offset_to_stream(std::ostream &out, const block_off_t &t)
{
  return out << t;
}

std::ostream &operator<<(std::ostream &out, const paddr_t &rhs)
{
  out << "paddr_t<";
  if (rhs == P_ADDR_NULL) {
    out << "NULL_PADDR";
  } else if (rhs == P_ADDR_MIN) {
    out << "MIN_PADDR";
  } else if (rhs.is_block_relative()) {
    out << "BLOCK_REG";
  } else if (rhs.is_record_relative()) {
    out << "RECORD_REG";
  } else if (rhs.is_delayed()) {
    out << "DELAYED_TEMP";
  } else if (rhs.get_addr_type() == addr_types_t::SEGMENT) {
    const seg_paddr_t& s = rhs.as_seg_paddr();
    segment_to_stream(out, s.get_segment_id());
    out << ", ";
    offset_to_stream(out, s.get_segment_off());
  } else if (rhs.get_addr_type() == addr_types_t::RANDOM_BLOCK) {
    const blk_paddr_t& s = rhs.as_blk_paddr();
    block_offset_to_stream(out, s.get_block_off());
  } else {
    out << "INVALID";
  }
  return out << ">";
}

std::ostream &operator<<(std::ostream &out, const journal_seq_t &seq)
{
  return out << "journal_seq_t("
             << "segment_seq=" << segment_seq_printer_t{seq.segment_seq}
             << ", offset=" << seq.offset
             << ")";
}

std::ostream &operator<<(std::ostream &out, extent_types_t t)
{
  switch (t) {
  case extent_types_t::ROOT:
    return out << "ROOT";
  case extent_types_t::LADDR_INTERNAL:
    return out << "LADDR_INTERNAL";
  case extent_types_t::LADDR_LEAF:
    return out << "LADDR_LEAF";
  case extent_types_t::ONODE_BLOCK_STAGED:
    return out << "ONODE_BLOCK_STAGED";
  case extent_types_t::OMAP_INNER:
    return out << "OMAP_INNER";
  case extent_types_t::OMAP_LEAF:
    return out << "OMAP_LEAF";
  case extent_types_t::COLL_BLOCK:
    return out << "COLL_BLOCK";
  case extent_types_t::OBJECT_DATA_BLOCK:
    return out << "OBJECT_DATA_BLOCK";
  case extent_types_t::RETIRED_PLACEHOLDER:
    return out << "RETIRED_PLACEHOLDER";
  case extent_types_t::TEST_BLOCK:
    return out << "TEST_BLOCK";
  case extent_types_t::TEST_BLOCK_PHYSICAL:
    return out << "TEST_BLOCK_PHYSICAL";
  case extent_types_t::NONE:
    return out << "NONE";
  default:
    return out << "UNKNOWN";
  }
}

std::ostream &operator<<(std::ostream &out, const laddr_list_t &rhs)
{
  bool first = false;
  for (auto &i: rhs) {
    out << (first ? '[' : ',') << '(' << i.first << ',' << i.second << ')';
    first = true;
  }
  return out << ']';
}
std::ostream &operator<<(std::ostream &out, const paddr_list_t &rhs)
{
  bool first = false;
  for (auto &i: rhs) {
    out << (first ? '[' : ',') << '(' << i.first << ',' << i.second << ')';
    first = true;
  }
  return out << ']';
}

std::ostream &operator<<(std::ostream &lhs, const delta_info_t &rhs)
{
  return lhs << "delta_info_t("
	     << "type: " << rhs.type
	     << ", paddr: " << rhs.paddr
	     << ", laddr: " << rhs.laddr
	     << ", prev_crc: " << rhs.prev_crc
	     << ", final_crc: " << rhs.final_crc
	     << ", length: " << rhs.length
	     << ", pversion: " << rhs.pversion
	     << ")";
}

std::ostream &operator<<(std::ostream &out, const extent_info_t &info)
{
  return out << "extent_info_t("
	     << "type: " << info.type
	     << ", addr: " << info.addr
	     << ", len: " << info.len
	     << ")";
}

std::ostream &operator<<(std::ostream &out, const segment_header_t &header)
{
  return out << "segment_header_t("
	     << "segment_seq=" << segment_seq_printer_t{header.journal_segment_seq}
	     << ", segment_id=" << header.physical_segment_id
	     << ", journal_tail=" << header.journal_tail
	     << ", segment_nonce=" << header.segment_nonce
	     << ")";
}

extent_len_t record_size_t::get_raw_mdlength() const
{
  // empty record is allowed to submit
  return plain_mdlength +
         ceph::encoded_sizeof_bounded<record_header_t>();
}

void record_size_t::account_extent(extent_len_t extent_len)
{
  assert(extent_len);
  plain_mdlength += ceph::encoded_sizeof_bounded<extent_info_t>();
  dlength += extent_len;
}

void record_size_t::account(const delta_info_t& delta)
{
  assert(delta.bl.length());
  plain_mdlength += ceph::encoded_sizeof(delta);
}

std::ostream &operator<<(std::ostream& out, const record_size_t& rsize)
{
  return out << "record_size_t("
             << "raw_md=" << rsize.get_raw_mdlength()
             << ", data=" << rsize.dlength
             << ")";
}

std::ostream &operator<<(std::ostream& out, const record_t& r)
{
  return out << "record_t("
             << "num_extents=" << r.extents.size()
             << ", num_deltas=" << r.deltas.size()
             << ")";
}

std::ostream& operator<<(std::ostream& out, const record_group_header_t& h)
{
  return out << "record_group_header_t("
             << "num_records=" << h.records
             << ", mdlength=" << h.mdlength
             << ", dlength=" << h.dlength
             << ", nonce=" << h.segment_nonce
             << ", committed_to=" << h.committed_to
             << ", data_crc=" << h.data_crc
             << ")";
}

extent_len_t record_group_size_t::get_raw_mdlength() const
{
  return plain_mdlength +
         sizeof(checksum_t) +
         ceph::encoded_sizeof_bounded<record_group_header_t>();
}

void record_group_size_t::account(
    const record_size_t& rsize,
    extent_len_t _block_size)
{
  // empty record is allowed to submit
  assert(_block_size > 0);
  assert(rsize.dlength % _block_size == 0);
  assert(block_size == 0 || block_size == _block_size);
  plain_mdlength += rsize.get_raw_mdlength();
  dlength += rsize.dlength;
  block_size = _block_size;
}

std::ostream& operator<<(std::ostream& out, const record_group_size_t& size)
{
  return out << "record_group_size_t("
             << "raw_md=" << size.get_raw_mdlength()
             << ", data=" << size.dlength
             << ", block_size=" << size.block_size
             << ", fullness=" << size.get_fullness()
             << ")";
}

std::ostream& operator<<(std::ostream& out, const record_group_t& rg)
{
  return out << "record_group_t("
             << "num_records=" << rg.records.size()
             << ", " << rg.size
             << ")";
}

ceph::bufferlist encode_record(
  record_t&& record,
  extent_len_t block_size,
  const journal_seq_t& committed_to,
  segment_nonce_t current_segment_nonce)
{
  record_group_t record_group(std::move(record), block_size);
  return encode_records(
      record_group,
      committed_to,
      current_segment_nonce);
}

ceph::bufferlist encode_records(
  record_group_t& record_group,
  const journal_seq_t& committed_to,
  segment_nonce_t current_segment_nonce)
{
  assert(record_group.size.block_size > 0);
  assert(record_group.records.size() > 0);

  bufferlist data_bl;
  for (auto& r: record_group.records) {
    for (auto& i: r.extents) {
      assert(i.bl.length());
      data_bl.append(i.bl);
    }
  }

  bufferlist bl;
  record_group_header_t header{
    static_cast<extent_len_t>(record_group.records.size()),
    record_group.size.get_mdlength(),
    record_group.size.dlength,
    current_segment_nonce,
    committed_to,
    data_bl.crc32c(-1)
  };
  encode(header, bl);

  auto metadata_crc_filler = bl.append_hole(sizeof(checksum_t));

  for (auto& r: record_group.records) {
    record_header_t rheader{
      (extent_len_t)r.deltas.size(),
      (extent_len_t)r.extents.size(),
    };
    encode(rheader, bl);
  }
  for (auto& r: record_group.records) {
    for (const auto& i: r.extents) {
      encode(extent_info_t(i), bl);
    }
  }
  for (auto& r: record_group.records) {
    for (const auto& i: r.deltas) {
      encode(i, bl);
    }
  }
  ceph_assert(bl.length() == record_group.size.get_raw_mdlength());

  auto aligned_mdlength = record_group.size.get_mdlength();
  if (bl.length() != aligned_mdlength) {
    assert(bl.length() < aligned_mdlength);
    bl.append_zero(aligned_mdlength - bl.length());
  }

  auto bliter = bl.cbegin();
  auto metadata_crc = bliter.crc32c(
    ceph::encoded_sizeof_bounded<record_group_header_t>(),
    -1);
  bliter += sizeof(checksum_t); /* metadata crc hole */
  metadata_crc = bliter.crc32c(
    bliter.get_remaining(),
    metadata_crc);
  ceph_le32 metadata_crc_le;
  metadata_crc_le = metadata_crc;
  metadata_crc_filler.copy_in(
    sizeof(checksum_t),
    reinterpret_cast<const char *>(&metadata_crc_le));

  bl.claim_append(data_bl);
  ceph_assert(bl.length() == record_group.size.get_encoded_length());

  record_group.clear();
  return bl;
}

std::optional<record_group_header_t>
try_decode_records_header(
    const ceph::bufferlist& header_bl,
    segment_nonce_t expected_nonce)
{
  auto bp = header_bl.cbegin();
  record_group_header_t header;
  try {
    decode(header, bp);
  } catch (ceph::buffer::error &e) {
    journal_logger().debug(
        "try_decode_records_header: failed, "
        "cannot decode record_group_header_t, got {}.",
        e);
    return std::nullopt;
  }
  if (header.segment_nonce != expected_nonce) {
    journal_logger().debug(
        "try_decode_records_header: failed, record_group_header nonce mismatch, "
        "read {}, expected {}!",
        header.segment_nonce,
        expected_nonce);
    return std::nullopt;
  }
  return header;
}

bool validate_records_metadata(
    const ceph::bufferlist& md_bl)
{
  auto bliter = md_bl.cbegin();
  auto test_crc = bliter.crc32c(
    ceph::encoded_sizeof_bounded<record_group_header_t>(),
    -1);
  ceph_le32 recorded_crc_le;
  decode(recorded_crc_le, bliter);
  uint32_t recorded_crc = recorded_crc_le;
  test_crc = bliter.crc32c(
    bliter.get_remaining(),
    test_crc);
  bool success = (test_crc == recorded_crc);
  if (!success) {
    journal_logger().debug(
        "validate_records_metadata: failed, metadata crc mismatch.");
  }
  return success;
}

bool validate_records_data(
    const record_group_header_t& header,
    const ceph::bufferlist& data_bl)
{
  bool success = (data_bl.crc32c(-1) == header.data_crc);
  if (!success) {
    journal_logger().debug(
        "validate_records_data: failed, data crc mismatch!");
  }
  return success;
}

namespace {

std::optional<std::vector<record_header_t>>
try_decode_record_headers(
    const record_group_header_t& header,
    const ceph::bufferlist& md_bl)
{
  auto bliter = md_bl.cbegin();
  bliter += ceph::encoded_sizeof_bounded<record_group_header_t>();
  bliter += sizeof(checksum_t); /* metadata crc hole */
  std::vector<record_header_t> record_headers(header.records);
  for (auto &&i: record_headers) {
    try {
      decode(i, bliter);
    } catch (ceph::buffer::error &e) {
      journal_logger().debug(
          "try_decode_record_headers: failed, "
          "cannot decode record_header_t, got {}.",
          e);
      return std::nullopt;
    }
  }
  return record_headers;
}

}

std::optional<std::vector<record_extent_infos_t> >
try_decode_extent_infos(
    const record_group_header_t& header,
    const ceph::bufferlist& md_bl)
{
  auto maybe_headers = try_decode_record_headers(header, md_bl);
  if (!maybe_headers) {
    return std::nullopt;
  }

  auto bliter = md_bl.cbegin();
  bliter += ceph::encoded_sizeof_bounded<record_group_header_t>();
  bliter += sizeof(checksum_t); /* metadata crc hole */
  bliter += (ceph::encoded_sizeof_bounded<record_header_t>() *
             maybe_headers->size());

  std::vector<record_extent_infos_t> record_extent_infos(
      maybe_headers->size());
  auto result_iter = record_extent_infos.begin();
  for (auto& h: *maybe_headers) {
    result_iter->header = h;
    result_iter->extent_infos.resize(h.extents);
    for (auto& i: result_iter->extent_infos) {
      try {
        decode(i, bliter);
      } catch (ceph::buffer::error &e) {
        journal_logger().debug(
            "try_decode_extent_infos: failed, "
            "cannot decode extent_info_t, got {}.",
            e);
        return std::nullopt;
      }
    }
    ++result_iter;
  }
  return record_extent_infos;
}

std::optional<std::vector<record_deltas_t> >
try_decode_deltas(
    const record_group_header_t& header,
    const ceph::bufferlist& md_bl,
    paddr_t record_block_base)
{
  auto maybe_record_extent_infos = try_decode_extent_infos(header, md_bl);
  if (!maybe_record_extent_infos) {
    return std::nullopt;
  }

  auto bliter = md_bl.cbegin();
  bliter += ceph::encoded_sizeof_bounded<record_group_header_t>();
  bliter += sizeof(checksum_t); /* metadata crc hole */
  bliter += (ceph::encoded_sizeof_bounded<record_header_t>() *
             maybe_record_extent_infos->size());
  for (auto& r: *maybe_record_extent_infos) {
    bliter += (ceph::encoded_sizeof_bounded<extent_info_t>() *
               r.extent_infos.size());
  }

  std::vector<record_deltas_t> record_deltas(
      maybe_record_extent_infos->size());
  auto result_iter = record_deltas.begin();
  for (auto& r: *maybe_record_extent_infos) {
    result_iter->record_block_base = record_block_base;
    result_iter->deltas.resize(r.header.deltas);
    for (auto& i: result_iter->deltas) {
      try {
        decode(i, bliter);
      } catch (ceph::buffer::error &e) {
        journal_logger().debug(
            "try_decode_deltas: failed, "
            "cannot decode delta_info_t, got {}.",
            e);
        return std::nullopt;
      }
    }
    for (auto& i: r.extent_infos) {
      auto& seg_addr = record_block_base.as_seg_paddr();
      seg_addr.set_segment_off(seg_addr.get_segment_off() + i.len);
    }
    ++result_iter;
  }
  return record_deltas;
}

std::ostream& operator<<(std::ostream& out, placement_hint_t h)
{
  switch (h) {
  case placement_hint_t::HOT:
    return out << "HOT";
  case placement_hint_t::COLD:
    return out << "COLD";
  case placement_hint_t::REWRITE:
    return out << "REWRITE";
  default:
    return out << "INVALID_PLACEMENT_HINT_TYPE!";
  }
}

bool can_delay_allocation(device_type_t type) {
  // Some types of device may not support delayed allocation, for example PMEM.
  return type <= device_type_t::RANDOM_BLOCK;
}

device_type_t string_to_device_type(std::string type) {
  if (type == "segmented") {
    return device_type_t::SEGMENTED;
  }
  if (type == "random_block") {
    return device_type_t::RANDOM_BLOCK;
  }
  if (type == "pmem") {
    return device_type_t::PMEM;
  }
  return device_type_t::NONE;
}

std::ostream& operator<<(std::ostream& out, device_type_t t)
{
  switch (t) {
  case device_type_t::NONE:
    return out << "NONE";
  case device_type_t::SEGMENTED:
    return out << "SEGMENTED";
  case device_type_t::RANDOM_BLOCK:
    return out << "RANDOM_BLOCK";
  case device_type_t::PMEM:
    return out << "PMEM";
  default:
    return out << "INVALID_DEVICE_TYPE!";
  }
}

std::ostream& operator<<(std::ostream& out, const write_result_t& w)
{
  return out << "write_result_t("
             << "start=" << w.start_seq
             << ", length=" << w.length
             << ")";
}

std::ostream& operator<<(std::ostream& out, const record_locator_t& l)
{
  return out << "record_locator_t("
             << "block_base=" << l.record_block_base
             << ", " << l.write_result
             << ")";
}

void scan_valid_records_cursor::emplace_record_group(
    const record_group_header_t& header, ceph::bufferlist&& md_bl)
{
  auto new_committed_to = header.committed_to;
  ceph_assert(last_committed == journal_seq_t() ||
              last_committed <= new_committed_to);
  last_committed = new_committed_to;
  pending_record_groups.emplace_back(
    seq.offset,
    header,
    std::move(md_bl));
  increment_seq(header.dlength + header.mdlength);
  ceph_assert(new_committed_to == journal_seq_t() ||
              new_committed_to < seq);
}

std::ostream& operator<<(std::ostream& out, const scan_valid_records_cursor& c)
{
  return out << "cursor(last_valid_header_found=" << c.last_valid_header_found
             << ", seq=" << c.seq
             << ", last_committed=" << c.last_committed
             << ", pending_record_groups=" << c.pending_record_groups.size()
             << ", num_consumed_records=" << c.num_consumed_records
             << ")";
}

}
