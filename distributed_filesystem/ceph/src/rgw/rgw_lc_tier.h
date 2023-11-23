// -*- mode:C++; tab-width:8; c-basic-offset:2; indent-tabs-mode:t -*-
// vim: ts=8 sw=2 smarttab ft=cpp

#ifndef CEPH_RGW_LC_TIER_H
#define CEPH_RGW_LC_TIER_H

#include "rgw_lc.h"
#include "rgw_rest_conn.h"
#include "rgw_rados.h"
#include "rgw_zone.h"
#include "rgw_sal_rados.h"
#include "rgw_cr_rest.h"

#define DEFAULT_MULTIPART_SYNC_PART_SIZE (32 * 1024 * 1024)
#define MULTIPART_MIN_POSSIBLE_PART_SIZE (5 * 1024 * 1024)

struct RGWLCCloudTierCtx {
  CephContext *cct;
  const DoutPrefixProvider *dpp;

  /* Source */
  rgw_bucket_dir_entry& o;
  rgw::sal::Store *store;
  RGWBucketInfo& bucket_info;
  std::string storage_class;

  rgw::sal::Object *obj;
  RGWObjectCtx& rctx;

  /* Remote */
  RGWRESTConn& conn;
  std::string target_bucket_name;
  std::string target_storage_class;

  std::map<std::string, RGWTierACLMapping> acl_mappings;
  uint64_t multipart_min_part_size;
  uint64_t multipart_sync_threshold;

  bool is_multipart_upload{false};
  bool target_bucket_created{true};

  RGWLCCloudTierCtx(CephContext* _cct, const DoutPrefixProvider *_dpp,
      rgw_bucket_dir_entry& _o, rgw::sal::Store *_store,
      RGWBucketInfo &_binfo, rgw::sal::Object *_obj,
      RGWObjectCtx& _rctx, RGWRESTConn& _conn, std::string& _bucket,
      std::string& _storage_class) :
    cct(_cct), dpp(_dpp), o(_o), store(_store), bucket_info(_binfo),
    obj(_obj), rctx(_rctx), conn(_conn), target_bucket_name(_bucket),
    target_storage_class(_storage_class) {}
};

/* Transition object to cloud endpoint */
int rgw_cloud_tier_transfer_object(RGWLCCloudTierCtx& tier_ctx);

#endif
