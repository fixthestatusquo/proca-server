import client from './client'
import {request} from '@proca/api'
import * as admin from './proca'
import {ActionMessageV2, actionToActionMessage, decryptActionMessage} from './queueMessage'
import {getFormatter, FormatOpts} from './format'
import {DecryptOpts} from './cli'
import {CliConfig} from './config'
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

  let campaigns : Record<string, admin.CampaignIds>;
  let actionPages : Record<number, Pick<admin.ActionPage,  'id' | 'name' | 'locale' | 'thankYouTemplateRef'>>;

  for (;;) {
    const {data, error} = await request(c, query, vars)

    delete argv.after  // we will use id to paginate

    if (error) {
      console.error(fmt.error(error))
      break
    }

    if (data.exportActions.length == 0) {
      break
    }

    if (!campaigns) {
      campaigns = {};
      for (const c of data.org.campaigns) {
        campaigns[c.name] = c
        delete c.__typename
      }
    }
    if (!actionPages) {
      actionPages = {};
      for (const ap of data.org.actionPages) {
        actionPages[ap.id] = ap
      }
    }

    for (const action of data.exportActions) {
      vars.start = action.actionId + 1

      const campName = argv.campaign || (action as admin.ExportOrgActions['exportActions'][0]).campaign?.name
      console.log('-> ', action.actionPage.id)
      console.log('key', action.contact.publicKey)
      const actionMsg = actionToActionMessage(action,
                                              actionPages[action.actionPage.id] || {...action.actionPage, thankYouTemplateRef: null},
                                              campaigns[campName])
      if (actionMsg.schema === "proca:action:2") {
        decryptActionMessage(actionMsg, argv, config)
        console.log(fmt.action(actionMsg))
      }
    }
  }
}



export async function syncExportFile(opts : ServiceOpts & DecryptOpts, config: CliConfig) {
  const service = getService(opts)
  const lines = new LineByLine(opts.filePath)

  lines.on('line', async (l) => {
    let action : ActionMessageV2 = JSON.parse(l)
    log(`sync actionId: ${action.actionId}`)
    
    decryptActionMessage(action, opts, config)
    lines.pause()
    await service.syncAction(action, opts, config)
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
