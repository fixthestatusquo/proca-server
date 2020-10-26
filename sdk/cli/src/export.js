import client from './client'
import {admin, request} from '@proca/api'
import {decryptAction} from './crypto'
import {getFormatter} from './format'
import {keys, decrypt, getContact} from './crypto'


export async function exportActions(argv) {
  const c = client(argv)
  const fmt = getFormatter(argv)

  const vars = {
    org: argv.org,
    limit: argv.batch,
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

      decryptAction(action, argv)

      console.log(fmt.action(action))
    }
  }
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

