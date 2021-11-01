import { KeyStore, PersonalInfo } from './types';
export { KeyStore, PersonalInfo } from './types';
export declare function addKeysToKeyStore(keys: any, ks: KeyStore): true;
export declare function decodeBase64url(s: string): Uint8Array;
export declare function decryptPersonalInfo(pii: PersonalInfo | undefined, keyStore: KeyStore): any;
export declare function decrypt(ciphertext: string, nonce: string, encPriv: string, signPub: string): string;
