// constant_h
#ifndef CONSTANT_H
#define CONSTANT_H

enum class AttestationConveyancePreference {
  NONE,
  INDIRECT,
  DIRECT,
  ENTERPRISE
};

enum class UserVerificationRequirement {
  REQUIRED,
  PREFERRED,
  DISCOURAGED
};

enum class AuthenticatorAttachment {
    PLATFORM,
    CROSS_PLATFORM,
    UNSPECIFIED
};

enum class ResidentKeyRequirement {
    REQUIRED,
    PREFERRED,
    DISCOURAGED
};

enum class AuthenticatorTransport {
    USB,
    NFC,
    BLE,
    INTERNAL,
    HYBRID
};

#endif
