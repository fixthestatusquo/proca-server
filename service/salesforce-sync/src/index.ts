import {Connection} from 'jsforce'

import {
  syncQueue, ActionMessageV2
} from '@proca/queue'

import {
  makeClient,
  upsertContact,
  upsertLead,
  contactByEmail,
  campaignByName,
  addCampaignContact,
  foo,
  leadByEmail
} from './client'


import {
  isActionSyncable,
  actionToContactRecord,
  actionToLeadRecord
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
 -e email - lookup contact and lead by email
 -l - add as leads not contacts
 -L - language custom field
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

  } else if (opt.e) {
    makeClient().then(async ({conn}) => {
      const contact = await contactByEmail(conn, opt.e)
      const lead = await leadByEmail(conn, opt.e)
      console.log('contact', contact)
      console.log('lead', lead)
      process.exit(0)
    })
  } else if (opt.i) {
    makeClient().then(async ({conn}) => {
      console.log('contact', await conn.sobject('Contact').retrieve(opt.id))
      console.log('lead', await conn.sobject('Lead').retrieve(opt.id))
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

        try {

          if (opt.l) {
            const record = actionToLeadRecord(action, {language: opt.L});
            const LeadId = await upsertLead(conn, record)
            if (!LeadId) return Error(`Could not upsert contact`)
            await addCampaignContact(conn, camp.Id, {LeadId})


          } else {
            const record = actionToContactRecord(action, {language: opt.L});
            const ContactId = await upsertContact(conn, record)
            if (!ContactId) return Error(`Could not upsert contact`)
            await addCampaignContact(conn, camp.Id, {ContactId})
          }
        } catch (er) {
          if (er.errorCode === 'DUPLICATE_VALUE') {
            // already in campaign
            return {}
          }
          console.error(`tried to add ${action.contact.email} but (ignoring)`, er, JSON.stringify(er),  `CODE>${er.errorCode}<`)
          throw er;
        }

        return {}
      })
    })
  }
}
