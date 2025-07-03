export interface KeyPair {
    public: string;
    private?: string;
}
export declare type PublicKey = {
    id: number;
    public: string;
};
export declare type KeyStore = {
    filename: string | null;
    readFromFile: boolean;
    keys: KeyPair[];
};
export declare type KeyStoreFile = {
    [key: string]: {
        private: string;
    };
};
export interface PersonalInfo {
    payload: string;
    nonce: string;
    encryptKey: PublicKey;
    signKey: PublicKey;
}
