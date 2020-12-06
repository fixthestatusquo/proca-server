import client from './client'
import {request, admin} from '@proca/api'
import {getFormatter,FormatOpts} from './format'
import {loadKeys} from './crypto'
import {CliConfig} from 'config'

export async function listKeys(argv : FormatOpts, config : CliConfig) {
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


export async function addKey(_opts : FormatOpts, _config : CliConfig) {
  console.log("please use proca-cli setup")
}
