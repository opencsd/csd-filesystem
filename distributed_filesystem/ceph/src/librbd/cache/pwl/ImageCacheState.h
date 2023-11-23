// -*- mode:C++; tab-width:8; c-basic-offset:2; indent-tabs-mode:t -*-
// vim: ts=8 sw=2 smarttab

#ifndef CEPH_LIBRBD_CACHE_RWL_IMAGE_CACHE_STATE_H
#define CEPH_LIBRBD_CACHE_RWL_IMAGE_CACHE_STATE_H

#include "librbd/ImageCtx.h"
#include "librbd/cache/Types.h"
#include <string>

class JSONFormattable;
namespace ceph {
  class Formatter;
}

namespace librbd {

namespace plugin { template <typename> struct Api; }

namespace cache {
namespace pwl {

template <typename ImageCtxT = ImageCtx>
class ImageCacheState {
private:
  ImageCtxT* m_image_ctx;
  plugin::Api<ImageCtxT>& m_plugin_api;
public:
  bool present = false;
  bool empty = true;
  bool clean = true;
  std::string host;
  std::string path;
  std::string cache_type;
  uint64_t size = 0;
  bool log_periodic_stats;

  ImageCacheState(ImageCtxT* image_ctx, plugin::Api<ImageCtxT>& plugin_api);

  ImageCacheState(ImageCtxT* image_ctx, JSONFormattable& f,
                  plugin::Api<ImageCtxT>& plugin_api);

  ~ImageCacheState() {}

  ImageCacheType get_image_cache_type() const {
    if (cache_type == "rwl") {
      return IMAGE_CACHE_TYPE_RWL;
    } else if (cache_type == "ssd") {
      return IMAGE_CACHE_TYPE_SSD;
    }
    return IMAGE_CACHE_TYPE_UNKNOWN;
  }


  void write_image_cache_state(Context *on_finish);

  void clear_image_cache_state(Context *on_finish);

  void dump(ceph::Formatter *f) const;

  static ImageCacheState<ImageCtxT>* create_image_cache_state(
    ImageCtxT* image_ctx, plugin::Api<ImageCtxT>& plugin_api, int &r);

  static ImageCacheState<ImageCtxT>* get_image_cache_state(
    ImageCtxT* image_ctx, plugin::Api<ImageCtxT>& plugin_api);

  bool is_valid();
};

} // namespace pwl
} // namespace cache
} // namespace librbd

extern template class librbd::cache::pwl::ImageCacheState<librbd::ImageCtx>;

#endif // CEPH_LIBRBD_CACHE_RWL_IMAGE_CACHE_STATE_H
