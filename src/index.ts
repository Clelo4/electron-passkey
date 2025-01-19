import { join } from 'node:path';
import os from 'node:os';
import type { IpcMain, IpcRenderer } from 'electron';
import type {
  PasskeyInterface,
  PasskeyHandler,
  PublicKeyCredentialRequestOptions,
  PublicKeyCredentialCreationOptions,
} from './types';
import { mapPublicKey, PassKeyMethods } from './utils';

const lib: PasskeyInterface = require('node-gyp-build')(join(__dirname, '..'));

class Passkey {
  private static instance: Passkey;

  private handler: PasskeyHandler;

  private platform = os.platform();

  private constructor() {
    this.handler = new lib.PasskeyHandler(); // Create an instance of PasskeyHandler
  }

  private handlePasskeyCreate(options: PublicKeyCredentialCreationOptions): Promise<string> {
    if (this.platform !== 'darwin') {
      throw new Error(
        `electron-passkey is meant for macOS only and should NOT be run on ${this.platform}`,
      );
    }

    return this.handler.HandlePasskeyCreate(options);
  }

  private handlePasskeyGet(options: PublicKeyCredentialRequestOptions): Promise<string> {
    if (this.platform !== 'darwin') {
      throw new Error(
        `electron-passkey is meant for macOS only and should NOT be run on ${this.platform}`,
      );
    }

    return this.handler.HandlePasskeyGet(options);
  }

  attachHandlersToMain(ipcMain: IpcMain): void {
    ipcMain.handle(PassKeyMethods.createPasskey, (_event, options) =>
      this.handlePasskeyCreate(options),
    );
    ipcMain.handle(PassKeyMethods.getPasskey, (_event, options) =>
      this.handlePasskeyGet(options),
    );
  }

  // Singleton pattern: ensures only one instance is created
  static getInstance(): Passkey {
    if (!Passkey.instance) {
      Passkey.instance = new Passkey();
    }
    return Passkey.instance;
  }

  static getPackageName(): string {
    return 'electron-passkey';
  }

  static async attachCreateToRenderer(
    ipcRenderer: IpcRenderer,
    options?: CredentialCreationOptions,
  ): Promise<PublicKeyCredential> {
    const rawString: string = await ipcRenderer.invoke(
      PassKeyMethods.createPasskey,
      options?.publicKey,
    );
    return mapPublicKey(rawString, true);
  }

  static async attachGetToRenderer(
    ipcRenderer: IpcRenderer,
    options?: CredentialRequestOptions,
  ): Promise<PublicKeyCredential> {
    const rawString: string = await ipcRenderer.invoke(
      PassKeyMethods.getPasskey,
      options?.publicKey,
    );
    return mapPublicKey(rawString, false);
  }
}

export = Passkey;
