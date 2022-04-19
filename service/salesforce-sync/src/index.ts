import {Connection} from 'jsforce'

import {
  syncQueue, ActionMessageV2
} from '@proca/queue'

import {
  makeClient,
  upsertContact,
  contactByEmail,
  campaignByName,
  addCampaignContact,
  foo
} from './client'


import {
  isActionSyncable,
  actionToContactRecord
} from './contact'


import parseArg from 'minimist'


export function p(o : any) {
  console.log(JSON.stringify(o, null, 2));
  return o
}
export function p2(o : any) {
  console.log(o)
  return o
}


function help () {
  console.log(`Help:
salesforce-sync [-t] [-u -q]

 -t - test sign in to SalesForce
 -q - run sync of queue
 -u - queue url amqps://user:password@api.proca.app/proca_live
 -c campaignName - fetch campaign info
`)
}

export const cli = (argv : string[]) => {
  const opt = parseArg(argv)

  if (opt.h) {
    // HELP
    help()
  } else if (opt.t) {
    // TEST
    makeClient().then(({userInfo}) => {
      console.log(`Signed in`, userInfo)
      process.exit(0)
    })
  } else if (opt.c) {
    makeClient().then(async ({conn}) => {
      const camp = await campaignByName(conn, opt.c)
      console.log(camp)
      process.exit(0)
    })

  } else if (opt.q) {
    const url = opt.u || process.env.QUEUE_URL
    if (!url) throw Error(`Provide -u or set QUEUE_URL`)
    // SYNC
    makeClient().then(async ({conn}) => {
      return syncQueue(url, opt.q, async (action : ActionMessageV2)=>{
        if (!isActionSyncable(action)) {
          console.info(`Not syncing action id ${action.actionId} (no consent/opt in)`)
          return false
        }

        let camp = await campaignByName(conn, action.campaign.name)

        const record = actionToContactRecord(action);
        const contactId = await upsertContact(conn, record)
        if (!contactId) return Error(`Could not upsert contact`)
        const campaignContact = await addCampaignContact(conn, camp.Id, contactId)

        return {record, contactId, campaignContact}
      })
    })
  }
}
