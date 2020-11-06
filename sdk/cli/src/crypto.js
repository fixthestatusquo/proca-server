import nacl from 'tweetnacl'
import {decodeBase64, encodeUTF8} from 'tweetnacl-util'
import base64url from 'base64url'
import fs from 'fs'

export function keys(argv) {
  let ks = null;
  if (argv.keys) {
    if (argv.keys[0] === '{') {
      ks = JSON.parse(argv.keys)
    } else {
      ks = loadKeys(argv.keys)
    }
  }

  for (const pub of Object.keys(ks)) {
    if (typeof ks[pub] === "string") {
      ks[pub] = { private: ks[pub] }
    }
  }

  return ks
}

function loadKeys(filename) {
  try {
  return JSON.parse(fs.readFileSync(filename, 'utf8'))
  } catch (e) {
    if (e.code == 'ENOENT') return {}
    throw e
  }
}

export function saveKeys(keys, filename) {
  if (typeof keys !== 'object') throw `Trying to save non invalid keys map ${keys}`
  if (Object.keys(keys) == 0) throw `Trying to save empty key map ${keys}`
  const content = JSON.stringify(keys, null, 2)
  fs.writeFileSync(filename, content, {mode: 0o600})
}


function base64url2normal(s) {
  return decodeBase64(base64url.toBase64(s))
}

export function decrypt(payload, nonce, public_key, sign_key, keys) {
  if (nonce === null || nonce === undefined) {
    return payload // decrypted
  }

  let priv = keys[public_key]

  if (!priv) {
    return null // cannot decrypt
  }

  priv = base64url2normal(priv.private)
  const pub = base64url2normal(sign_key)

  // decrypt
  const clear = nacl.box.open(base64url2normal(payload), base64url2normal(nonce), pub, priv)
  if (clear === null) {
    return null;
  } else {
    return encodeUTF8(clear)
  }
}

export function decryptAction(action, argv) {
  const pii = getContact(action.contact, argv)
  action.contact.pii = pii
  return action
}

export function getContact(contact, argv) {
  let {payload, nonce, publicKey, signKey} = contact
  if (payload === undefined) return {}
  if (publicKey === null || publicKey === undefined) {
    // plain text
    return JSON.parse(payload)
  }

  if (!argv.decrypt)
    return {}

  const k = keys(argv)
  if (k === null)
    return {}

  publicKey = publicKey.public || publicKey
  signKey = signKey.public || signKey

  const clear = decrypt(payload, nonce, publicKey, signKey, k)

  if (clear === null)
    return {}

  return JSON.parse(clear)
}
