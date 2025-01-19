// Credential.h
#ifndef CREDENTIAL_H
#define CREDENTIAL_H

#include <string>
#include <vector>

#include "constant.h"

struct PublicKeyCredentialDescriptor {
    std::string type;                       // 必需: 必须是 "public-key"
    std::vector<uint8_t> id;                // 必需: 凭证ID
    std::vector<AuthenticatorTransport> transports;  // 可选: 传输方式
};

#endif // CREDENTIAL_H
