import client from './client'
import {request,  types} from '@proca/api'
import * as admin from "./proca"
import {getFormatter,FormatOpts} from './format'
import {loadKeys} from './keys'
import {CliConfig} from './config'

function loadOrCreateKeys(config : CliConfig) {
  try {
    return loadKeys(config)
  } catch {
    return {
      filename: config.keyData,
      readFromFile: false,
      keys: []
    }
  }
}


export async function listKeys(argv : FormatOpts, config : CliConfig) {
  const c = client(config)
  const fmt = getFormatter(argv)
  const keys = loadOrCreateKeys(config)

  const {data, error} = await request(c, admin.ListKeysDocument, {"org": config.org})
  if (error) throw error
  data.org.keys
    .forEach((k) => {
      console.log(fmt.key(k, keys))
    })
}


export async function addKey(_opts : FormatOpts, _config : CliConfig) {
  console.log("please use proca-cli setup")
}

interface AddOrgOpts {
  name?: string,
  title?: string,
  schema?: string
}

function contactSchemaFromString(value : string) : admin.ContactSchema | undefined {
  return Object.values(admin.ContactSchema).find((v) => value == v)
}

export async function addOrg(argv : AddOrgOpts & FormatOpts, config : CliConfig) {
  const c = client(config)
  const fmt = getFormatter(argv)

  const org = {
    name: argv.name,
    title: argv.title,
    contactSchema: contactSchemaFromString(argv.schema.toUpperCase())
  }
  console.log(org)
  const {data, error} = await request(c, admin.AddOrgDocument, {org})

  if (error) throw error

  console.log(`Added org ${data.addOrg.name}`)

}
