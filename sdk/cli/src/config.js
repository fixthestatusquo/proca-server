
import dotenv from 'dotenv'
import inquirer from 'inquirer'
import emailValidator from 'email-validator'
import fs from 'fs'

dotenv.config()

function to_keys(joined_by_col) {
  const [pub, priv] = joined_by_col.split(':')
  if (pub == null || priv == null) {
    return null;
  }
  return {
    pub, priv
  }
}

const config = {
  org: process.env.ORG_NAME,
  user: process.env.AUTH_USER,
  password: process.env.AUTH_PASSWORD,
  queue_url: process.env.QUEUE_URL,
  identity_url: process.env.IDENTITY_URL,
  identity_api_token: process.env.IDENTITY_API_TOKEN,
  identity_consent: process.env.IDENTITY_CONSENT,
  identity_action_fields: (process.env.IDENTITY_ACTION_FIELDS || '').toLowerCase().split(','),
  identity_contact_fields: (process.env.IDENTITY_CONTACT_FIELDS || '').toLowerCase().split(','),
  service_url: process.env.SERVICE_URL || process.env.IDENTITY_URL,
  url: process.env.API_URL || 'https://api.proca.app',
  keys: process.env.KEYS || 'keys.json'
}

function storeConfig(config, fn) {
  let data = ''

  const vars = {
    'ORG_NAME': config.org,
    'AUTH_USER': config.user,
    'AUTH_PASSWORD': config.password,
    'API_URL': config.url,
    'QUEUE_URL': config.queue_url,
    'IDENTITY_URL': config.identity_url,
    'IDENTITY_API_TOKEN': config.identity_api_token,
    'IDENTITY_CONSENT': config.identity_consent,
    'IDENTITY_ACTION_FIELDS': config.identity_action_fields,
    'IDENTITY_CONTACT_FIELDS': config.identity_contact_fields,
    'SERVICE_URL': config.service_url,
    'KEYS': config.keys
  }

  for (let [k, v] of Object.entries(vars)) {
    if (v) {
      data += `${k}=${v}\n`
    }
  }

  fs.writeFile(fn, data, (err) => {
    if (err) return console.log(err);
  })
}

async function setup() {
  const info = await inquirer.prompt([
    {type:'input', name: 'org', default: config.org, message: 'What is the short name of your org?'},
    {type:'input', name: 'user', default: config.user, message: 'What is your username (email)?',
     validate: emailValidator.validate},
    {type:'password', name: 'password', default: config.password, messsage: 'Your password?'},
    {type:'input', name: 'url', default: config.url, message: 'Proca backend url'},
    {type:'input', name: 'queue_url', default: config.queue_url, message: 'Proca queue url'},
    {type:'input', name: 'keys', default: config.keys, message: 'Keys file'}

  ]).catch((error) => {
    console.log(`Wrong! ${error}`)
    return {}
  })

  storeConfig(info, '.env')
}

export default Object.assign(config, {setup: setup});

// module.exports = Object.assign(config, {
//   setup: setup
// })
