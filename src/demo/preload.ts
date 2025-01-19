import { ipcRenderer } from 'electron';
import Passkey from '..';

navigator.credentials.create = (options) =>
  Passkey.attachCreateToRenderer(ipcRenderer, options);

navigator.credentials.get = (options) =>
  Passkey.attachGetToRenderer(ipcRenderer, options);
