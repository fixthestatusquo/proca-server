import client from './client'
import {request, admin} from '@proca/api'
import {getFormatter} from './format'
import fs from 'fs'

export async function listKeys(argv) {
  const c = client(argv)
  const fmt = getFormatter(argv)

  const {data, errors} = await request(c, admin.ListKeysDocument, {"orgName": argv.org})
  if (errors) throw errors

  data.org.keys
    .forEach((k) => {
      console.log(k)
    })
}
