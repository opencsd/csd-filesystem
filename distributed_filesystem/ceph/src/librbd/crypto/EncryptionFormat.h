// -*- mode:C++; tab-width:8; c-basic-offset:2; indent-tabs-mode:t -*-
// vim: ts=8 sw=2 smarttab

#ifndef CEPH_LIBRBD_CRYPTO_ENCRYPTION_FORMAT_H
#define CEPH_LIBRBD_CRYPTO_ENCRYPTION_FORMAT_H

#include "common/ref.h"

struct Context;

namespace librbd {
namespace crypto {

struct CryptoInterface;

template <typename ImageCtxT>
struct EncryptionFormat {
  virtual ~EncryptionFormat() {
  }

  virtual void format(ImageCtxT* ictx, Context* on_finish) = 0;
  virtual void load(ImageCtxT* ictx, Context* on_finish) = 0;

  virtual ceph::ref_t<CryptoInterface> get_crypto() = 0;
};

} // namespace crypto
} // namespace librbd

#endif // CEPH_LIBRBD_CRYPTO_ENCRYPTION_FORMAT_H
