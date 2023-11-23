// -*- mode:C++; tab-width:8; c-basic-offset:2; indent-tabs-mode:t -*-
// vim: ts=8 sw=2 smarttab ft=cpp

#include <string.h>

#include <iostream>
#include <map>

#include "include/types.h"

#include "common/Formatter.h"

#include "rgw_acl.h"
#include "rgw_acl_s3.h"
#include "rgw_user.h"

#define dout_subsys ceph_subsys_rgw

using namespace std;

bool operator==(const ACLPermission& lhs, const ACLPermission& rhs) {
  return lhs.flags == rhs.flags;
}
bool operator!=(const ACLPermission& lhs, const ACLPermission& rhs) {
  return !(lhs == rhs);
}

bool operator==(const ACLGranteeType& lhs, const ACLGranteeType& rhs) {
  return lhs.type == rhs.type;
}
bool operator!=(const ACLGranteeType& lhs, const ACLGranteeType& rhs) {
  return lhs.type != rhs.type;
}

bool operator==(const ACLGrant& lhs, const ACLGrant& rhs) {
  return lhs.type == rhs.type && lhs.id == rhs.id
      && lhs.email == rhs.email && lhs.permission == rhs.permission
      && lhs.name == rhs.name && lhs.group == rhs.group
      && lhs.url_spec == rhs.url_spec;
}
bool operator!=(const ACLGrant& lhs, const ACLGrant& rhs) {
  return !(lhs == rhs);
}

bool operator==(const ACLReferer& lhs, const ACLReferer& rhs) {
  return lhs.url_spec == rhs.url_spec && lhs.perm == rhs.perm;
}
bool operator!=(const ACLReferer& lhs, const ACLReferer& rhs) {
  return !(lhs == rhs);
}

bool operator==(const RGWAccessControlList& lhs,
                const RGWAccessControlList& rhs) {
  return lhs.acl_user_map == rhs.acl_user_map
      && lhs.acl_group_map == rhs.acl_group_map
      && lhs.referer_list == rhs.referer_list
      && lhs.grant_map == rhs.grant_map;
}
bool operator!=(const RGWAccessControlList& lhs,
                const RGWAccessControlList& rhs) {
  return !(lhs == rhs);
}

bool operator==(const ACLOwner& lhs, const ACLOwner& rhs) {
  return lhs.id == rhs.id && lhs.display_name == rhs.display_name;
}
bool operator!=(const ACLOwner& lhs, const ACLOwner& rhs) {
  return !(lhs == rhs);
}

bool operator==(const RGWAccessControlPolicy& lhs,
                const RGWAccessControlPolicy& rhs) {
  return lhs.acl == rhs.acl && lhs.owner == rhs.owner;
}
bool operator!=(const RGWAccessControlPolicy& lhs,
                const RGWAccessControlPolicy& rhs) {
  return !(lhs == rhs);
}

void RGWAccessControlList::_add_grant(ACLGrant *grant)
{
  ACLPermission& perm = grant->get_permission();
  ACLGranteeType& type = grant->get_type();
  switch (type.get_type()) {
  case ACL_TYPE_REFERER:
    referer_list.emplace_back(grant->get_referer(), perm.get_permissions());

    /* We're specially handling the Swift's .r:* as the S3 API has a similar
     * concept and thus we can have a small portion of compatibility here. */
     if (grant->get_referer() == RGW_REFERER_WILDCARD) {
       acl_group_map[ACL_GROUP_ALL_USERS] |= perm.get_permissions();
     }
    break;
  case ACL_TYPE_GROUP:
    acl_group_map[grant->get_group()] |= perm.get_permissions();
    break;
  default:
    {
      rgw_user id;
      if (!grant->get_id(id)) {
        ldout(cct, 0) << "ERROR: grant->get_id() failed" << dendl;
      }
      acl_user_map[id.to_str()] |= perm.get_permissions();
    }
  }
}

void RGWAccessControlList::add_grant(ACLGrant *grant)
{
  rgw_user id;
  grant->get_id(id); // not that this will return false for groups, but that's ok, we won't search groups
  grant_map.insert(pair<string, ACLGrant>(id.to_str(), *grant));
  _add_grant(grant);
}

void RGWAccessControlList::remove_canon_user_grant(rgw_user& user_id)
{
  auto multi_map_iter = grant_map.find(user_id.to_str());
  if(multi_map_iter != grant_map.end()) {
    auto grants = grant_map.equal_range(user_id.to_str());
    grant_map.erase(grants.first, grants.second);
  }

  auto map_iter = acl_user_map.find(user_id.to_str());
  if (map_iter != acl_user_map.end()){
    acl_user_map.erase(map_iter);
  }
}

uint32_t RGWAccessControlList::get_perm(const DoutPrefixProvider* dpp, 
                                        const rgw::auth::Identity& auth_identity,
                                        const uint32_t perm_mask)
{
  ldpp_dout(dpp, 5) << "Searching permissions for identity=" << auth_identity
                << " mask=" << perm_mask << dendl;

  return perm_mask & auth_identity.get_perms_from_aclspec(dpp, acl_user_map);
}

uint32_t RGWAccessControlList::get_group_perm(const DoutPrefixProvider *dpp, 
                                              ACLGroupTypeEnum group,
                                              const uint32_t perm_mask) const
{
  ldpp_dout(dpp, 5) << "Searching permissions for group=" << (int)group
                << " mask=" << perm_mask << dendl;

  const auto iter = acl_group_map.find((uint32_t)group);
  if (iter != acl_group_map.end()) {
    ldpp_dout(dpp, 5) << "Found permission: " << iter->second << dendl;
    return iter->second & perm_mask;
  }
  ldpp_dout(dpp, 5) << "Permissions for group not found" << dendl;
  return 0;
}

uint32_t RGWAccessControlList::get_referer_perm(const DoutPrefixProvider *dpp,
                                                const uint32_t current_perm,
                                                const std::string http_referer,
                                                const uint32_t perm_mask)
{
  ldpp_dout(dpp, 5) << "Searching permissions for referer=" << http_referer
                << " mask=" << perm_mask << dendl;

  /* This function is basically a transformation from current perm to
   * a new one that takes into consideration the Swift's HTTP referer-
   * based ACLs. We need to go through all items to respect negative
   * grants. */
  uint32_t referer_perm = current_perm;
  for (const auto& r : referer_list) {
    if (r.is_match(http_referer)) {
       referer_perm = r.perm;
    }
  }

  ldpp_dout(dpp, 5) << "Found referer permission=" << referer_perm << dendl;
  return referer_perm & perm_mask;
}

uint32_t RGWAccessControlPolicy::get_perm(const DoutPrefixProvider* dpp,
                                          const rgw::auth::Identity& auth_identity,
                                          const uint32_t perm_mask,
                                          const char * const http_referer,
                                          bool ignore_public_acls)
{
  ldpp_dout(dpp, 20) << "-- Getting permissions begin with perm_mask=" << perm_mask
                 << dendl;

  uint32_t perm = acl.get_perm(dpp, auth_identity, perm_mask);

  if (auth_identity.is_owner_of(owner.get_id())) {
    perm |= perm_mask & (RGW_PERM_READ_ACP | RGW_PERM_WRITE_ACP);
  }

  if (perm == perm_mask) {
    return perm;
  }

  /* should we continue looking up? */
  if (!ignore_public_acls && ((perm & perm_mask) != perm_mask)) {
    perm |= acl.get_group_perm(dpp, ACL_GROUP_ALL_USERS, perm_mask);

    if (false == auth_identity.is_owner_of(rgw_user(RGW_USER_ANON_ID))) {
      /* this is not the anonymous user */
      perm |= acl.get_group_perm(dpp, ACL_GROUP_AUTHENTICATED_USERS, perm_mask);
    }
  }

  /* Should we continue looking up even deeper? */
  if (nullptr != http_referer && (perm & perm_mask) != perm_mask) {
    perm = acl.get_referer_perm(dpp, perm, http_referer, perm_mask);
  }

  ldpp_dout(dpp, 5) << "-- Getting permissions done for identity=" << auth_identity
                << ", owner=" << owner.get_id()
                << ", perm=" << perm << dendl;

  return perm;
}

bool RGWAccessControlPolicy::verify_permission(const DoutPrefixProvider* dpp,
                                               const rgw::auth::Identity& auth_identity,
                                               const uint32_t user_perm_mask,
                                               const uint32_t perm,
                                               const char * const http_referer,
                                               bool ignore_public_acls)
{
  uint32_t test_perm = perm | RGW_PERM_READ_OBJS | RGW_PERM_WRITE_OBJS;

  uint32_t policy_perm = get_perm(dpp, auth_identity, test_perm, http_referer, ignore_public_acls);

  /* the swift WRITE_OBJS perm is equivalent to the WRITE obj, just
     convert those bits. Note that these bits will only be set on
     buckets, so the swift READ permission on bucket will allow listing
     the bucket content */
  if (policy_perm & RGW_PERM_WRITE_OBJS) {
    policy_perm |= (RGW_PERM_WRITE | RGW_PERM_WRITE_ACP);
  }
  if (policy_perm & RGW_PERM_READ_OBJS) {
    policy_perm |= (RGW_PERM_READ | RGW_PERM_READ_ACP);
  }
   
  uint32_t acl_perm = policy_perm & perm & user_perm_mask;

  ldpp_dout(dpp, 10) << " identity=" << auth_identity
                 << " requested perm (type)=" << perm
                 << ", policy perm=" << policy_perm
                 << ", user_perm_mask=" << user_perm_mask
                 << ", acl perm=" << acl_perm << dendl;

  return (perm == acl_perm);
}


bool RGWAccessControlPolicy::is_public(const DoutPrefixProvider *dpp) const
{

  static constexpr auto public_groups = {ACL_GROUP_ALL_USERS,
					 ACL_GROUP_AUTHENTICATED_USERS};
  return std::any_of(public_groups.begin(), public_groups.end(),
                         [&, dpp](ACLGroupTypeEnum g) {
                           auto p = acl.get_group_perm(dpp, g, RGW_PERM_FULL_CONTROL);
                           return (p != RGW_PERM_NONE) && (p != RGW_PERM_INVALID);
                         }
                         );

}

void ACLPermission::generate_test_instances(list<ACLPermission*>& o)
{
  ACLPermission *p = new ACLPermission;
  p->set_permissions(RGW_PERM_WRITE_ACP);
  o.push_back(p);
  o.push_back(new ACLPermission);
}

void ACLPermission::dump(Formatter *f) const
{
  f->dump_int("flags", flags);
}

void ACLGranteeType::dump(Formatter *f) const
{
  f->dump_unsigned("type", type);
}

void ACLGrant::dump(Formatter *f) const
{
  f->open_object_section("type");
  type.dump(f);
  f->close_section();

  f->dump_string("id", id.to_str());
  f->dump_string("email", email);

  f->open_object_section("permission");
  permission.dump(f);
  f->close_section();

  f->dump_string("name", name);
  f->dump_int("group", (int)group);
  f->dump_string("url_spec", url_spec);
}

void ACLGrant::generate_test_instances(list<ACLGrant*>& o)
{
  rgw_user id("rgw");
  string name, email;
  name = "Mr. RGW";
  email = "r@gw";

  ACLGrant *g1 = new ACLGrant;
  g1->set_canon(id, name, RGW_PERM_READ);
  g1->email = email;
  o.push_back(g1);

  ACLGrant *g2 = new ACLGrant;
  g1->set_group(ACL_GROUP_AUTHENTICATED_USERS, RGW_PERM_WRITE);
  o.push_back(g2);

  o.push_back(new ACLGrant);
}

void ACLGranteeType::generate_test_instances(list<ACLGranteeType*>& o)
{
  ACLGranteeType *t = new ACLGranteeType;
  t->set(ACL_TYPE_CANON_USER);
  o.push_back(t);
  o.push_back(new ACLGranteeType);
}

void RGWAccessControlList::generate_test_instances(list<RGWAccessControlList*>& o)
{
  RGWAccessControlList *acl = new RGWAccessControlList(NULL);

  list<ACLGrant *> glist;
  list<ACLGrant *>::iterator iter;

  ACLGrant::generate_test_instances(glist);
  for (iter = glist.begin(); iter != glist.end(); ++iter) {
    ACLGrant *grant = *iter;
    acl->add_grant(grant);

    delete grant;
  }
  o.push_back(acl);
  o.push_back(new RGWAccessControlList(NULL));
}

void ACLOwner::generate_test_instances(list<ACLOwner*>& o)
{
  ACLOwner *owner = new ACLOwner;
  owner->id = "rgw";
  owner->display_name = "Mr. RGW";
  o.push_back(owner);
  o.push_back(new ACLOwner);
}

void RGWAccessControlPolicy::generate_test_instances(list<RGWAccessControlPolicy*>& o)
{
  list<RGWAccessControlList *> acl_list;
  list<RGWAccessControlList *>::iterator iter;
  for (iter = acl_list.begin(); iter != acl_list.end(); ++iter) {
    RGWAccessControlList::generate_test_instances(acl_list);
    iter = acl_list.begin();

    RGWAccessControlPolicy *p = new RGWAccessControlPolicy(NULL);
    RGWAccessControlList *l = *iter;
    p->acl = *l;

    string name = "radosgw";
    rgw_user id("rgw");
    p->owner.set_name(name);
    p->owner.set_id(id);

    o.push_back(p);

    delete l;
  }

  o.push_back(new RGWAccessControlPolicy(NULL));
}

void RGWAccessControlList::dump(Formatter *f) const
{
  map<string, int>::const_iterator acl_user_iter = acl_user_map.begin();
  f->open_array_section("acl_user_map");
  for (; acl_user_iter != acl_user_map.end(); ++acl_user_iter) {
    f->open_object_section("entry");
    f->dump_string("user", acl_user_iter->first);
    f->dump_int("acl", acl_user_iter->second);
    f->close_section();
  }
  f->close_section();

  map<uint32_t, int>::const_iterator acl_group_iter = acl_group_map.begin();
  f->open_array_section("acl_group_map");
  for (; acl_group_iter != acl_group_map.end(); ++acl_group_iter) {
    f->open_object_section("entry");
    f->dump_unsigned("group", acl_group_iter->first);
    f->dump_int("acl", acl_group_iter->second);
    f->close_section();
  }
  f->close_section();

  multimap<string, ACLGrant>::const_iterator giter = grant_map.begin();
  f->open_array_section("grant_map");
  for (; giter != grant_map.end(); ++giter) {
    f->open_object_section("entry");
    f->dump_string("id", giter->first);
    f->open_object_section("grant");
    giter->second.dump(f);
    f->close_section();
    f->close_section();
  }
  f->close_section();
}

void ACLOwner::dump(Formatter *f) const
{
  encode_json("id", id.to_str(), f);
  encode_json("display_name", display_name, f);
}

void ACLOwner::decode_json(JSONObj *obj) {
  string id_str;
  JSONDecoder::decode_json("id", id_str, obj);
  id.from_str(id_str);
  JSONDecoder::decode_json("display_name", display_name, obj);
}

void RGWAccessControlPolicy::dump(Formatter *f) const
{
  encode_json("acl", acl, f);
  encode_json("owner", owner, f);
}

ACLGroupTypeEnum ACLGrant::uri_to_group(string& uri)
{
  // this is required for backward compatibility
  return ACLGrant_S3::uri_to_group(uri);
}

