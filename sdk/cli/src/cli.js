import yargs from 'yargs';

import {load as loadConfig} from './config'
import {listCampaigns, getCampaign, listActionPages, getActionPage, updateActionPage} from  './campaign'
import {listKeys, addKey} from './org'
import {exportActions} from './export'
import {testQueue, syncQueue} from './queue'
import {setup} from './setup'
import {showToken} from './util'
import {watchPages} from './watch'

// import {testQueue, syncQueue, addBackoff} from './queue'

require = require('esm')(module);



export default function cli() {
  const config = loadConfig()

  const configOverrides = {
    'queue': 'queue_url',
    'keys': 'keyData',
    'host': 'url',
    'user': 'username',
    'password': 'password',
    'org': 'org'
  }

  function override(option, desc) {
    const key = configOverrides[option]
    return {
      alias: option,
      type: 'string',
      describe: desc,
      default: config[key],
    }
  }

  function cmd(cliMethod) {
    return (opts) => {
      // override config
      for (const [opt, key] of Object.entries(configOverrides)) {
        config[key] = opts[opt]
      }

      cliMethod(opts, config).catch((error) => {
        if (error.message) {
          console.error(`Error:`, error.message)
        } else if (error.length > 0 && error[0].message) {
          const {message, path} = error[0]
          console.error(`Error:`, message)
          if (path && path[0] == 'org') {
            console.error(`Do you belong to the team of org "${config.org}"?`)
          }
        } else if (error.result && error.result.errors && error.result.errors.length > 0) {
          const {message, extensions, path} = error.result.errors[0]
          console.error(message + (extensions && extensions.code ? `, code: ${extensions.code}` : ``))
        }
      })
    }
  }

  const argv = yargs
        .scriptName('proca-cli')
        .command(
          'setup',
          'configure proca CLI (generates .env, keys.json files)',
          y => y,
          (y) => setup(config)
        )
        .option('o', override('org', 'org name' ))
        .option('u', override('user', 'user name'))
        .option('p', override('password', 'password'))
        .option('h', override('host', 'api url'))
        .option('q', override('queue', 'queue url'))
        .option('k', override('keys', 'file containing keys'))
        .option('J', {
          alias: 'json',
          type: 'boolean',
          describe: 'Format output in JSON',
          default: false
        })
        .option('X', {
          alias: 'csv',
          type: 'boolean',
          describe: 'Format output in CSV',
          default: false
        })
        .command('token', 'print basic auth token', {}, showToken)
        .command('campaigns', 'List campaigns for org', {}, cmd(listCampaigns))
        .command('campaign', 'show campaign for org', {
          i: {
            alias: 'id',
            type: 'number',
            description: 'ID of requested object',
            demandOption: true
          }
        }, cmd(getCampaign))
        .command('pages', 'List action pages for org', {}, cmd(listActionPages))
        .command('page', 'show page for org', {
          i: {
            alias: 'id',
            type: 'number',
            description: 'ID of requested object'
          },
          n: {
            alias: 'name',
            type: 'string',
            description: 'Name of requested object'
          },
          'P': {
            alias: 'public',
            type: 'boolean',
            description: 'Use public API to fetch action page'
          }
        }, cmd(getActionPage))
        .command('page:update', 'update page for org', {
          i: {
            alias: 'id',
            type: 'number',
            description: 'ID of requested object',
            demandOption: true
          },
          n: {
            alias: 'name',
            type: 'string',
            description: 'update ActionPage name'
          },
          l: {
            alias: 'locale',
            type: 'string',
            description: 'update ActionPage locale'
          },
          t: {
            alias: 'tytpl',
            type: 'string',
            description: 'update ActionPage Thank You email template reference'
          },
          e: {
            alias: 'extra',
            type: 'number',
            description: 'update ActionPage extra supporters number'
          },
          c: {
            alias: 'config',
            type: 'string',
            description: 'update ActionPage config - provide filename or JSON string'
          }
        }, cmd(updateActionPage))
        .command('keys', 'Display keys', {}, cmd(listKeys))
        .command('key:add', 'Do not use! deprecated. Use setup instead', {}, cmd(addKey))
        .command('watch:pages', 'Subscribe to page updates', {
          x: {
            alias: 'exec',
            type: 'string',
            description: 'program to execute with data in stdin'
          },
          A: {
            alias: 'all',
            type: 'boolean',
            description: 'Watch all orgs (not just one passed via -o)'
          }
        }, cmd(watchPages))
        .command('export', 'Export action and supporter data', {
          c: {
            alias: 'campaign',
            type: 'string',
            description: 'Limit to campaign name'
          },
          b: {
            alias: 'batch',
            type: 'number',
            description: 'Batch size',
            default: 1000
          },
          s: {
            alias: 'start',
            type: 'number',
            description: 'Start from this action id'
          },
          a: {
            alias: 'after',
            type: 'string',
            description: 'Start from this date (iso)'
          },
          d: {
            alias: 'decrypt',
            type: 'boolean',
            description: 'Decrypt contact PII'
          },
          I: {
            alias: 'ignore',
            type: 'boolean',
            default: false,
            description: 'Ignore problems with decrypting contact pii'
          },
          A: {
            alias: 'all',
            type: 'boolean',
            default: false,
            description: 'Download all actions (even not opted in)'
          },
          F: {
            alias: 'fields',
            type: 'string',
            default: '',
            description: 'Export fields (comma separated)'
          }
        }, cmd(exportActions))
        .command('deliver:check', 'print status of delivery queue', {}, cmd(testQueue))
        .command('deliver:sync', 'sync deliver queue to service', {
          d: {
            alias: 'decrypt',
            type: 'boolean',
            description: 'Decrypt contact PII'
          },
          's': {
            alias: 'service',
            type: 'string',
            describe: 'Service to which deliver action data',
            demandOption: true
          },
          'l': {
            alias: 'service_url',
            type: 'string',
            describe: 'Deliver to service at location',
            default: config.service_url
          },
          'B': {
            alias: 'backoff',
            type: 'boolean',
            describe: 'Add backoff when calling syncAction'
          }
        }, cmd(syncQueue))
        .demandCommand().argv;
}
