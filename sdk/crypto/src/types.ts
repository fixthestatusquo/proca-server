//
// NaCL keys, always base64url encoded
export interface KeyPair {
  public: string,
  private?: string
}

export type PublicKey = {
  id: number,    // Proca id
  public: string // public key part, base64url encoded
}

// used for key store json file
export type KeyStore = {
  filename: string | null,
  readFromFile: boolean,
  keys: KeyPair[]
}

export type KeyStoreFile = {
  [key: string]: {
    private: string
  }
}

// contact payload
export interface PersonalInfo {
  payload: string, // encrypted payload, encoded base64url
  nonce: string,   // nonce bytes, encoded base64url
  encryptKey: PublicKey,
  signKey: PublicKey 
}
