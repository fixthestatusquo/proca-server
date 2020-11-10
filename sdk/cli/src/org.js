import client from './client'
import {request, admin} from '@proca/api'
import {getFormatter} from './format'
import {loadKeys, saveKeys} from './crypto'
import fs from 'fs'
import inquirer from 'inquirer'

export async function listKeys(argv, config) {
  const c = client(config)
  const fmt = getFormatter(argv)
  const keys = loadKeys(config)

  const {data, errors} = await request(c, admin.ListKeysDocument, {"org": config.org})
  if (errors) throw errors

  data.org.keys
    .forEach((k) => {
      console.log(fmt.key(k, keys))
    })
}


export async function addKey(argv, config) {
  console.log("please use proca-cli setup")
}
