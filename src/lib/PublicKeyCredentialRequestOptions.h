// PublicKeyCredentialRequestOptions.h
#ifndef PUBLIC_KEY_CREDENTIAL_REQUEST_OPTIONS_H
#define PUBLIC_KEY_CREDENTIAL_REQUEST_OPTIONS_H

#include <vector>
#include "credential.h"
#include "constant.h"

class PublicKeyCredentialRequestOptions {
public:
  PublicKeyCredentialRequestOptions();
  ~PublicKeyCredentialRequestOptions() = default;

  PublicKeyCredentialRequestOptions(const PublicKeyCredentialRequestOptions &) =
      delete;
  PublicKeyCredentialRequestOptions &
  operator=(const PublicKeyCredentialRequestOptions &) = delete;

  PublicKeyCredentialRequestOptions(PublicKeyCredentialRequestOptions &&);
  PublicKeyCredentialRequestOptions& operator=(PublicKeyCredentialRequestOptions &&);

  // Setters
  void SetChallenge(const std::vector<uint8_t> &challenge);
  void SetAllowCredentials(
      const std::vector<PublicKeyCredentialDescriptor> &allowCredentials);
  void SetRpId(const std::string &rpId);
  void SetTimeout(uint64_t timeout);
  void SetUserVerification(const UserVerificationRequirement& userVerificationRequirement);

  // Getters
  const std::vector<uint8_t>& GetChallenge() const;
  const std::vector<PublicKeyCredentialDescriptor>& GetAllowCredentials() const;
  bool HasRpId() const;
  const std::string &GetRpId() const;
  bool HasTimeout() const;
  uint64_t GetTimeout() const;
  bool HasUserVerification() const;
  const UserVerificationRequirement& GetUserVerification() const;
  
private:
  // Required properties
  std::vector<uint8_t> challenge_;

  // Optional properties
  std::vector<PublicKeyCredentialDescriptor> allowCredentials_;

  bool has_rpId_;
  std::string rpId_;

  bool has_timeout_;
  uint64_t timeout_;

  bool has_userVerification_;
  UserVerificationRequirement userVerification_;
};

#endif // PUBLIC_KEY_CREDENTIAL_REQUEST_OPTIONS_H
