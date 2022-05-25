import nacl from 'tweetnacl'
import {decodeBase64, encodeUTF8} from 'tweetnacl-util'
import base64url from 'base64url'
import lo from "lodash"
import {KeyStore, PersonalInfo} from './types'
export {PublicKey, KeyStore, PersonalInfo} from './types'
export {loadKeyStoreFromFile, storeKeyStoreToFile, loadKeyStoreFromString} from './utils'

type KeyJson = {
  private?: string
}

export function addKeysToKeyStore(keys: any, ks : KeyStore) : true  {
  if (typeof keys !== "object") 
    throw new Error("key store must be object")

  for (let [key, value] of Object.entries(keys as Record<string, KeyJson>)) {
    if (typeof key !== "string")
      throw new Error("keys must be a map keyed by public key")

    if (typeof value === "object" && 
        'private' in value && 
         typeof value.private === "string") {
      ks.keys.push({public: key, private: value.private})
    } else {
        throw new Error("keys must be a map with values containing private key")
    }
  }

  ks.keys = lo.uniqBy(ks.keys, "public")
  return true 
}

export function decodeBase64url(s : string) {
  return decodeBase64(base64url.toBase64(s))
}

export function decryptPersonalInfo(pii : PersonalInfo | undefined, keyStore : KeyStore) : any {
  if (!pii) {
    return {} // decrypted
  }

  if (!(pii.encryptKey && pii.signKey && pii.nonce)) {
    throw new Error("Tried to decrypt a payload providing null public_key or sign_key")
  }

  const privIdx = keyStore.keys.findIndex((k) => k.public == pii.encryptKey.public)
  if (privIdx < 0) return null;

  const privPair = keyStore.keys[privIdx]

  const clear = decrypt(pii.payload, pii.nonce,privPair.private, pii.signKey.public)
  return JSON.parse(clear)
}

// decrypt and verify a payload with nonce, encryption key private side, signing key public side
export function decrypt(ciphertext : string, nonce : string, encPriv : string, signPub : string) : string {
  const priv = decodeBase64url(encPriv)
  const pub = decodeBase64url(signPub)
  const n = decodeBase64url(nonce)
  const p = decodeBase64url(ciphertext)

  // decrypt
  const clear = nacl.box.open(p, n, pub, priv)
  if (clear === null) {
    throw new Error(`decrypting ciphertext returned null (ciphertext ${ciphertext})`)
  } else {
    return encodeUTF8(clear)
  }
}
