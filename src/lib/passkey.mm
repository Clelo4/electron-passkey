#import "passkey.h"
#include <stdexcept>
#include <exception>
#include "napi.h"
#include "PublicKeyCredentialCreationOptions.h"
#include "PublicKeyCredentialRequestOptions.h"
#include "utils.h"
#include <iostream>
#import <Foundation/Foundation.h>
#import <dispatch/dispatch.h>
#import <AuthenticationServices/AuthenticationServices.h>

typedef void (^PasskeyCompletionHandler)(NSString *resultMessage, NSString *errorMessage);

NSData* ConvertBufferToNSData(Napi::Buffer<uint8_t> buffer) {
    return [NSData dataWithBytes:buffer.Data() length:buffer.Length()];
}

@interface PasskeyHandlerObjC : NSObject <ASAuthorizationControllerDelegate, ASAuthorizationControllerPresentationContextProviding>

@property (nonatomic, strong) PasskeyCompletionHandler completionHandler;

- (void)PerformCreateRequest:(const PublicKeyCredentialCreationOptions &)options withCompletionHandler:(PasskeyCompletionHandler)completionHandler;
- (void)PerformGetRequest:(const PublicKeyCredentialRequestOptions&)options withCompletionHandler:(PasskeyCompletionHandler)completionHandler;

@end

@implementation PasskeyHandlerObjC

- (instancetype)init {
    self = [super init];
    return self;
}

- (void)PerformCreateRequest:(const PublicKeyCredentialCreationOptions &)options withCompletionHandler:(PasskeyCompletionHandler)completionHandler {
    self.completionHandler = completionHandler;

    if (@available(macOS 12.0, *)) {
      NSString *rpId = ToNSString(options.GetRp().id);
      NSString *userName = ToNSString(options.GetUser().name);
      NSData *userId = ToNSData(options.GetUser().id);
      NSData *challenge = ToNSData(options.GetChallenge());

        ASAuthorizationPlatformPublicKeyCredentialProvider *provider =
            [[ASAuthorizationPlatformPublicKeyCredentialProvider alloc] initWithRelyingPartyIdentifier:rpId];
    
        ASAuthorizationPlatformPublicKeyCredentialRegistrationRequest *request =
            [provider createCredentialRegistrationRequestWithChallenge:challenge name:userName userID:userId];

        if (options.HasAuthenticatorSelection()) {
            // NSString *attachment = authenticatorSelection[@"authenticatorAttachment"];
            // if ([attachment isEqualToString:@"platform"]) {
            //     request.authenticatorAttachment = ASAuthorizationPublicKeyCredentialAttachmentPlatform;
            // } else if ([attachment isEqualToString:@"cross-platform"]) {
            //     request.authenticatorAttachment = ASAuthorizationPublicKeyCredentialAttachmentCrossPlatform;
            // }

            NSString *userVerification = authenticatorSelection[@"userVerification"];
            if ([userVerification isEqualToString:@"required"]) {
                request.userVerificationPreference = ASAuthorizationPublicKeyCredentialUserVerificationPreferenceRequired;
            } else if ([userVerification isEqualToString:@"preferred"]) {
                request.userVerificationPreference = ASAuthorizationPublicKeyCredentialUserVerificationPreferencePreferred;
            } else if ([userVerification isEqualToString:@"discouraged"]) {
                request.userVerificationPreference = ASAuthorizationPublicKeyCredentialUserVerificationPreferenceDiscouraged;
            }
        }

        ASAuthorizationController *controller =
            [[ASAuthorizationController alloc] initWithAuthorizationRequests:@[request]];

        controller.delegate = self;
        controller.presentationContextProvider = self;

        NSLog(@"[PerformCreateRequest]: Delegate and PresentationContextProvider set. Starting requests...");

        [controller performRequests];
    } else {
        NSLog(@"[PerformCreateRequest]: Your macOS version does not support WebAuthn APIs.");
        if (completionHandler) {
            completionHandler(nil, @"macOS version not supported");
        }
    }
}

- (void)PerformGetRequest:(const PublicKeyCredentialRequestOptions&)options withCompletionHandler:(PasskeyCompletionHandler)completionHandler {
    self.completionHandler = completionHandler;

    if (@available(macOS 12.0, *)) {
        NSDictionary *publicKeyOptions = options[@"publicKey"];
        NSString *rpId = publicKeyOptions[@"rpId"];
        NSData *challenge = publicKeyOptions[@"challenge"];

        ASAuthorizationPlatformPublicKeyCredentialProvider *provider =
            [[ASAuthorizationPlatformPublicKeyCredentialProvider alloc] initWithRelyingPartyIdentifier:rpId];

        ASAuthorizationPlatformPublicKeyCredentialAssertionRequest *request =
            [provider createCredentialAssertionRequestWithChallenge:challenge];

        NSArray *allowCredentials = publicKeyOptions[@"allowCredentials"];
        if (allowCredentials) {
            NSMutableArray<ASAuthorizationPlatformPublicKeyCredentialDescriptor *> *credentials = [NSMutableArray array];
            for (NSDictionary *cred in allowCredentials) {
                NSString *credId = cred[@"id"];
                NSData *credIdData = [[NSData alloc] initWithBase64EncodedString:credId options:0];
                ASAuthorizationPlatformPublicKeyCredentialDescriptor *descriptor = [[ASAuthorizationPlatformPublicKeyCredentialDescriptor alloc] initWithCredentialID:credIdData];
                [credentials addObject:descriptor];
            }
            request.allowedCredentials = credentials;
        }

        NSString *userVerification = publicKeyOptions[@"userVerification"];
        if ([userVerification isEqualToString:@"required"]) {
            request.userVerificationPreference = ASAuthorizationPublicKeyCredentialUserVerificationPreferenceRequired;
        } else if ([userVerification isEqualToString:@"preferred"]) {
            request.userVerificationPreference = ASAuthorizationPublicKeyCredentialUserVerificationPreferencePreferred;
        } else if ([userVerification isEqualToString:@"discouraged"]) {
            request.userVerificationPreference = ASAuthorizationPublicKeyCredentialUserVerificationPreferenceDiscouraged;
        }

        ASAuthorizationController *controller =
            [[ASAuthorizationController alloc] initWithAuthorizationRequests:@[request]];

        controller.delegate = self;
        controller.presentationContextProvider = self;

        NSLog(@"[PerformGetRequest]: Delegate and PresentationContextProvider set. Starting requests...");

        [controller performRequests];
    } else {
        NSLog(@"[PerformGetRequest]: Your macOS version does not support WebAuthn APIs.");
        if (completionHandler) {
            completionHandler(nil, @"macOS version not supported");
        }
    }
}

- (void)authorizationController:(ASAuthorizationController *)controller didCompleteWithAuthorization:(ASAuthorization *)authorization {
    NSLog(@"[authorizationController didCompleteWithAuthorization]: Success");
    
    if ([authorization.credential isKindOfClass:[ASAuthorizationPlatformPublicKeyCredentialRegistration class]]) {
        NSLog(@"[authorizationController didCompleteWithAuthorization]: Creating credentials");
        ASAuthorizationPlatformPublicKeyCredentialRegistration *credential = (ASAuthorizationPlatformPublicKeyCredentialRegistration *)authorization.credential;
        
        NSData *clientDataJSON = credential.rawClientDataJSON;
        NSData *attestationObject = credential.rawAttestationObject;
        NSString *credentialId = [credential.credentialID base64EncodedStringWithOptions:0];
        
        NSDictionary *responseDict = @{
            @"clientDataJSON": [clientDataJSON base64EncodedStringWithOptions:0],
            @"attestationObject": [attestationObject base64EncodedStringWithOptions:0]
        };
        
        // Assemble the PublicKeyCredential object structure
        NSDictionary *publicKeyCredentialDict = @{
            @"id": credentialId, // id is the base64-encoded credential ID
            @"type": @"public-key", // Fixed value for PublicKeyCredential
            @"rawId": credentialId, // rawId is the raw NSData representing the credential ID
            @"response": responseDict, // The response object
            @"clientExtensionResults": @{}, // An empty dictionary, as no extensions are used in this example
            @"transports": @[] // Transports are not directly available in ASAuthorizationPlatformPublicKeyCredentialRegistration
        };
        
        if (![NSJSONSerialization isValidJSONObject:publicKeyCredentialDict]) {
            if (self.completionHandler) {
                self.completionHandler(nil, @"Invalid arguments to create");
                return;
            }
        }

        NSError *error = nil;
        NSData *responseData = [NSJSONSerialization dataWithJSONObject:publicKeyCredentialDict options:0 error:&error];

        if (error) {
            NSLog(@"[authorizationController didCompleteWithAuthorization]: Failed to serialize response: %@", error.localizedDescription);
            if (self.completionHandler) {
                self.completionHandler(nil, error.localizedDescription);
            }
        } else {
            NSString *resultMessage = [[NSString alloc] initWithData:responseData encoding:NSUTF8StringEncoding];
            if (self.completionHandler) {
                self.completionHandler(resultMessage, nil);
            }
        }
    } else if ([authorization.credential isKindOfClass:[ASAuthorizationPlatformPublicKeyCredentialAssertion class]]) {
        NSLog(@"[authorizationController didCompleteWithAuthorization]: Getting credentials");
        ASAuthorizationPlatformPublicKeyCredentialAssertion *credential = (ASAuthorizationPlatformPublicKeyCredentialAssertion *)authorization.credential;

        NSString *credentialId = [credential.credentialID base64EncodedStringWithOptions:0];

        // Create the "response" dictionary, simulating the AuthenticatorAssertionResponse
        NSDictionary *responseDict = @{
            @"clientDataJSON": [credential.rawClientDataJSON base64EncodedStringWithOptions:0],
            @"authenticatorData": [credential.rawAuthenticatorData base64EncodedStringWithOptions:0],
            @"signature": [credential.signature base64EncodedStringWithOptions:0],
            @"userHandle": credential.userID ? [credential.userID base64EncodedStringWithOptions:0] : [NSNull null]
        };
        
        // Assemble the PublicKeyCredential object structure
        NSDictionary *publicKeyCredentialDict = @{
            @"id": credentialId, // id is the base64-encoded credential ID
            @"type": @"public-key", // Fixed value for PublicKeyCredential
            @"rawId": credentialId, // rawId is the base64-encoded credential ID
            @"response": responseDict, // The response object
            @"clientExtensionResults": @{}, // An empty dictionary, as no extensions are used in this example
            @"transports": @[] // Transports are not directly available in ASAuthorizationPlatformPublicKeyCredentialAssertion
        };

        if (![NSJSONSerialization isValidJSONObject:publicKeyCredentialDict]) {
            if (self.completionHandler) {
                self.completionHandler(nil, @"Invalid arguments to get");
                return;
            }
        }

        // Serialize the PublicKeyCredential object into JSON
        NSError *error = nil;
        NSData *responseData = [NSJSONSerialization dataWithJSONObject:publicKeyCredentialDict options:0 error:&error];
        if (error) {
            NSLog(@"[authorizationController didCompleteWithAuthorization]: Failed to serialize response: %@", error.localizedDescription);
            if (self.completionHandler) {
                self.completionHandler(nil, error.localizedDescription);
            }
        } else {
            NSString *resultMessage = [[NSString alloc] initWithData:responseData encoding:NSUTF8StringEncoding];
            if (self.completionHandler) {
                self.completionHandler(resultMessage, nil);
            }
        }
    } else {
        NSLog(@"[authorizationController didCompleteWithAuthorization]: Unsupported credential type");
        if (self.completionHandler) {
            self.completionHandler(nil, @"Unsupported credential type");
        }
    }
}

- (void)authorizationController:(ASAuthorizationController *)controller didCompleteWithError:(NSError *)error {
    NSLog(@"[authorizationController didCompleteWithError]: Error: %@", error.localizedDescription);

    if (self.completionHandler) {
        self.completionHandler(nil, error.localizedDescription);
    }
}

- (ASPresentationAnchor)presentationAnchorForAuthorizationController:(ASAuthorizationController *)controller {
    NSWindow *mainWindow = [NSApplication sharedApplication].keyWindow;
    if (!mainWindow) {
        mainWindow = [NSApplication sharedApplication].windows.firstObject;
    }
    
    if (mainWindow) {
        NSLog(@"[presentationAnchorForAuthorizationController]: Returning main window as presentation anchor.");
        return mainWindow;
    } else {
        NSLog(@"[presentationAnchorForAuthorizationController]: Error: No valid presentation anchor available.");
        return nil;
    }
}

@end

NSDictionary* ConvertStringToNSDictionary(const std::string& str) {
    if (str.empty()) {
        NSLog(@"[ConvertStringToNSDictionary]: Empty string provided to ConvertStringToNSDictionary");
        return nil;
    }

    NSData* jsonData = [NSData dataWithBytes:str.c_str() length:str.size()];
    if (!jsonData) {
        NSLog(@"[ConvertStringToNSDictionary]: Failed to convert string to NSData");
        return nil;
    }

    NSError* error = nil;
    NSDictionary* dict = [NSJSONSerialization JSONObjectWithData:jsonData options:0 error:&error];
    
    if (error) {
        NSLog(@"[ConvertStringToNSDictionary]: Failed to convert NSData to NSDictionary: %@", error.localizedDescription);
        return nil;
    }

    return dict;
}

class PasskeyHandler::Impl {
public:
    Impl() {
        handlerObjC = [[PasskeyHandlerObjC alloc] init];  // Use Objective-C allocation
    }

    ~Impl() {
        // ARC handles memory management, so no need to manually delete or release
    }

    Napi::Value HandlePasskeyCreate(Napi::Env env, const PublicKeyCredentialCreationOptions& creationOptions) {
        auto deferred = Napi::Promise::Deferred::New(env);

        [handlerObjC PerformCreateRequest:creationOptions withCompletionHandler:^(NSString *resultMessage, NSString *errorMessage) {
            Napi::HandleScope scope(env);

            if (errorMessage != nil) {
                deferred.Reject(Napi::TypeError::New(env, std::string([errorMessage UTF8String])).Value());
            } else if (resultMessage == nil) {
                deferred.Reject(Napi::TypeError::New(env, "[HandlePasskeyCreate]: Result message is nil").Value());
            } else {
                deferred.Resolve(Napi::String::New(env, std::string([resultMessage UTF8String])));
            }
        }];

        return deferred.Promise();
    }

    Napi::Value HandlePasskeyGet(Napi::Env env, const PublicKeyCredentialRequestOptions& requestOptions) {
        auto deferred = Napi::Promise::Deferred::New(env);

        [handlerObjC PerformGetRequest:requestOptions withCompletionHandler:^(NSString *resultMessage, NSString *errorMessage) {
            Napi::HandleScope scope(env);

            if (errorMessage != nil) {
                deferred.Reject(Napi::TypeError::New(env, std::string([errorMessage UTF8String])).Value());
            } else if (resultMessage == nil) {
                deferred.Reject(Napi::TypeError::New(env, "[HandlePasskeyGet]: Result message is nil").Value());
            } else {
                deferred.Resolve(Napi::String::New(env, std::string([resultMessage UTF8String])));
            }
        }];

        return deferred.Promise();
    }

private:
    PasskeyHandlerObjC* handlerObjC;
};

PasskeyHandler::PasskeyHandler(const Napi::CallbackInfo& info)
    : Napi::ObjectWrap<PasskeyHandler>(info), impl_(std::make_unique<Impl>()) {
    // Constructor
}

PasskeyHandler::~PasskeyHandler() = default;

Napi::Value
PasskeyHandler::HandlePasskeyCreate(const Napi::CallbackInfo &info) {
    Napi::Env env = info.Env();
    try {
      if (info.Length() < 1 || !info[0].IsObject()) {
        throw std::invalid_argument("Expected object as first argument");
      }

      Napi::Object jsOptions = info[0].As<Napi::Object>();
      PublicKeyCredentialCreationOptions createOptons = ParseCreateOptions(jsOptions);

      return impl_->HandlePasskeyCreate(info.Env(), createOptons);
    } catch (const std::exception &e) {
      Napi::Error::New(env, e.what()).ThrowAsJavaScriptException();
      return env.Undefined();
    }
}

Napi::Value PasskeyHandler::HandlePasskeyGet(const Napi::CallbackInfo &info) {
  Napi::Env env = info.Env();

  try {
    if (info.Length() < 1 || !info[0].IsObject()) {
      throw std::invalid_argument("Expected object as first argument");
    }

    Napi::Object jsOptions = info[0].As<Napi::Object>();
    PublicKeyCredentialRequestOptions requestOptions = ParseRequestOptions(jsOptions);

    return impl_->HandlePasskeyGet(info.Env(), requestOptions);
  } catch (const std::exception &e) {
    Napi::Error::New(env, e.what()).ThrowAsJavaScriptException();
    return env.Undefined();
  }
}

Napi::Object PasskeyHandler::Init(Napi::Env env, Napi::Object exports) {
    Napi::Function func = DefineClass(env, "PasskeyHandler", {
        InstanceMethod("HandlePasskeyCreate", &PasskeyHandler::HandlePasskeyCreate),
        InstanceMethod("HandlePasskeyGet", &PasskeyHandler::HandlePasskeyGet),
    });

    exports.Set("PasskeyHandler", func);
    return exports;
}

Napi::Object InitAll(Napi::Env env, Napi::Object exports) {
    return PasskeyHandler::Init(env, exports);
}

NODE_API_MODULE(passkey, InitAll);
