#pragma once

#include "messages/MOSDOp.h"
#include "osd/osd_types.h"
#include "crimson/common/type_helpers.h"

// The fields in this struct are parameters that may be needed in multiple
// level of processing. I inclosed all those parameters in this struct to
// avoid passing each of them as a method parameter.
struct osd_op_params_t {
  osd_reqid_t req_id;
  utime_t mtime;
  eversion_t at_version;
  eversion_t pg_trim_to;
  eversion_t min_last_complete_ondisk;
  eversion_t last_complete;
  version_t user_at_version = 0;
  bool user_modify = false;
  ObjectCleanRegions clean_regions;

  osd_op_params_t() = default;
};
