import yargs from 'yargs';

import config from './config'
import {listCampaigns, getCampaign} from  './campaign'
import {setup, showToken} from './util'

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
          c: {
            type: 'integer',
            demandOption: true
          }
        }, getCampaign)
        .command(
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
        )
        .demandCommand().argv;
}
