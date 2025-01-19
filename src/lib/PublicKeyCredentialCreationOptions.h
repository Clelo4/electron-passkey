// PublicKeyCredentialCreationOptions
#ifndef PUBLIC_KEY_CREDENTIAL_CREATION_OPTIONS_H
#define PUBLIC_KEY_CREDENTIAL_CREATION_OPTIONS_H

#include <string>
#include <vector>
#include <map>
#include <memory>
#include <optional>
#include "constant.h"
#include "credential.h"

struct PublicKeyCredentialRpEntity {
    std::string id;
    std::string name;
};

struct PublicKeyCredentialUserEntity {
    std::vector<uint8_t> id;
    std::string name;
    std::string displayName;
};

struct PublicKeyCredentialParameters {
    std::string type;                       // "public-key"
    int32_t alg;
};

struct AuthenticatorSelectionCriteria {
  bool has_authenticator_attachment;
  AuthenticatorAttachment authenticator_attachment;

  bool has_resident_key;
  ResidentKeyRequirement residentKey = ResidentKeyRequirement::DISCOURAGED;

  // Deprecated
  bool require_resident_key;
  UserVerificationRequirement user_verification;

  AuthenticatorSelectionCriteria()
    : has_authenticator_attachment(false),
      has_resident_key(false),
      require_resident_key(false),
      user_verification(UserVerificationRequirement::PREFERRED)
      {}
};

class PublicKeyCredentialCreationOptions {

public:
  PublicKeyCredentialCreationOptions();
  ~PublicKeyCredentialCreationOptions() = default;

  PublicKeyCredentialCreationOptions(
      const PublicKeyCredentialCreationOptions &) = delete;
  PublicKeyCredentialCreationOptions &
  operator=(const PublicKeyCredentialCreationOptions &) = delete;

  PublicKeyCredentialCreationOptions(
      PublicKeyCredentialCreationOptions &&other);
  PublicKeyCredentialCreationOptions& operator=(PublicKeyCredentialCreationOptions &&other);

  // Setters
  void SetChallenge(const std::vector<uint8_t>& challenge);
  void SetRp(const PublicKeyCredentialRpEntity& rp);
  void SetUser(const PublicKeyCredentialUserEntity& user);
  void SetPubKeyCredParams(const std::vector<PublicKeyCredentialParameters>& params);
  void SetTimeout(uint64_t timeout);
  void SetExcludeCredentials(const std::vector<PublicKeyCredentialDescriptor>& excludeList);
  void SetAuthenticatorSelection(const AuthenticatorSelectionCriteria& selection);
  void SetAttestation(AttestationConveyancePreference attestation);

  // Getters
  const std::vector<uint8_t>& GetChallenge() const;
  const PublicKeyCredentialRpEntity& GetRp() const;
  const PublicKeyCredentialUserEntity& GetUser() const;
  const std::vector<PublicKeyCredentialParameters>& GetPubKeyCredParams() const;
  bool HasTimeout() const;
  uint64_t GetTimeout() const;
  const std::vector<PublicKeyCredentialDescriptor> &
  GetExcludeCredentials() const;
  bool HasAuthenticatorSelection() const;
  const AuthenticatorSelectionCriteria& GetAuthenticatorSelection() const;
  AttestationConveyancePreference GetAttestation() const;

  bool IsValid() const;

private:
  // Required properties
  std::vector<uint8_t> challenge_;
  PublicKeyCredentialRpEntity rp_;
  PublicKeyCredentialUserEntity user_;
  std::vector<PublicKeyCredentialParameters> pubKeyCredParams_;

  // Optional properties
  bool has_timeout_;
  uint64_t timeout_;
  std::vector<std::vector<uint8_t>> excludeCredentials_;
  bool has_authenticator_selection_;
  AuthenticatorSelectionCriteria authenticatorSelection_;
  AttestationConveyancePreference attestation_;
};

#endif // PUBLIC_KEY_CREDENTIAL_CREATION_OPTIONS_H
