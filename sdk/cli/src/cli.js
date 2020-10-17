import yargs from 'yargs';

import config from './config'
import {listCampaigns, getCampaign, listActionPages, getActionPage, updateActionPage} from  './campaign'
import {listKeys} from './org'
import {exportActions} from './export'
import {setup, showToken} from './util'
import {watchPages} from './watch'

import {testQueue, syncQueue, addBackoff} from './queue'
import {deliver} from './export'

require = require('esm')(module);


export default function cli() {
  const argv = yargs
        .scriptName('proca-cli')
        .command(
          'setup',
          'configure proca CLI (generates .env file)',
          y => y,
          setup
        )
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
        .option('h', {
          alias: 'host',
          type: 'string',
          describe: 'api host with scheme (http/https)',
          default: config.url
        })
        .option('q', {
          alias: 'queue_url',
          type: 'string',
          describe: 'queue url (without path)',
          default: config.queue_url
        })
        .option('k', {
          alias: 'keys',
          type: 'string',
          describe: 'key file',
          default: config.keys
        })
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
        .command('token', 'print basic auth token', y => y, showToken)
        .command('campaigns', 'List campaigns for org', y => y, listCampaigns)
        .command('campaign', 'show campaign for org', {
          i: {
            type: 'number',
            description: 'ID of requested object',
            demandOption: true
          }
        }, getCampaign)
        .command('pages', 'List action pages for org', y => y, listActionPages)
        .command('page', 'show page for org', {
          i: {
            alias: 'id',
            type: 'number',
            description: 'ID of requested object',
            demandOption: true
          }
        }, getActionPage)
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
        }, updateActionPage)
        .command('keys', 'Display keys', {}, listKeys)
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
        }, watchPages)
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
          }
        }, exportActions)
        /*.command(
          'deliver',
          'print status of delivery qeue',
          yargs => {
            return yargs
              .option('c', {
                alias: 'check',
                type: 'boolean',
                describe: 'Check delivery queue'
              })
              .option('s', {
                alias: 'service',
                type: 'string',
                describe: 'Service to which deliver action data'
              })
              .option('l', {
                alias: 'service_url',
                type: 'string',
                describe: 'Deliver to service at location',
                default: config.service_url
              })
              .option('B', {
                alias: 'backoff',
                type: 'boolean',
                describe: 'Add backoff when calling syncAction'
              });
          },
          deliver
        )*/
        .demandCommand().argv;
}
