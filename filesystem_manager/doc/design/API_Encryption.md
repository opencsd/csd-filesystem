# API Encryption

## Architectural Overview

```mermaid
sequenceDiagram
    participant Client
    participant GMS
    participant etcd
    Note over GMS: N.B. The format of All RSA public-keys in these diagram follows PKCS no.1 padding
    loop Signing Key regeneration (Every 600s)
        GMS->>GMS: Generate RSA key pairs
        Note over GMS: (signing_privkey, signing_pubkey) = generate_rsa_keys()
    end
    Client->>GMS: GET http://gms.domain.com/
    GMS->>Client: 200 OK
    Note over GMS, Client: Set-Cookie: signing_key=encodeURI(encode_base64(<signing_pubkey>))
    activate Client
        Client->>Client: signing_pubkey = decode_base64(decodeURI(Cookie.signing_key))
    deactivate Client
    Client->>GMS: POST http://gms.domain.com/api/manager/sign_in
    Note over Client, GMS: payload = { id: <id>, password: encode_base64(encrypt_rsa(<signing_pubkey>, <data>)) }
    activate GMS
    GMS->>GMS: Decrypt and validate sign-in
    Note right of GMS: decoded = decode_base64(payload.password)<br />decrypted = descrypt_rsa(<signing_privkey>, decoded)<br />validate(id, decrypted)<br />token = generate_token()<br />(privkey, pubkey) = generate_rsa_keys()
    deactivate GMS
    GMS->>etcd: Store RSA key pairs into etcd per token(session)
    Note over GMS, etcd: /Sessions/<token>/private_key = <privkey><br />/Sessions/<token>/public_key = <pubkey>
    GMS->>Client: 200 OK
    Note over GMS, Client: payload: { token: <token>, public_key: <pubkey> }<br />N.B. <public_key> is stored into JWT token and payload both
    Client->>GMS: POST http://gms.domain.com/api/...
    Note over Client, GMS: payload: { secret = encode_base64(encrypt_rsa(<pubkey>, <data>)) }
    activate GMS
        GMS->>etcd: Request a private key for a session <br />
        Note over GMS, etcd: key: /Sessions/<token>/private_key
        etcd->>GMS: Response with the private key
        GMS->>GMS: <privkey> = /Sessions/<token>/private_key
        GMS->>GMS: Decrypt the data
        Note right of GMS: decoded = decode_base64(payload.secret) <br /> decrypted = decrypt_rsa(<pubkey>, decoded)<br />process_with_decrypted()
    deactivate GMS
    GMS->>Client: Response with status code
```

## Used libraries for this feature

* Web UI
  * [jsencrypt v2.3](https://github.com/travist/jsencrypt/)
    * For now, jsencrypt does not support OAEP padding so we should use PKCS #1
    * https://github.com/travist/jsencrypt/issues/84
  * [jwt-decode v2.2.0](https://github.com/auth0/jwt-decode)
* GMS
  * [MIME::Base64](https://metacpan.org/pod/MIME::Base64)
  * [Crypt::OpenSSL::RSA](https://metacpan.org/pod/Crypt::OpenSSL::RSA)
  * [Crypt::OpenSSL::Bignum](https://metacpan.org/pod/Crypt::OpenSSL::Bignum)
