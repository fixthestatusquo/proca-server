import inquirer from 'inquirer'
import emailValidator from 'email-validator'
import {CliConfig, storeConfig} from './config'
import {KeyStore, loadKeys, storeKeys} from './crypto'


export async function setup(config : CliConfig) {
  const msgHello = `Hello!\n\n` +
    `- Using current working directory: ${process.cwd()}\n` +
    (config.envFile ?
      `- I have read settings from .env file` :
      `- There is not .env file - I will create it after asking You some questions`)

  console.log(msgHello)

  let keys : KeyStore = null
  try {
    keys = loadKeys(config)
  } catch (errorLoadingKeys) {
    console.warn(`- I can't load keys, because`, errorLoadingKeys.message)
    console.warn(`  You might want to use setup to add the keys.`)

    keys = {
      keys: [],
      readFromFile: true,
      filename: "keys.json"
    }
  }


  while (true) {
    const msgAuthStatus = (config.org ? `org is ${config.org}` : `no org set`) + ', ' + 
      (config.username ? `user is: ${config.username}` : `user is not set up`) + ', ' +
      (config.password ? `password is set` : `password is not set`)

    const msgKeyStatus = keys === null ?
      `keys are not loaded` :
      (`${keys.keys.length} keys loaded` + (keys.readFromFile ?
        ` from file ${keys.filename}` :
        ` from KEYS var`))

    console.log(`\n`)
    const topMenu = await inquirer.prompt([{
      type: 'list',
      message: 'What would you like to do?',
      name: 'cmd',
      choices: [
        {name: "Save current config to .env file and leave", value: 'save'},
        {name: "Just leave", value: 'leave'},
        {name: `Set up authentication (${msgAuthStatus})`, value: 'auth'},
        {name: `List and verify keys (${msgKeyStatus})`, value: 'keys'},
        {name: `Add key pair`, value: 'addKeys'},
      ]
    }])

    switch (topMenu.cmd) {
      case 'save': {
        storeConfig(config, '.env')
        return
      }
      case 'leave': {
        console.log(`bye! Config wasn't saved`)
        return
      }
      case 'auth': { await setupAuth(config); break  }
      case 'keys': { await listKeys(config, keys); break }
      case 'addKeys': { await addKey(keys, config); break }
    }
  }
}

function validateOrg(org : string) {
  if (/^[\w\d_-]+$/.test(org)) {
    return true
  }
  return `should only contain letters, numbers hyphen and underscore`
}

async function setupAuth(config : CliConfig) {
  const info = await inquirer.prompt([
    {type:'input', name: 'org', default: config.org,
     message: 'What is the short name of your org?',
     validate: validateOrg},
    {type:'input', name: 'username', default: config.username,
     message: 'What is your username (email)?',
     validate: emailValidator.validate},
    {type:'password', name: 'password', default: config.password, messsage: 'Your password?'}
  ])

  config.org = info.org
  config.username = info.username
  config.password = info.password

  console.log(`Thanks! To check if these credentials work, run proca-cli campaigns or proca-cli pages`)

  return config
}

function validateKeypart(kp : string) {
  const keypartRegex = /^[A-Za-z0-9_=-]+$/

  if (kp.length == 43 && keypartRegex.test(kp)) {
    return true
  }
  return `key part does not look right! It should be 43 chars, only A-Za-z0-9_=-`
}

async function listKeys(config : CliConfig, keys : KeyStore) {
  const msgIntro = `You have ${keys.keys.length} keys in your keychain.` +
    (keys.keys.length > 0 ? ` Their public parts are (private parts not shown):` : ``)
  console.log(msgIntro)

  keys.keys.forEach((k, idx) => {
    console.log(`${idx}. ${k.public} (private key not shown)`)
    const okPub = validateKeypart(k.public)
    const okPriv = validateKeypart(k.private)
    if (okPub !== true) {
      console.warn(`  public ${okPub}`)
    }
    if (okPriv !== true) {
      console.warn(`  private ${okPriv}`)
    }
  })

  return config
}

async function addKey(keys : KeyStore, config : CliConfig) {
  const newKey = await inquirer.prompt([
    {type:'input', name: 'public', validate: validateKeypart,
     message: 'Paste public part of the key'},
    {type:'password', name: 'private', validate: validateKeypart,
     message: 'Paste private part of the key'}
  ])
  keys.keys.push({
    private: newKey.private,
    public: newKey.public
  })
  console.log(`Storing the new key`)
  try {
    storeKeys(keys)
  } catch (e) {
    console.error(`I cannot store the new key:`, e.message)
  }
  return keys
}

