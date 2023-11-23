// -*- mode:C++; tab-width:8; c-basic-offset:2; indent-tabs-mode:t -*-
// vim: ts=8 sw=2 smarttab ft=cpp

#include "svc_sys_obj_core.h"
#include "svc_rados.h"
#include "svc_zone.h"

#include "rgw/rgw_tools.h"

#define dout_subsys ceph_subsys_rgw

using namespace std;

int RGWSI_SysObj_Core_GetObjState::get_rados_obj(const DoutPrefixProvider *dpp,
                                                 RGWSI_RADOS *rados_svc,
                                                 RGWSI_Zone *zone_svc,
                                                 const rgw_raw_obj& obj,
                                                 RGWSI_RADOS::Obj **pobj)
{
  if (!has_rados_obj) {
    if (obj.oid.empty()) {
      ldpp_dout(dpp, 0) << "ERROR: obj.oid is empty" << dendl;
      return -EINVAL;
    }

    rados_obj = rados_svc->obj(obj);
    int r = rados_obj.open(dpp);
    if (r < 0) {
      return r;
    }
    has_rados_obj = true;
  }
  *pobj = &rados_obj;
  return 0;
}

int RGWSI_SysObj_Core::get_rados_obj(const DoutPrefixProvider *dpp,
                                     RGWSI_Zone *zone_svc,
                                     const rgw_raw_obj& obj,
                                     RGWSI_RADOS::Obj *pobj)
{
  if (obj.oid.empty()) {
    ldpp_dout(dpp, 0) << "ERROR: obj.oid is empty" << dendl;
    return -EINVAL;
  }

  *pobj = rados_svc->obj(obj);
  int r = pobj->open(dpp);
  if (r < 0) {
    return r;
  }

  return 0;
}

int RGWSI_SysObj_Core::get_system_obj_state_impl(RGWSysObjectCtxBase *rctx,
                                                 const rgw_raw_obj& obj,
                                                 RGWSysObjState **state,
                                                 RGWObjVersionTracker *objv_tracker,
                                                 optional_yield y,
                                                 const DoutPrefixProvider *dpp)
{
  if (obj.empty()) {
    return -EINVAL;
  }

  RGWSysObjState *s = rctx->get_state(obj);
  ldpp_dout(dpp, 20) << "get_system_obj_state: rctx=" << (void *)rctx << " obj=" << obj << " state=" << (void *)s << " s->prefetch_data=" << s->prefetch_data << dendl;
  *state = s;
  if (s->has_attrs) {
    return 0;
  }

  s->obj = obj;

  int r = raw_stat(dpp, obj, &s->size, &s->mtime, &s->epoch, &s->attrset,
                   (s->prefetch_data ? &s->data : nullptr), objv_tracker, y);
  if (r == -ENOENT) {
    s->exists = false;
    s->has_attrs = true;
    s->mtime = real_time();
    return 0;
  }
  if (r < 0)
    return r;

  s->exists = true;
  s->has_attrs = true;
  s->obj_tag = s->attrset[RGW_ATTR_ID_TAG];

  if (s->obj_tag.length()) {
    ldpp_dout(dpp, 20) << "get_system_obj_state: setting s->obj_tag to " << s->obj_tag.c_str() << dendl;
  } else {
    ldpp_dout(dpp, 20) << "get_system_obj_state: s->obj_tag was set empty" << dendl;
  }

  return 0;
}

int RGWSI_SysObj_Core::get_system_obj_state(RGWSysObjectCtxBase *rctx,
                                            const rgw_raw_obj& obj,
                                            RGWSysObjState **state,
                                            RGWObjVersionTracker *objv_tracker,
                                            optional_yield y,
                                            const DoutPrefixProvider *dpp)
{
  int ret;

  do {
    ret = get_system_obj_state_impl(rctx, obj, state, objv_tracker, y, dpp);
  } while (ret == -EAGAIN);

  return ret;
}

int RGWSI_SysObj_Core::raw_stat(const DoutPrefixProvider *dpp, const rgw_raw_obj& obj, uint64_t *psize, real_time *pmtime, uint64_t *epoch,
                                map<string, bufferlist> *attrs, bufferlist *first_chunk,
                                RGWObjVersionTracker *objv_tracker,
                                optional_yield y)
{
  RGWSI_RADOS::Obj rados_obj;
  int r = get_rados_obj(dpp, zone_svc, obj, &rados_obj);
  if (r < 0) {
    return r;
  }

  uint64_t size = 0;
  struct timespec mtime_ts;

  librados::ObjectReadOperation op;
  if (objv_tracker) {
    objv_tracker->prepare_op_for_read(&op);
  }
  op.getxattrs(attrs, nullptr);
  if (psize || pmtime) {
    op.stat2(&size, &mtime_ts, nullptr);
  }
  if (first_chunk) {
    op.read(0, cct->_conf->rgw_max_chunk_size, first_chunk, nullptr);
  }
  bufferlist outbl;
  r = rados_obj.operate(dpp, &op, &outbl, y);

  if (epoch) {
    *epoch = rados_obj.get_last_version();
  }

  if (r < 0)
    return r;

  if (psize)
    *psize = size;
  if (pmtime)
    *pmtime = ceph::real_clock::from_timespec(mtime_ts);

  return 0;
}

int RGWSI_SysObj_Core::stat(RGWSysObjectCtxBase& obj_ctx,
                            RGWSI_SysObj_Obj_GetObjState& _state,
                            const rgw_raw_obj& obj,
                            map<string, bufferlist> *attrs,
			    bool raw_attrs,
                            real_time *lastmod,
                            uint64_t *obj_size,
                            RGWObjVersionTracker *objv_tracker,
                            optional_yield y,
                            const DoutPrefixProvider *dpp)
{
  RGWSysObjState *astate = nullptr;

  int r = get_system_obj_state(&obj_ctx, obj, &astate, objv_tracker, y, dpp);
  if (r < 0)
    return r;

  if (!astate->exists) {
    return -ENOENT;
  }

  if (attrs) {
    if (raw_attrs) {
      *attrs = astate->attrset;
    } else {
      rgw_filter_attrset(astate->attrset, RGW_ATTR_PREFIX, attrs);
    }
    if (cct->_conf->subsys.should_gather<ceph_subsys_rgw, 20>()) {
      map<string, bufferlist>::iterator iter;
      for (iter = attrs->begin(); iter != attrs->end(); ++iter) {
        ldpp_dout(dpp, 20) << "Read xattr: " << iter->first << dendl;
      }
    }
  }

  if (obj_size)
    *obj_size = astate->size;
  if (lastmod)
    *lastmod = astate->mtime;

  return 0;
}

int RGWSI_SysObj_Core::read(const DoutPrefixProvider *dpp,
                            RGWSysObjectCtxBase& obj_ctx,
                            RGWSI_SysObj_Obj_GetObjState& _read_state,
                            RGWObjVersionTracker *objv_tracker,
                            const rgw_raw_obj& obj,
                            bufferlist *bl, off_t ofs, off_t end,
                            map<string, bufferlist> *attrs,
			    bool raw_attrs,
                            rgw_cache_entry_info *cache_info,
                            boost::optional<obj_version>,
                            optional_yield y)
{
  auto& read_state = static_cast<GetObjState&>(_read_state);

  uint64_t len;
  librados::ObjectReadOperation op;

  if (end < 0)
    len = 0;
  else
    len = end - ofs + 1;

  if (objv_tracker) {
    objv_tracker->prepare_op_for_read(&op);
  }

  ldpp_dout(dpp, 20) << "rados->read ofs=" << ofs << " len=" << len << dendl;
  op.read(ofs, len, bl, nullptr);

  map<string, bufferlist> unfiltered_attrset;

  if (attrs) {
    if (raw_attrs) {
      op.getxattrs(attrs, nullptr);
    } else {
      op.getxattrs(&unfiltered_attrset, nullptr);
    }
  }

  RGWSI_RADOS::Obj rados_obj;
  int r = get_rados_obj(dpp, zone_svc, obj, &rados_obj);
  if (r < 0) {
    ldpp_dout(dpp, 20) << "get_rados_obj() on obj=" << obj << " returned " << r << dendl;
    return r;
  }
  r = rados_obj.operate(dpp, &op, nullptr, y);
  if (r < 0) {
    ldpp_dout(dpp, 20) << "rados_obj.operate() r=" << r << " bl.length=" << bl->length() << dendl;
    return r;
  }
  ldpp_dout(dpp, 20) << "rados_obj.operate() r=" << r << " bl.length=" << bl->length() << dendl;

  uint64_t op_ver = rados_obj.get_last_version();

  if (read_state.last_ver > 0 &&
      read_state.last_ver != op_ver) {
    ldpp_dout(dpp, 5) << "raced with an object write, abort" << dendl;
    return -ECANCELED;
  }

  if (attrs && !raw_attrs) {
    rgw_filter_attrset(unfiltered_attrset, RGW_ATTR_PREFIX, attrs);
  }

  read_state.last_ver = op_ver;

  return bl->length();
}

/**
 * Get an attribute for a system object.
 * obj: the object to get attr
 * name: name of the attr to retrieve
 * dest: bufferlist to store the result in
 * Returns: 0 on success, -ERR# otherwise.
 */
int RGWSI_SysObj_Core::get_attr(const DoutPrefixProvider *dpp,
                                const rgw_raw_obj& obj,
                                const char *name,
                                bufferlist *dest,
                                optional_yield y)
{
  RGWSI_RADOS::Obj rados_obj;
  int r = get_rados_obj(dpp, zone_svc, obj, &rados_obj);
  if (r < 0) {
    ldpp_dout(dpp, 20) << "get_rados_obj() on obj=" << obj << " returned " << r << dendl;
    return r;
  }

  librados::ObjectReadOperation op;

  int rval;
  op.getxattr(name, dest, &rval);
  
  r = rados_obj.operate(dpp, &op, nullptr, y);
  if (r < 0)
    return r;

  return 0;
}

int RGWSI_SysObj_Core::set_attrs(const DoutPrefixProvider *dpp, 
                                 const rgw_raw_obj& obj,
                                 map<string, bufferlist>& attrs,
                                 map<string, bufferlist> *rmattrs,
                                 RGWObjVersionTracker *objv_tracker,
                                 optional_yield y)
{
  RGWSI_RADOS::Obj rados_obj;
  int r = get_rados_obj(dpp, zone_svc, obj, &rados_obj);
  if (r < 0) {
    ldpp_dout(dpp, 20) << "get_rados_obj() on obj=" << obj << " returned " << r << dendl;
    return r;
  }

  librados::ObjectWriteOperation op;

  if (objv_tracker) {
    objv_tracker->prepare_op_for_write(&op);
  }

  map<string, bufferlist>::iterator iter;
  if (rmattrs) {
    for (iter = rmattrs->begin(); iter != rmattrs->end(); ++iter) {
      const string& name = iter->first;
      op.rmxattr(name.c_str());
    }
  }

  for (iter = attrs.begin(); iter != attrs.end(); ++iter) {
    const string& name = iter->first;
    bufferlist& bl = iter->second;

    if (!bl.length())
      continue;

    op.setxattr(name.c_str(), bl);
  }

  if (!op.size())
    return 0;

  bufferlist bl;

  r = rados_obj.operate(dpp, &op, y);
  if (r < 0)
    return r;

  if (objv_tracker) {
    objv_tracker->apply_write();
  }
  return 0;
}

int RGWSI_SysObj_Core::omap_get_vals(const DoutPrefixProvider *dpp, 
                                     const rgw_raw_obj& obj,
                                     const string& marker,
                                     uint64_t count,
                                     std::map<string, bufferlist> *m,
                                     bool *pmore,
                                     optional_yield y)
{
  RGWSI_RADOS::Obj rados_obj;
  int r = get_rados_obj(dpp, zone_svc, obj, &rados_obj);
  if (r < 0) {
    ldpp_dout(dpp, 20) << "get_rados_obj() on obj=" << obj << " returned " << r << dendl;
    return r;
  }

  string start_after = marker;
  bool more;

  do {
    librados::ObjectReadOperation op;

    std::map<string, bufferlist> t;
    int rval;
    op.omap_get_vals2(start_after, count, &t, &more, &rval);
  
    r = rados_obj.operate(dpp, &op, nullptr, y);
    if (r < 0) {
      return r;
    }
    if (t.empty()) {
      break;
    }
    count -= t.size();
    start_after = t.rbegin()->first;
    m->insert(t.begin(), t.end());
  } while (more && count > 0);

  if (pmore) {
    *pmore = more;
  }
  return 0;
}

int RGWSI_SysObj_Core::omap_get_all(const DoutPrefixProvider *dpp, 
                                    const rgw_raw_obj& obj,
                                    std::map<string, bufferlist> *m,
                                    optional_yield y)
{
  RGWSI_RADOS::Obj rados_obj;
  int r = get_rados_obj(dpp, zone_svc, obj, &rados_obj);
  if (r < 0) {
    ldpp_dout(dpp, 20) << "get_rados_obj() on obj=" << obj << " returned " << r << dendl;
    return r;
  }

#define MAX_OMAP_GET_ENTRIES 1024
  const int count = MAX_OMAP_GET_ENTRIES;
  string start_after;
  bool more;

  do {
    librados::ObjectReadOperation op;

    std::map<string, bufferlist> t;
    int rval;
    op.omap_get_vals2(start_after, count, &t, &more, &rval);
  
    r = rados_obj.operate(dpp, &op, nullptr, y);
    if (r < 0) {
      return r;
    }
    if (t.empty()) {
      break;
    }
    start_after = t.rbegin()->first;
    m->insert(t.begin(), t.end());
  } while (more);
  return 0;
}

int RGWSI_SysObj_Core::omap_set(const DoutPrefixProvider *dpp, const rgw_raw_obj& obj, const std::string& key,
                                bufferlist& bl, bool must_exist,
                                optional_yield y)
{
  RGWSI_RADOS::Obj rados_obj;
  int r = get_rados_obj(dpp, zone_svc, obj, &rados_obj);
  if (r < 0) {
    ldpp_dout(dpp, 20) << "get_rados_obj() on obj=" << obj << " returned " << r << dendl;
    return r;
  }

  ldpp_dout(dpp, 15) << "omap_set obj=" << obj << " key=" << key << dendl;

  map<string, bufferlist> m;
  m[key] = bl;
  librados::ObjectWriteOperation op;
  if (must_exist)
    op.assert_exists();
  op.omap_set(m);
  r = rados_obj.operate(dpp, &op, y);
  return r;
}

int RGWSI_SysObj_Core::omap_set(const DoutPrefixProvider *dpp, const rgw_raw_obj& obj,
                                const std::map<std::string, bufferlist>& m,
                                bool must_exist, optional_yield y)
{
  RGWSI_RADOS::Obj rados_obj;
  int r = get_rados_obj(dpp, zone_svc, obj, &rados_obj);
  if (r < 0) {
    ldpp_dout(dpp, 20) << "get_rados_obj() on obj=" << obj << " returned " << r << dendl;
    return r;
  }

  librados::ObjectWriteOperation op;
  if (must_exist)
    op.assert_exists();
  op.omap_set(m);
  r = rados_obj.operate(dpp, &op, y);
  return r;
}

int RGWSI_SysObj_Core::omap_del(const DoutPrefixProvider *dpp, const rgw_raw_obj& obj, const std::string& key,
                                optional_yield y)
{
  RGWSI_RADOS::Obj rados_obj;
  int r = get_rados_obj(dpp, zone_svc, obj, &rados_obj);
  if (r < 0) {
    ldpp_dout(dpp, 20) << "get_rados_obj() on obj=" << obj << " returned " << r << dendl;
    return r;
  }

  set<string> k;
  k.insert(key);

  librados::ObjectWriteOperation op;

  op.omap_rm_keys(k);

  r = rados_obj.operate(dpp, &op, y);
  return r;
}

int RGWSI_SysObj_Core::notify(const DoutPrefixProvider *dpp, const rgw_raw_obj& obj, bufferlist& bl,
                              uint64_t timeout_ms, bufferlist *pbl,
                              optional_yield y)
{
  RGWSI_RADOS::Obj rados_obj;
  int r = get_rados_obj(dpp, zone_svc, obj, &rados_obj);
  if (r < 0) {
    ldpp_dout(dpp, 20) << "get_rados_obj() on obj=" << obj << " returned " << r << dendl;
    return r;
  }

  r = rados_obj.notify(dpp, bl, timeout_ms, pbl, y);
  return r;
}

int RGWSI_SysObj_Core::remove(const DoutPrefixProvider *dpp, 
                              RGWSysObjectCtxBase& obj_ctx,
                              RGWObjVersionTracker *objv_tracker,
                              const rgw_raw_obj& obj,
                              optional_yield y)
{
  RGWSI_RADOS::Obj rados_obj;
  int r = get_rados_obj(dpp, zone_svc, obj, &rados_obj);
  if (r < 0) {
    ldpp_dout(dpp, 20) << "get_rados_obj() on obj=" << obj << " returned " << r << dendl;
    return r;
  }

  librados::ObjectWriteOperation op;

  if (objv_tracker) {
    objv_tracker->prepare_op_for_write(&op);
  }

  op.remove();
  r = rados_obj.operate(dpp, &op, y);
  if (r < 0)
    return r;

  return 0;
}

int RGWSI_SysObj_Core::write(const DoutPrefixProvider *dpp, 
                             const rgw_raw_obj& obj,
                             real_time *pmtime,
                             map<std::string, bufferlist>& attrs,
                             bool exclusive,
                             const bufferlist& data,
                             RGWObjVersionTracker *objv_tracker,
                             real_time set_mtime,
                             optional_yield y)
{
  RGWSI_RADOS::Obj rados_obj;
  int r = get_rados_obj(dpp, zone_svc, obj, &rados_obj);
  if (r < 0) {
    ldpp_dout(dpp, 20) << "get_rados_obj() on obj=" << obj << " returned " << r << dendl;
    return r;
  }

  librados::ObjectWriteOperation op;

  if (exclusive) {
    op.create(true); // exclusive create
  } else {
    op.remove();
    op.set_op_flags2(LIBRADOS_OP_FLAG_FAILOK);
    op.create(false);
  }

  if (objv_tracker) {
    objv_tracker->prepare_op_for_write(&op);
  }

  if (real_clock::is_zero(set_mtime)) {
    set_mtime = real_clock::now();
  }

  struct timespec mtime_ts = real_clock::to_timespec(set_mtime);
  op.mtime2(&mtime_ts);
  op.write_full(data);

  bufferlist acl_bl;

  for (map<string, bufferlist>::iterator iter = attrs.begin(); iter != attrs.end(); ++iter) {
    const string& name = iter->first;
    bufferlist& bl = iter->second;

    if (!bl.length())
      continue;

    op.setxattr(name.c_str(), bl);
  }

  r = rados_obj.operate(dpp, &op, y);
  if (r < 0) {
    return r;
  }

  if (objv_tracker) {
    objv_tracker->apply_write();
  }

  if (pmtime) {
    *pmtime = set_mtime;
  }

  return 0;
}


int RGWSI_SysObj_Core::write_data(const DoutPrefixProvider *dpp, 
                                  const rgw_raw_obj& obj,
                                  const bufferlist& bl,
                                  bool exclusive,
                                  RGWObjVersionTracker *objv_tracker,
                                  optional_yield y)
{
  RGWSI_RADOS::Obj rados_obj;
  int r = get_rados_obj(dpp, zone_svc, obj, &rados_obj);
  if (r < 0) {
    ldpp_dout(dpp, 20) << "get_rados_obj() on obj=" << obj << " returned " << r << dendl;
    return r;
  }

  librados::ObjectWriteOperation op;

  if (exclusive) {
    op.create(true);
  }

  if (objv_tracker) {
    objv_tracker->prepare_op_for_write(&op);
  }
  op.write_full(bl);
  r = rados_obj.operate(dpp, &op, y);
  if (r < 0)
    return r;

  if (objv_tracker) {
    objv_tracker->apply_write();
  }
  return 0;
}

int RGWSI_SysObj_Core::pool_list_prefixed_objs(const DoutPrefixProvider *dpp,
                                               const rgw_pool& pool, const string& prefix,
                                               std::function<void(const string&)> cb)
{
  bool is_truncated;

  auto rados_pool = rados_svc->pool(pool);

  auto op = rados_pool.op();

  RGWAccessListFilterPrefix filter(prefix);

  int r = op.init(dpp, string(), &filter);
  if (r < 0) {
    return r;
  }

  do {
    vector<string> oids;
#define MAX_OBJS_DEFAULT 1000
    int r = op.get_next(dpp, MAX_OBJS_DEFAULT, &oids, &is_truncated);
    if (r < 0) {
      return r;
    }
    for (auto& val : oids) {
      if (val.size() > prefix.size()) {
        cb(val.substr(prefix.size()));
      }
    }
  } while (is_truncated);

  return 0;
}

int RGWSI_SysObj_Core::pool_list_objects_init(const DoutPrefixProvider *dpp,
                                              const rgw_pool& pool,
                                              const string& marker,
                                              const string& prefix,
                                              RGWSI_SysObj::Pool::ListCtx *_ctx)
{
  _ctx->impl.emplace<PoolListImplInfo>(prefix);

  auto& ctx = static_cast<PoolListImplInfo&>(*_ctx->impl);

  ctx.pool = rados_svc->pool(pool);
  ctx.op = ctx.pool.op();

  int r = ctx.op.init(dpp, marker, &ctx.filter);
  if (r < 0) {
    ldpp_dout(dpp, 10) << "failed to list objects pool_iterate_begin() returned r=" << r << dendl;
    return r;
  }
  return 0;
}

int RGWSI_SysObj_Core::pool_list_objects_next(const DoutPrefixProvider *dpp,
                                              RGWSI_SysObj::Pool::ListCtx& _ctx,
                                              int max,
                                              vector<string> *oids,
                                              bool *is_truncated)
{
  if (!_ctx.impl) {
    return -EINVAL;
  }
  auto& ctx = static_cast<PoolListImplInfo&>(*_ctx.impl);
  int r = ctx.op.get_next(dpp, max, oids, is_truncated);
  if (r < 0) {
    if(r != -ENOENT)
      ldpp_dout(dpp, 10) << "failed to list objects pool_iterate returned r=" << r << dendl;
    return r;
  }

  return oids->size();
}

int RGWSI_SysObj_Core::pool_list_objects_get_marker(RGWSI_SysObj::Pool::ListCtx& _ctx,
                                                    string *marker)
{
  if (!_ctx.impl) {
    return -EINVAL;
  }

  auto& ctx = static_cast<PoolListImplInfo&>(*_ctx.impl);
  return ctx.op.get_marker(marker);
}
