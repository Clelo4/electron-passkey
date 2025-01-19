// PublicKeyCredentialCreationOptions.cpp
#include "PublicKeyCredentialCreationOptions.h"
#include <stdexcept>

PublicKeyCredentialCreationOptions::PublicKeyCredentialCreationOptions()
    : has_timeout_(false), timeout_(0), has_authenticator_selection_(false),
      attestation_(AttestationConveyancePreference::NONE) {}

PublicKeyCredentialCreationOptions::PublicKeyCredentialCreationOptions(
    PublicKeyCredentialCreationOptions &&other)
    : challenge_(std::move(other.challenge_)), rp_(std::move(other.rp_)),
      user_(std::move(other.user_)),
      pubKeyCredParams_(std::move(other.pubKeyCredParams_)),
      has_timeout_(other.has_timeout_), timeout_(other.timeout_),
      excludeCredentials_(std::move(other.excludeCredentials_)),
      has_authenticator_selection_(other.has_authenticator_selection_),
      authenticatorSelection_(std::move(other.authenticatorSelection_)),
      attestation_(std::move(other.attestation_))
      {}

PublicKeyCredentialCreationOptions &
PublicKeyCredentialCreationOptions::operator=(
    PublicKeyCredentialCreationOptions &&other) {
  if (&other != this) {
    challenge_ = std::move(other.challenge_);
    rp_ = std::move(other.rp_);
    user_ = std::move(other.user_);
    pubKeyCredParams_ = std::move(other.pubKeyCredParams_);
    has_timeout_ = other.has_timeout_;
    timeout_ = other.timeout_;
    excludeCredentials_ = std::move(other.excludeCredentials_);
    has_authenticator_selection_ = other.has_authenticator_selection_;
    authenticatorSelection_ = std::move(other.authenticatorSelection_);
    attestation_ = other.attestation_;
  }
  return *this;
}
