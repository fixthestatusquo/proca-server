
import {decrypt, KeyStore, FullFormat, readMixedFormat, EncryptedContact} from './crypto'
import {CliConfig} from './config'
import {loadKeys} from './keys'

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


export type DecryptOpts = {
  decrypt?: boolean,
  ignore?: boolean
}
