
import {readFileSync, writeFileSync} from 'fs'
import {KeyStore, FullFormat, readMixedFormat, EncryptedContact} from './crypto'
import {CliConfig} from './config'

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
  let data  : FullFormat = ks.keys.reduce<FullFormat>((m, k) => {
    m[k.public] = {private: k.private}
    return m
  }, {})
  const content = JSON.stringify(data, null, 2)
  writeFileSync(ks.filename, content, {mode: 0o600})
}

