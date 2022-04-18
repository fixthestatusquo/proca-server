import {readFileSync, writeFileSync} from 'fs'
import {KeyStore, KeyStoreFile} from './types'
import {addKeysToKeyStore} from './index'

export function loadKeyStoreFromFile(filename : string) : KeyStore {
  const ks : KeyStore = {
    filename: filename,
    readFromFile: true,
    keys: []
  }
  const kd = JSON.parse(readFileSync(ks.filename, 'utf8'))
  addKeysToKeyStore(kd, ks)
  return ks
}

export function storeKeyStoreToFile(ks : KeyStore, filename : string | undefined) {
  const data = ks.keys.reduce((agg : KeyStoreFile, k) => {
    agg[k.public] = {private: k.private}
    return agg
  }, {})
  const content = JSON.stringify(data, null, 2)
  writeFileSync(filename || ks.filename, content, {mode: 0o600})
}

export function loadKeyStoreFromString(json : string) : KeyStore {
  const ks : KeyStore = {
    filename: null,
    readFromFile: false,
    keys: []
  }
  const kd = JSON.parse(json)
  addKeysToKeyStore(kd, ks)
  return ks
}
