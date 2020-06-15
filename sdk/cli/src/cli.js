
import yargs from 'yargs'
// import config from './config/get'
import config from './config'
import {campaigns,client, streamSignatures} from './api'
import {decryptSignatures} from './crypto'
import {testQueue, syncQueue, addBackoff} from './queue'
// import {getCount,getSignature} from './lib/server.js'
require = require('esm')(module)

async function setup(argv) {
  config.setup()
}

function argv2client(argv) {
  const c = client({url: argv.url, user: argv.user, password: argv.password})
  return c
}

const actionTypeEmojis = {
  'petition': "✍️ ",
  'register': "📥",
  'share_click': "📣",
  'share_close': "📣",
  'twitter_click': "🐦",
  'twitter_close': "🐦"
}

const actionTypeOtherEmoji = "👉"

async function listCampaigns(argv) {
  const c = argv2client(argv)
  const resp = await campaigns(c, argv.org);
  resp.data.org.campaigns.forEach((camp) => {
    console.log(`🏁 ${camp.name} [ID ${camp.id}]: ${camp.title} [${camp.org.title}] (🧑‍ ${camp.stats.supporterCount} supporters)`)
    camp.stats.actionCount.forEach(({actionType, count}) => {
      const emoji = actionTypeEmojis[actionType] || actionTypeOtherEmoji
      console.log(`  ${emoji} ${actionType}: ${count}`)
    })
  })
}

async function getSupporters(argv) {
  const c = argv2client(argv)
  await streamSignatures(c, argv.org, argv.campaignId, (sigs) => {
    const signatures = decryptSignatures(sigs, config)
    console.log(signatures)
  })
  
}

async function showToken(argv) {
  const c = argv2client(argv)
  console.log(c.options.headers)
}

async function deliver(argv) {
  if (argv.check) {
    testQueue(config)
  } else if (argv.service) {
    let service = require(`./service/${argv.service}`)
    if (argv.backoff) {
      service.syncAction = addBackoff(service.syncAction)
    }
    try {
      await syncQueue(service, config, argv)
    } catch (error) {
      console.error(`🙄 Problem delivering to service. I give up: ${error}`)
    }
  }
  return true
}

export default function cli () {
  const argv = yargs.scriptName("proca-cli")
        .command('setup', 'configure proca CLI (generates .env file)', y => y, setup)
        .option('o', {
          alias: 'org',
          type: 'string',
          describe: 'org name',
          default: config.org
        })
        .option('u', {
          alias: 'user',
          type: 'string',
          describe: 'user email',
          default: config.user
        })
        .option('p', {
          alias: 'password',
          type: 'string',
          describe: 'password',
          default: config.password
        })
        .option('a', {
          alias: 'url',
          type: 'string',
          describe: 'api url (without path)',
          default: config.url
        })
        .option('q', {
          alias: 'queue_url',
          type: 'string',
          describe: 'queue url (without path)',
          default: config.queue_url
        })
        .command('token', 'print basic auth token', y => y, showToken)
        .command('campaigns', 'List campaigns for org',y => y, listCampaigns)
        .command('supporters', 'Downloads supporters',  (yargs) => {
          return yargs
            .option('c', {
              alias: 'campaignId', type: 'integer', describe: 'campaign id'
            })
            .option('r', {
              alias: 'run', type: 'string',
              describe: 'JS file exporting syncAction(action, config) method'
            })
        }, getSupporters)
        .command('deliver', 'print status of delivery qeue', (yargs) => {
          return yargs
            .option('c', {
              alias: 'check', type: 'boolean', describe: 'Check delivery queue'
            })
            .option('s', {
              alias: 'service', type: 'string', describe: 'Service to which deliver action data'
            })
            .option('l', {
              alias: 'service_url', type: 'string', describe: 'Deliver to service at location'
            })
            .option('B', {
              alias: 'backoff', type: 'boolean', describe: 'Add backoff when calling syncAction'
            })
        }, deliver)
        .demandCommand()
        .argv
}

