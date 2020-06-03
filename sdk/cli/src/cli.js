
import yargs from 'yargs'
// import config from './config/get'
import config from './config'
import {campaigns,client, streamSignatures} from './api'
import {decryptSignatures} from './crypto'
// import {getCount,getSignature} from './lib/server.js'


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
  try {
    const resp = await campaigns(c, argv.org);
  } catch (e) {
    e.response.errors.map (msg =>(console.error(msg.message)))
    process.exit(1);
  }
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

export function cli () {
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
        .command('token', 'print basic auth token', y => y, showToken)
        .command('campaigns', 'List campaigns for org',y => y, listCampaigns)
        .command('supporters', 'Downloads supporters',  (yargs) => {
          return yargs.option('c', {alias: 'campaignId', type: 'integer', describe: 'campaign id'})
        }, getSupporters)
        .demandCommand()
        .argv
}

module.exports = {
  cli
}
