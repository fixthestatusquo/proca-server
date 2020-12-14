import nacl from 'tweetnacl'
import {decodeBase64, encodeUTF8} from 'tweetnacl-util'
import base64url from 'base64url'
import {readFileSync, writeFileSync} from 'fs'
import {types} from '@proca/api'
import {CliConfig} from './config'
import {ActionMessage} from './queueMessage'

export type DecryptOpts = {
  decrypt?: boolean,
  ignore?: boolean
}

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

type mixedFormatValue = {
  private: string
} | string

type mixedFormat = Record<string, mixedFormatValue>

type fullFormatValue = {
  private: string
}

type fullFormat = Record<string, fullFormatValue>

// contact payload

export interface EncryptedContact {
  payload: string,
  nonce: string,
  publicKey: KeyPair,
  signKey: KeyPair,
  contactRef: string
}

export interface ActionWithEncryptedContact {
  contact: EncryptedContact
}

export type ContactWithPII = EncryptedContact & {
  pii?: any
}

export type ActionWithPII = Omit<types.Action, "contact"> & {
  contact: ContactWithPII,
}

function readMixedFormat(ks : KeyStore, keys : mixedFormat) {
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

  return ks
}

export function loadKeys(config : CliConfig) : KeyStore {
  if (config.keyData[0] === '{') {
    // in env-memory key list -----------------------
    const ks : KeyStore = {
      filename: null,
      readFromFile: false,
      keys: []
    }

    const kd = JSON.parse(config.keyData)
    return readMixedFormat(ks, kd)

  } else {
    // filename -------------------------------------
    const ks : KeyStore = {
      filename: config.keyData,
      readFromFile: true,
      keys: []
    }
    const kd = JSON.parse(readFileSync(ks.filename, 'utf8'))
    return readMixedFormat(ks, kd)
  }
}

export function storeKeys(ks : KeyStore) {
  let data  : fullFormat = ks.keys.reduce<fullFormat>((m, k) => {
    m[k.public] = {private: k.private}
    return m
  }, {})
  const content = JSON.stringify(data, null, 2)
  writeFileSync(ks.filename, content, {mode: 0o600})
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

export function decryptAction(action : ActionWithEncryptedContact, argv : DecryptOpts, config : CliConfig) {
  const pii = getContact(action.contact, argv, config)
  const action2 = action as ActionWithPII
  action2.contact.pii = pii
  return action2
}


export function decryptActionMessage(action : ActionMessage, argv : DecryptOpts, config : CliConfig) {
  const contact : EncryptedContact = {
    signKey: { public: action.contact.signKey},
    publicKey: { public: action.contact.publicKey},
    nonce: action.contact.nonce,
    payload: action.contact.payload,
    contactRef: action.contact.ref
  }

  const pii = getContact(contact, argv, config)
  action.contact.pii = pii
  if (!action.contact.firstName && action.contact.pii.firstName)
    action.contact.firstName = action.contact.pii.firstName
  if (!action.contact.email && action.contact.pii.email)
    action.contact.email = action.contact.pii.email
  return action
}


export function getContact(contact : EncryptedContact, argv : DecryptOpts, config : CliConfig) {
  let {payload, nonce, publicKey, signKey} = contact
  if (payload === undefined) throw new Error(`action contact has no payload: ${JSON.stringify(contact)}`)
  if (publicKey === null || publicKey === undefined) {
    // plain text
    return JSON.parse(payload)
  }

  if (!argv.decrypt)
    return {}

  const ks = loadKeys(config)

  const clear = decrypt(payload, nonce, publicKey, signKey, ks)

  if (clear === null) {
    if (argv.ignore) {
      return {}
    } else {
      throw new Error(`Cannot decrypt action data encrypted for key ${JSON.stringify(publicKey)}`)
    }
  }

  return JSON.parse(clear)
}
