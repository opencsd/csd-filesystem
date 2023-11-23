// -*- mode:C++; tab-width:8; c-basic-offset:2; indent-tabs-mode:t -*-
// vim: ts=8 sw=2 smarttab ft=cpp

#ifndef CEPH_RGW_CR_TOOLS_H
#define CEPH_RGW_CR_TOOLS_H

#include "rgw_cr_rados.h"
#include "rgw_tools.h"
#include "rgw_lc.h"

#include "services/svc_bucket_sync.h"

struct rgw_user_create_params {
  rgw_user user;
  std::string display_name;
  std::string email;
  std::string access_key;
  std::string secret_key;
  std::string key_type; /* "swift" or "s3" */
  std::string caps;

  bool generate_key{true};
  bool suspended{false};
  std::optional<int32_t> max_buckets;
  bool system{false};
  bool exclusive{false};
  bool apply_quota{true};
};

using RGWUserCreateCR = RGWSimpleWriteOnlyAsyncCR<rgw_user_create_params>;

struct rgw_get_user_info_params {
  rgw_user user;
};

using RGWGetUserInfoCR = RGWSimpleAsyncCR<rgw_get_user_info_params, RGWUserInfo>;

struct rgw_get_bucket_info_params {
  std::string tenant;
  std::string bucket_name;
};

struct rgw_get_bucket_info_result {
  std::unique_ptr<rgw::sal::Bucket> bucket;
};

using RGWGetBucketInfoCR = RGWSimpleAsyncCR<rgw_get_bucket_info_params, rgw_get_bucket_info_result>;

struct rgw_bucket_create_local_params {
  std::shared_ptr<RGWUserInfo> user_info;
  std::string bucket_name;
  rgw_placement_rule placement_rule;
};

using RGWBucketCreateLocalCR = RGWSimpleWriteOnlyAsyncCR<rgw_bucket_create_local_params>;

struct rgw_object_simple_put_params {
  RGWDataAccess::BucketRef bucket;
  rgw_obj_key key;
  bufferlist data;
  std::map<std::string, bufferlist> attrs;
  std::optional<std::string> user_data;
};

using RGWObjectSimplePutCR = RGWSimpleWriteOnlyAsyncCR<rgw_object_simple_put_params>;


struct rgw_bucket_lifecycle_config_params {
  rgw::sal::Bucket* bucket;
  rgw::sal::Attrs bucket_attrs;
  RGWLifecycleConfiguration config;
};

using RGWBucketLifecycleConfigCR = RGWSimpleWriteOnlyAsyncCR<rgw_bucket_lifecycle_config_params>;

struct rgw_bucket_get_sync_policy_params {
  std::optional<rgw_zone_id> zone;
  std::optional<rgw_bucket> bucket;
};

struct rgw_bucket_get_sync_policy_result {
  RGWBucketSyncPolicyHandlerRef policy_handler;
};

using RGWBucketGetSyncPolicyHandlerCR = RGWSimpleAsyncCR<rgw_bucket_get_sync_policy_params, rgw_bucket_get_sync_policy_result>;

#endif
