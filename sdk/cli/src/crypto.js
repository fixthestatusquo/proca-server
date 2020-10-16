import nacl from 'tweetnacl'
import {decodeBase64, encodeUTF8} from 'tweetnacl-util'
import base64url from 'base64url'
import fs from 'fs'

export function loadKeys(filename) {
  return JSON.parse(fs.readFileSync(filename, 'utf8'))
}

export function saveKeys(keys, filename) {
  const content = JSON.stringify(keys)
  fs.writeFileSync(filename)
}




function fromBase64(s) {
  return decodeBase64(base64url.toBase64(s))
}

export function decrypt(payloads_with_nonces, sender_pk, config) {
  const my_priv = fromBase64(config.keys[0].priv)
  const sender_pub = fromBase64(sender_pk)

  return payloads_with_nonces.map(([p, n]) => {
    // not encrypted
    if (n === null) {
      return p;
    }

    // decrypt
    const clear = nacl.box.open(fromBase64(p), fromBase64(n), sender_pub, my_priv)
    if (clear === null) {
      return null;
    } else {
      return encodeUTF8(clear)
    }
  })
}

export function decryptOne(payload, nonce, public_key, sign_key, config) {
  if (nonce === null || nonce === undefined) {
    return payload
  }

  const my_priv = fromBase64(config.keys[0].priv)
  sign_key = fromBase64(sign_key)

  // decrypt
  const clear = nacl.box.open(fromBase64(payload), fromBase64(nonce), sign_key, my_priv)
  if (clear === null) {
    return null;
  } else {
    return encodeUTF8(clear)
  }
}

export function decryptSignatures({list, publicKey}, config) {
  decrypt(
    list.map(({contact, nonce}) => [contact, nonce]),
    publicKey, config
  ).map((clear_contact, idx) => {
    if (clear_contact !== null) {
      list[idx].contact = JSON.parse(clear_contact)
      list[idx].nonce = null
    }
  })
  return list
}

export function decryptAction(action, config) {
  const contact = action.contact;
  const clear_contact = decryptOne(contact.payload, contact.nonce, contact.publicKey, contact.signKey, config)
  contact.pii = JSON.parse(clear_contact)
  return action
}
