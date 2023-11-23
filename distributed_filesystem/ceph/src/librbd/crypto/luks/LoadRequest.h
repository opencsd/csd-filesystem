// -*- mode:C++; tab-width:8; c-basic-offset:2; indent-tabs-mode:t -*-
// vim: ts=8 sw=2 smarttab

#ifndef CEPH_LIBRBD_CRYPTO_LUKS_LOAD_REQUEST_H
#define CEPH_LIBRBD_CRYPTO_LUKS_LOAD_REQUEST_H

#include "include/rbd/librbd.hpp"
#include "librbd/ImageCtx.h"
#include "librbd/crypto/CryptoInterface.h"
#include "librbd/crypto/luks/Header.h"

namespace librbd {

class ImageCtx;

namespace crypto {
namespace luks {

// max header size in LUKS1/2 (excl. keyslots) is 4MB
const uint64_t MAXIMUM_HEADER_SIZE = 4 * 1024 * 1024;
// default header size in LUKS2 2 X 16KB + 1 X 256KB keyslot
const uint64_t DEFAULT_INITIAL_READ_SIZE = 288 * 1024;

template <typename I>
class LoadRequest {
public:
    static LoadRequest* create(
            I* image_ctx, encryption_format_t format, std::string&& passphrase,
            ceph::ref_t<CryptoInterface>* result_crypto, Context* on_finish) {
      return new LoadRequest(image_ctx, format, std::move(passphrase),
                             result_crypto, on_finish);
    }

    LoadRequest(I* image_ctx, encryption_format_t format,
                std::string&& passphrase,
                ceph::ref_t<CryptoInterface>* result_crypto,
                Context* on_finish);
    void send();
    void finish(int r);
    void set_initial_read_size(uint64_t read_size);

private:
    I* m_image_ctx;
    encryption_format_t m_format;
    std::string m_passphrase;
    Context* m_on_finish;
    ceph::bufferlist m_bl;
    ceph::ref_t<CryptoInterface>* m_result_crypto;
    uint64_t m_initial_read_size;
    Header m_header;
    uint64_t m_offset;

    void read(uint64_t end_offset, Context* on_finish);
    bool handle_read(int r);
    void handle_read_header(int r);
    void handle_read_keyslots(int r);
    void read_volume_key();
};

} // namespace luks
} // namespace crypto
} // namespace librbd

extern template class librbd::crypto::luks::LoadRequest<librbd::ImageCtx>;

#endif // CEPH_LIBRBD_CRYPTO_LUKS_LOAD_REQUEST_H
