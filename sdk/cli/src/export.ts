import client from './client'
import {admin, request, types} from '@proca/api'
import {
  ActionWithEncryptedContact, 
  ActionWithPII,
  readMixedFormat,
  KeyStore
  } from './crypto'
import {ActionMessage, actionToActionMessage} from './queueMessage'
import {getFormatter, FormatOpts} from './format'
import {getContact, DecryptOpts} from './decrypt'
import {CliConfig} from './config'
import {PartialBy} from './util'
import {getService, ServiceOpts} from './service'
import LineByLine from 'line-by-line'
import debug from 'debug';

const log = debug('proca:export')

interface ExportActionsOpts {
  batch: number,
  all: boolean,
  start?: number,
  after?: string,
  campaign?: string,
  fields: string
}

export async function exportActions(argv : ExportActionsOpts & DecryptOpts & FormatOpts, config : CliConfig) {
  const c = client(config)
  const fmt = getFormatter(argv)

  const vars : admin.ExportCampaignActionsVariables = {
    org: config.org,
    limit: argv.batch,
    onlyOptIn: !argv.all
  }

  if (argv.start) vars.start = argv.start
  if (argv.after) vars.after = argv.after
  if (argv.campaign) vars.campaignName = argv.campaign

  const query = argv.campaign !== undefined ? admin.ExportCampaignActionsDocument : admin.ExportOrgActionsDocument

  for (;;) {
    const {data, errors} = await request(c, query, vars)

    delete argv.after  // we will use id to paginate

    if (errors) {
      console.error(fmt.error(errors))
      break
    }

    if (data.exportActions.length == 0) {
      break
    }

    for (const action of data.exportActions) {
      vars.start = action.actionId + 1

      // inplace
      decryptAction(action as ActionWithEncryptedContact, argv, config)

      console.log(fmt.action(action))
    }
  }
}


export function decryptAction(action : ActionWithEncryptedContact, argv : DecryptOpts, config : CliConfig) {
  const pii = getContact(action.contact, argv, config)
  const action2 = action as ActionWithPII
  action2.contact.pii = pii
}

export async function syncExportFile(opts : ServiceOpts & DecryptOpts, config: CliConfig) {
  const service = getService(opts)
  const lines = new LineByLine(opts.filePath)

  lines.on('line', async (l) => {
    let action : types.Action = JSON.parse(l)
    log(`sync actionId: ${action.actionId}`)
    
    decryptAction(action, opts, config)
    lines.pause()
    await service.syncAction(actionToActionMessage(action), opts, config)
    lines.resume()
  })
}


// export async function getCsvSupporters(argv) {
//   const c = argv2client(argv);
//   const file = new Date().toISOString().substring(0, 10) + ".csv";
//   const csvWriter = createCsvWriter({
//     path: file,
//     headerIdDelimiter: ".",
//     header: [
//       { id: "actionPageId", title: "page" },
//       { id: "campaignId", title: "campaign" },
//       { id: "contact.first_name", title: "firstname" },
//       { id: "contact.last_name", title: "lastname" },
//       { id: "contact.email", title: "email" },
//       { id: "contact.postcode", title: "postcode" },
//       { id: "contact.country", title: "country" },
//       { id: "created", title: "date" },
//       { id: "id", title: "id" },
//       { id: "optIn", title: "optin" }
//     ]
//   });
//   console.log("writing to " + file);
//   await streamSignatures(c, argv.org, argv.campaignId, sigs => {
//     const signatures = decryptSignatures(sigs, config);
//     csvWriter.writeRecords(signatures);
//   });
// }
