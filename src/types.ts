export interface PublicKeyCredentialCreationOptions {
  attestation?: 'none' | 'indirect' | 'direct' | 'enterprise';
  authenticatorSelection?: {
    authenticatorAttachment?: 'platform' | 'cross-platform';
    requireResidentKey?: boolean;
    userVerification?: 'required' | 'preferred' | 'discouraged';
  };
  rp: {
    id: string;
    name: string;
  };
  user: {
    id: BufferSource;
    name: string;
    displayName: string;
  };
  challenge: BufferSource;
  pubKeyCredParams: Array<{
    type: string;
    alg: number;
  }>;
  timeout?: number;
  extensions?: AuthenticationExtensionsClientInputs;
}

type ExtendedAuthenticatorTransport = AuthenticatorTransport | 'smart-card';

interface CredentialDescriptor {
  id: string;
  transports: ExtendedAuthenticatorTransport[];
}

export interface PublicKeyCredentialRequestOptions {
  rpId?: string;
  challenge: ArrayBufferView | ArrayBuffer;
  allowCredentials?: Array<CredentialDescriptor>;
  userVerification?: 'required' | 'preferred' | 'discouraged';
  timeout?: number;
  extensions?: AuthenticationExtensionsClientInputs;
}

export interface PasskeyOptions {
  publicKey:
    | PublicKeyCredentialCreationOptions
    | PublicKeyCredentialRequestOptions;
  mediation?: 'conditional';
  signal?: AbortSignal;
}

export interface PasskeyHandler {
  HandlePasskeyCreate(options: PublicKeyCredentialCreationOptions): Promise<string>;
  HandlePasskeyGet(options: PublicKeyCredentialRequestOptions): Promise<string>;
}

export interface PasskeyInterface {
  PasskeyHandler: new () => PasskeyHandler;
}
