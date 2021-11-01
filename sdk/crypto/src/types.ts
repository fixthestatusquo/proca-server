
// keys ------
export interface KeyPair {
  public: string,
  private?: string
}

export type PublicKey = {
  id: number,
  public: string
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
  payload: string,
  nonce: string, 
  encryptKey: PublicKey,
  signKey: PublicKey 
}
