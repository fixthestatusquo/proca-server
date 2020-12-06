import inquirer from 'inquirer'
import emailValidator from 'email-validator'
import {request,admin} from '@proca/api'
import client from './client'
import {CliConfig, storeConfig} from './config'
import {KeyStore, loadKeys, storeKeys} from './crypto'
import {listKeys as listKeysOnServer} from './org'
import {listCampaigns} from './campaign'


export async function setup(_opts: any, config : CliConfig) {
  const msgHello = `Hello!\n\n` +
    `- Using current working directory: ${process.cwd()}\n` +
    (config.envFile ?
      `- I have read settings from .env file` :
      `- There is not .env file - I will create it after asking You some questions`)

  console.log(msgHello)


  while (true) {
    const msgAuthStatus = (config.org ? `org is ${config.org}` : `no org set`) + ', ' + 
      (config.username ? `user is: ${config.username}` : `user is not set up`) + ', ' +
      (config.password ? `password is set` : `password is not set`)

    console.log(`\n`)
    const topMenu = await inquirer.prompt([{
      type: 'list',
      message: 'What would you like to do?',
      name: 'cmd',
      choices: [
        {name: "Save current config to .env file and leave", value: 'save'},
        {name: "Just leave", value: 'leave'},
        {name: `Set up authentication (${msgAuthStatus})`, value: 'auth'},
        {name: `Set up encryption`, value: 'keys'},
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
      case 'keys': { await setupKeys(config); break }
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

  console.log(`Thanks! Fetching campaign list to check the credentials`)
  try {
    await listCampaigns({}, config)
  } catch(errors) {
    console.error(`Nope, something is not ok with your sign-in: `, errors.message)
  }

  return config
}

async function setupKeys(config : CliConfig) {
  let keys : KeyStore = null

  try {
    keys = loadKeys(config)
  } catch (errorLoadingKeys) {
    console.warn(`- I can't load keys, because`, errorLoadingKeys.message)
    console.warn(`  Generate or add key`)

    keys = {
      keys: [],
      readFromFile: true,
      filename: "keys.json"
    }
  }

  const msgKeyStatus = `${keys.keys.length} keys in key chain`

  while (true) {
    const menu = await inquirer.prompt([{
      type: 'list',
      message: 'Here you can set up encryption:',
      name: 'cmd',
      choices: [
        {name: `Go back`, value: 'back'},
        {name: `List and verify keychain (${msgKeyStatus})`, value: 'checkKeyStore'},
        {name: `List keys in the app`, value: 'keys'},
        {name: `Set active key (used for encryption)`, value: 'activate'},
        {name: `Add key pair I have`, value: 'addKey'},
        {name: `Generate a new key pair and add it`, value: 'generateKey'},
      ]
    }])

    switch (menu.cmd) {
      case 'back': { return }
      case 'checkKeyStore': { await checkKeyStore(config, keys); break }
      case 'addKey': { await addKey(keys, config); break }
      case 'generateKey': { await generateKey(keys, config); break }
      case 'keys': {
        console.info(`Keys in org ${config.org}. Keys in your keychain with *`)
        await listKeysOnServer({}, config)
        break
      }
      case 'activate': { await activate(config); break}
    }

  }
}

async function activate(config: CliConfig) {
  const c = client(config)
  const {data, errors} = await request(c, admin.ListKeysDocument, {"org": config.org})
  if (errors) return console.error("Cannot list keys on server", errors)

  const keys = data.org.keys.filter(({expired}) => {return !expired})

  const choices = keys.map((k) => {
    return {
      name: `${k.public} ${k.name} ${k.active?" (active now)":""}`,
      value: k.id
    }
  })
  choices.push({name: "Cancel", value: 0})

  const akey = await inquirer.prompt([{
    type: 'list', message: "Which key to use for member data encryption", name: 'keyId',
    choices: choices
  }])


  if (akey.keyId == 0) {
    console.log(`Ok.`)
    return
  }

  console.log(`Setting that key as active..`)
  const op = await request(c, admin.ActivateKeyDocument, {org: config.org, id: akey.keyId})

  console.log(op.errors? `Failed to activate key ${op.errors[0].message}` : `Activated key: ${op.data.activateKey.status}`)
  
}

function validateKeypart(kp : string) {
  const keypartRegex = /^[A-Za-z0-9_=-]+$/

  if (kp.length == 43 && keypartRegex.test(kp)) {
    return true
  }
  return `key part does not look right! It should be 43 chars, only A-Za-z0-9_=-`
}

async function checkKeyStore(config : CliConfig, keys : KeyStore) {
  const msgIntro = `You have ${keys.keys.length} keys in your keychain.` +
    (keys.keys.length > 0 ? ` Their public parts are (private key not shown):` : ``)
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

async function generateKey(keys : KeyStore, config : CliConfig) {
  const input = await inquirer.prompt([
    {type:'input', name: 'name', message: 'Human readable name of the key'}
  ])
  const c = client(config)

  const {data, errors} = await request(c, admin.GenerateKeyDocument, {org: config.org, input})
  if (errors) throw errors

  const newKey = data.generateKey

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

  const activation = await inquirer.prompt([
    {type: 'confirm', name: 'activate', message: 'Activate this key?'}
  ])

  if (activation.activate) {
    const activateOp = await request(c, admin.ActivateKeyDocument, {org: config.org, id: newKey.id})
    if (activateOp.errors) throw activateOp.errors
    console.log(`Activating key: ${activateOp.data.status}`)
  }

  return keys
}
