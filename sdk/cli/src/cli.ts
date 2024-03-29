import yargs from 'yargs';

import {load as loadConfig, CliConfig, overrideConfig} from './config'
import {listCampaigns, getCampaign, listActionPages, getActionPage,
        updateActionPage, upsertCampaign, upsertActionPage} from  './campaign'
import {listKeys, addOrg, addKey} from './org'
import {exportActions, syncExportFile} from './export'
import {testQueue, syncQueue, syncFile} from './queue'
import {setup} from './setup'
import {showToken} from './util'
import {ServiceOpts} from './service'
import {watchPages} from './watch'

// import {testQueue, syncQueue, addBackoff} from './queue'



export interface CliOpts {
  org?: string,
  user?: string,
  password?: string,
  host?: string,
  queue?: string,
  keys?: string,
  debug?: boolean,
  sentry?: boolean,
  json?: boolean,
  csv?: boolean,
  indent?: number,
  id?: number,
  name?: string,
  title?: string,
  public?: boolean,
  locale?: string,
  tytpl?: string,
  extra?: number,
  config?: string,
  exec?: string,
  all?: boolean,
  campaign?: string,
  start?: number,
  after?: string,
  decrypt?: boolean,
  ignore?: boolean,
  fields?: string,
  // ServiceOpts
  queueName?: string,
  queuePrefetch?: number,
  service?: string,
  service_url?: string,
  backoff?: boolean,
  // file:sync
  filePath?: string
}

export type DecryptOpts = {
  decrypt?: boolean,
  ignore?: boolean
}

export default function cli() {
  const config : CliConfig = loadConfig()


  function override(short: string, desc: string, def: any) {
    return {
      alias: short,
      type: "string" as yargs.PositionalOptionsType,
      describe: desc,
      default: def
    }
  }

  function cmd(cliMethod : (opts:CliOpts, config:CliConfig) => Promise<any>) {
    return (opts : yargs.Arguments<CliOpts>) => {

      // back propagate the overriding of options
      // this might not be right but we have a two way flow:
      // the opts take defaults from config, but if set, they can override back the config

      overrideConfig(config, {
        queue_url: opts.queue,
        keyData: opts.keys,
        url: opts.host,
        username: opts.user,
        password: opts.password,
        org: opts.org
      })

      if (opts.sentry) {
        if (process.env.SENTRY_DSN) {
          try {
            const Sentry = require("@sentry/node");
            Sentry.init({
              dsn: process.env.SENTRY_DSN
            })
          } catch {
            opts.sentry = false
          }
        } else {
          opts.sentry = false
        }
      }


      cliMethod(opts, config).catch((error) => {
        if (process.env['DEBUG']) throw error;
        if (error.message) {
          console.error(`Error:`, error.message)

        } else if (error.length > 0 && error[0].message) {
          const {message, path, extensions} = error[0]
          console.error(`Error:`, message)
          if (path && path[0] == 'org') {
            console.error(`Do you belong to the team of org "${config.org}" and have proper permissions?`)
          }
          if (extensions && extensions.code == 'permission_denied') {
            console.error(`Needed permissions are: ${extensions.required}`)
          }
        } else {
          console.error(error)

        }

        if (error.result && error.result.error && error.result.error.length > 0) {
          const {message, extensions, path} = error.result.error[0]
          console.error(
            message
              + (extensions && extensions.code ? `, code: ${extensions.code}` : ``)
              + (path ? `, path: ${path}` : ``)
          )
        }

        if (opts.debug && error.stack) {
          console.error(`The call trace that led to this error is:\n${error.stack}`)
        }
      })
    }
  }

  function validateIso8601Date(val :string) {
    if (! /^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}(Z|[+-]\d{2}:\d{2})$/.test(val)) {
      throw new Error("Provide a date time in ISO8601 format (YYYY-MM-DDThh:mm:ssZ or TZ shift instead of Z, eg:+01:00)")
    }
    return val
  }

  const argv = yargs
    .scriptName('proca-cli')
    .usage('$0 <cmd> [args]')
    .option('debug', {
      alias: 'D',
      type: 'boolean',
      default: false,
      describe: 'Enable troubleshooting information'
    })
    .option('sentry', {
      alias: 'S',
      type: 'boolean',
      default: false,
      describe: 'Report to sentry (set SENTRY_DSN)'
    })
    .option('org', override('o', 'org name', config.org ))
    .option('user', override('u', 'user name', config.username))
    .option('password', override('p', 'password', config.password))
    .option('host', override('h', 'api url', config.url))
    .option('queue', override('q', 'queue url', config.queue_url))
    .option('keys', override('k', 'file containing keys', config.keyData))
    .option('json', {
      alias: 'J',
      type: 'boolean',
      describe: 'Format output in JSON',
      default: false
    })
    .option('indent', {
      type: 'number',
      describe: 'Indent in JSON formatting',
      default: 2
    })
    .option('csv', {
      alias: 'X',
      type: 'boolean',
      describe: 'Format output in CSV',
      default: false
    })
    .command('token', 'print basic auth token', {}, cmd(showToken))
    .command('$0', 'missing param', () => {}, (argv) => {
      console.log('missing params, --help. the first time you need to run setup')
    })

    .command(
      'setup',
      'configure proca CLI (generates .env, keys.json files)',
      {},
      cmd(setup)
    )
    .command('org:add', 'add a new organisation', {
      name: {
        alias: 'n',
        type: 'string',
        description: 'Name of campaign',
        demandOption: true
      },
      schema: {
        alias: 's',
        type: 'string',
        description: 'Member personal data schema',
        choices: ['basic', 'popular_initiative', 'eci'],
        default: 'basic'
      },
      title: {
        alias: 't',
        type: 'string',
        description: 'Full org name',
        demandOption: true
      }
    }, cmd(addOrg))
    .command('campaigns', 'List campaigns for org', {}, cmd(listCampaigns))
    .command('campaign', 'show campaign for org', {
      id: {
        alias: 'i',
        type: 'number',
        description: 'ID of requested object',
        demandOption: true
      }
    }, cmd(getCampaign))
    .command('campaign:upsert', 'Upsert campaign', {
      name: {
        alias: 'n',
        type: 'string',
        description: 'Name of campaign',
        demandOption: true
      },
      title: {
        alias: 't',
        type: 'string',
        description: 'Description of the campaign'
      }
    }, cmd(upsertCampaign))
    .command('pages', 'List action pages for org', {}, cmd(listActionPages))
    .command('page', 'show page for org', {
      id: {
        alias: 'i',
        type: 'number',
        description: 'ID of requested object'
      },
      name: {
        alias: 'n',
        type: 'string',
        description: 'Name of requested object'
      },
      'public': {
        alias: 'P',
        type: 'boolean',
        description: 'Use public API to fetch action page'
      }
    }, cmd(getActionPage))
    .command('page:update', 'update page for org', {
      id: {
        alias: 'i',
        type: 'number',
        description: 'ID of requested object',
        demandOption: true
      },
      name: {
        alias: 'n',
        type: 'string',
        description: 'update ActionPage name'
      },
      locale: {
        alias: 'l',
        type: 'string',
        description: 'update ActionPage locale'
      },
      tytpl: {
        alias: 't',
        type: 'string',
        description: 'update ActionPage Thank You email template reference'
      },
      extra: {
        alias: 'e',
        type: 'number',
        description: 'update ActionPage extra supporters number'
      },
      config: {
        alias: 'c',
        type: 'string',
        description: 'update ActionPage config - provide filename or JSON string'
      }
    }, cmd(updateActionPage))
    .command('page:add', 'Add a page to campaign', {
      campaign: {
        alias: 'c',
        type: 'string',
        description: 'Limit to campaign name',
        demandOption: true
      },
      name: {
        alias: 'n',
        type: 'string',
        description: 'update ActionPage name',
        demandOption: true
      },
      locale: {
        alias: 'l',
        type: 'string',
        description: 'update ActionPage locale',
        demandOption: true
      }
    }, cmd(upsertActionPage))
    .command('keys', 'Display keys', {}, cmd(listKeys))
    .command('key:add', 'Do not use! deprecated. Use setup instead', {}, cmd(addKey))
    .command('watch:pages', 'Subscribe to page updates', {
      exec: {
        alias: 'x',
        type: 'string',
        description: 'program to execute with data in stdin'
      },
      all: {
        alias: 'A',
        type: 'boolean',
        description: 'Watch all orgs (not just one passed via -o)'
      }
    }, cmd(watchPages))
    .command('export', 'Export action and supporter data', {
      campaign: {
        alias: 'c',
        type: 'string',
        description: 'Limit to campaign name'
      },
      batch: {
        alias: 'b',
        type: 'number',
        description: 'Batch size',
        default: 1000
      },
      start: {
        alias: 's',
        type: 'number',
        description: 'Start from this action id'
      },
      after: {
        alias: 'a',
        type: 'string',
        description: 'Start from this date (iso)',
        coerce: validateIso8601Date
      },
      decrypt: {
        alias: 'd',
        type: 'boolean',
        default: true,
        description: 'Decrypt contact PII'
      },
      ignore: {
        alias: 'I',
        type: 'boolean',
        default: false,
        description: 'Ignore problems with decrypting contact pii'
      },
      all: {
        alias: 'A',
        type: 'boolean',
        default: false,
        description: 'Download all actions (even not opted in)'
      },
      fields: {
        alias: 'F',
        type: 'string',
        default: '',
        description: 'Export fields (comma separated)'
      }
    }, cmd(exportActions))
    .command('export:syncFile', 'sync exported actions from file to service', {
      filePath: {
        alias: 'f',
        type: 'string',
        demandOption: true,
        description: 'File with actions (json list format)'
      },
      decrypt: {
        alias: 'd',
        type: 'boolean',
        description: 'Decrypt contact PII'
      },
      service: {
        alias: 's',
        type: 'string',
        describe: 'Service to which deliver action data',
        demandOption: true
      },
      service_url: {
        alias: 'l',
        type: 'string',
        describe: 'Deliver to service at location',
        default: config.service_url
      },
      'backoff': {
        alias: 'B',
        type: 'boolean',
        describe: 'Add backoff when calling syncAction'
      }
    }, cmd(syncExportFile))
    .command('deliver:check', 'print status of delivery queue', {
      queueName: {
        alias: 'Q',
        type: 'string',
        description: 'Exact queue name to use instead of standard ones'
      }
    }, cmd(testQueue))
    .command('deliver:sync', 'sync deliver queue to service', {
      queueName: {
        alias: 'Q',
        type: 'string',
        description: 'Exact queue name to use instead of standard ones'
      },
      queuePrefetch: {
        alias: 'N',
        type: 'number',
        description: 'Queue prefetch count'
      },
      decrypt: {
        alias: 'd',
        type: 'boolean',
        description: 'Decrypt contact PII'
      },
      service: {
        alias: 's',
        type: 'string',
        describe: 'Service to which deliver action data',
        demandOption: true
      },
      service_url: {
        alias: 'l',
        type: 'string',
        describe: 'Deliver to service at location',
        default: config.service_url
      },
      'backoff': {
        alias: 'B',
        type: 'boolean',
        describe: 'Add backoff when calling syncAction'
      }
    }, cmd(syncQueue))
    .command('deliver:syncFile', 'sync action messages from file to service', {
      filePath: {
        alias: 'f',
        type: 'string',
        demandOption: true,
        description: 'File with actions (json list format)'
      },
      decrypt: {
        alias: 'd',
        type: 'boolean',
        description: 'Decrypt contact PII'
      },
      service: {
        alias: 's',
        type: 'string',
        describe: 'Service to which deliver action data',
        demandOption: true
      },
      service_url: {
        alias: 'l',
        type: 'string',
        describe: 'Deliver to service at location',
        default: config.service_url
      },
      'backoff': {
        alias: 'B',
        type: 'boolean',
        describe: 'Add backoff when calling syncAction'
      }
    }, cmd(syncFile))

    .help()
    .argv
        // .demandCommand().argv;
}
