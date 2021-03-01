import nacl from 'tweetnacl'
import {decodeBase64, encodeUTF8} from 'tweetnacl-util'
import base64url from 'base64url'
import {types} from '@proca/api'
import lo from "lodash";

// keys ------
export type KeyPair = {
  public: string,
  private?: string
}

export type KeyStore = {
  filename: string | null,
  readFromFile: boolean,
  keys: KeyPair[]
}

type MixedFormatValue = {
  private: string
} | string

export type MixedFormat = Record<string, MixedFormatValue>

type FullFormatValue = {
  private: string
}

export type FullFormat = Record<string, FullFormatValue>

// contact payload

export interface EncryptedContact {
  payload: string,
  nonce?: string
  publicKey?: KeyPair
  signKey?: KeyPair
  contactRef: string
}

// action with 
export interface ActionWithEncryptedContact {
  contact: EncryptedContact
}

export type ContactWithPII = EncryptedContact & {
  pii?: any
}

export interface ActionWithPII {
  contact: ContactWithPII
}

export function readMixedFormat(ks : KeyStore, keys : MixedFormat) {
  for (let [key, value] of Object.entries(keys)) {
    if (typeof key !== "string")
      throw new Error("keys must be a map keyed by public key")

    if (typeof value == "string")
      ks.keys.push({public: key, private: value})

    if (typeof value == "object") {
      if (typeof value.private !== "string")
        throw new Error("keys must be a map with values containing private key")

      ks.keys.push({public: key, private: value.private})
    }
  }

  ks.keys = lo.uniqBy(ks.keys, "public")

  return ks
}




function base64url2normal(s : string) {
  return decodeBase64(base64url.toBase64(s))
}

export function decrypt(payload: string, nonce: string, public_key: KeyPair, sign_key: KeyPair, keys : KeyStore) {
  if (!nonce) {
    return payload // decrypted
  }

  if (!(public_key && sign_key)) {
    throw new Error("Tried to decrypt a payload providing null public_key or sign_key")
  }

  const privIdx = keys.keys.findIndex((k) => k.public == public_key.public)
  if (privIdx < 0) return null;

  const privPair = keys.keys[privIdx]

  const priv = base64url2normal(privPair.private)
  const pub = base64url2normal(sign_key.public)

  // decrypt
  const clear = nacl.box.open(base64url2normal(payload), base64url2normal(nonce), pub, priv)
  if (clear === null) {
    throw new Error(`decrypting payload returned null (payload ${payload})`)
  } else {
    return encodeUTF8(clear)
  }
}



