import { CliConfig } from './config';
import { types } from '@proca/api';
declare type DecryptOpts = {
    decrypt: boolean;
    ignore: boolean;
};
export declare type KeyPair = {
    public: string;
    private?: string;
};
export declare type KeyStore = {
    filename: string | null;
    readFromFile: boolean;
    keys: KeyPair[];
};
export declare function loadKeys(config: CliConfig): KeyStore;
export declare function storeKeys(ks: KeyStore): void;
export declare function decrypt(payload: string, nonce: string, public_key: KeyPair, sign_key: KeyPair, keys: KeyStore): string;
export declare type ContactWithPII = types.Contact & {
    pii?: any;
};
export declare type ActionWithPII = Omit<types.Action, "contact"> & {
    contact: ContactWithPII;
};
export declare function decryptAction(action: types.Action, argv: DecryptOpts, config: CliConfig): ActionWithPII;
export declare function getContact(contact: types.Contact, argv: DecryptOpts, config: CliConfig): any;
export {};
