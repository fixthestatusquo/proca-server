
import dotenv from 'dotenv'
import {writeFileSync} from 'fs'

export type CliConfig = {
  org?: string,
  username?: string,
  password?: string,
  queue_url?: string,
  identity_url?: string,
  identity_api_token?: string,
  identity_consent?: string,
  identity_action_fields?: string[],
  identity_contact_fields?: string[],
  service_url?: string,
  url: string,
  keyData?: string,
  envFile?: boolean,
  verbose?: boolean
}

export function load() {
  const {parsed} = dotenv.config()
  const config : CliConfig = loadFromEnv(process.env)
  // was env file loaded?
  config.envFile = parsed !== undefined
  return config
}

export function loadFromEnv(env = process.env)  {

  const config : CliConfig = {
    org: env["ORG_NAME"],
    username: env["AUTH_USER"],
    password: env["AUTH_PASSWORD"],
    queue_url: env["QUEUE_URL"] || 'amqp://api.proca.app/proca',
    identity_url: env["IDENTITY_URL"],
    identity_api_token: env["IDENTITY_API_TOKEN"],
    identity_consent: env["IDENTITY_CONSENT"],
    identity_action_fields: (env["IDENTITY_ACTION_FIELDS"] || '').toLowerCase().split(','),
    identity_contact_fields: (env["IDENTITY_CONTACT_FIELDS"] || '').toLowerCase().split(','),
    service_url: env["SERVICE_URL"] || env["IDENTITY_URL"],
    url: env["API_URL"] || 'https://api.proca.app',
    keyData: env["KEYS"] || 'keys.json',
    envFile: false,
    verbose: false
  }
  return config
}

export function storeConfig(config : CliConfig, file_name : string) {
  let data = ''

  const vars = {
    'ORG_NAME': config.org,
    'AUTH_USER': config.username,
    'AUTH_PASSWORD': config.password,
    'API_URL': config.url,
    'QUEUE_URL': config.queue_url,
    'IDENTITY_URL': config.identity_url,
    'IDENTITY_API_TOKEN': config.identity_api_token,
    'IDENTITY_CONSENT': config.identity_consent,
    'IDENTITY_ACTION_FIELDS': config.identity_action_fields ? config.identity_action_fields.join(",") : null,
    'IDENTITY_CONTACT_FIELDS': config.identity_contact_fields ? config.identity_contact_fields.join(",") : null,
    'SERVICE_URL': config.service_url,
    'KEYS': config.keyData
  }

  for (let [k, v] of Object.entries(vars)) {
    if (v) {
      data += `${k}=${v}\n`
    }
  }

  writeFileSync(file_name, data)
}


export type WidgetConfig = {
  actionpage: number,
  lang: string,
  journey: string[],
  filename: string,
  organisation: string
}
