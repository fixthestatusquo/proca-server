import client from './client'
import {request, admin} from '@proca/api'
import {getFormatter} from './format'
import {keys, saveKeys} from './crypto'
import fs from 'fs'
import inquirer from 'inquirer'

export async function listKeys(argv) {
  const c = client(argv)
  const fmt = getFormatter(argv)

  const {data, errors} = await request(c, admin.ListKeysDocument, {"org": argv.org})
  if (errors) throw errors

  data.org.keys
    .forEach((k) => {
      console.log(fmt.key(k))
    })
}


export async function addKey(argv) {
  const key = await inquirer.prompt([
    {type:'input', name: 'public', message: 'public key part'},
    {type:'password', name: 'private', message: 'private key part'}
  ]).catch((e) => {
    console.error(`Wrong input: ${e}`)
    return {}
  })
  const ks = keys(argv)

  if (key.public && key.private) {
    if (key.public in ks) {
      ks['#'+key.public] = ks[key.public]
    }
    ks[key.public] = {private: key.private}
    saveKeys(ks, argv.keys)
  }
}
