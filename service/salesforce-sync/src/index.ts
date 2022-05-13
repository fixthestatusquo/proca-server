import {Connection} from 'jsforce'

import {
  syncQueue, ActionMessageV2, EventMessageV2
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
  actionToLeadRecord,
  emailChangedToContactRecord
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
salesforce-sync

 -h - show this help

 Diagnostics:
 -t - test sign in to SalesForce
 -c campaignName - fetch campaign info
 -e email - lookup contact and lead by email


 Syncing:
 -q - run sync of queue, with these options:
 -u - queue url amqps://user:password@api.proca.app/proca_live (or QUEUE_URL env)
 -l - add as leads not contacts
 -L - language custom field
 -O - Opt in custom field (eg Email_Opt_In__c)
 -D - double opt in
 -T - use campaign title instead of name
`)
}

export const cli = (argv : string[]) => {
  const opt = parseArg(argv)
  let campaignRTI : string | undefined;

  if (opt.h || opt.help) {
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
      const camp = await campaignByName(conn, opt.c, false)
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
      return syncQueue(url, opt.q, async (action : ActionMessageV2 | EventMessageV2)=>{
        if (action.schema === 'proca:action:2') {
          if (!isActionSyncable(action)) {
            console.info(`Not syncing action id ${action.actionId} (no consent/opt in)`)
            return false
          }

          let camp = await campaignByName(conn, opt.T ? action.campaign.title : action.campaign.name, false)

          try {
            if (opt.l) {
              const record = actionToLeadRecord(action, {language: opt.L, doubleOptIn: Boolean(opt.D), optInField: opt.O, defaultLastName: opt.lastname});
              const LeadId = await upsertLead(conn, record)
              if (!LeadId) return Error(`Could not upsert lead`)
              const r = await addCampaignContact(conn, camp.Id, {LeadId}, action)
              console.log(`Added lead to campaign ${JSON.stringify(r)}`)


            } else {
              const record = actionToContactRecord(action, {language: opt.L, doubleOptIn: Boolean(opt.D), optInField: opt.O, defaultLastName: opt.lastname});
              const ContactId = await upsertContact(conn, record)
              if (!ContactId) return Error(`Could not upsert contact`)
              const r = await addCampaignContact(conn, camp.Id, {ContactId}, action)
              console.log(`Added contact to campaign ${JSON.stringify(r)}`)
            }
          } catch (er) {
            if (er.errorCode === 'DUPLICATE_VALUE') {
              // already in campaign
              return {}
            }
            console.error(`tried to add ${action.contact.email} but error happened`, er, JSON.stringify(er),  `CODE>${er.errorCode}<`)
            throw er;
          }
        } else if (action.schema === "proca:event:2" && action.eventType === 'email_status') {
          // update opt in
          if (!opt.O)  throw Error('please provide custom field for opt in with -O Opt_In__c')

          const record = emailChangedToContactRecord(action, opt.O)
          if (record === null)
            return {}

          if (opt.l) {
            const LeadId = await upsertLead(conn, record)
            console.log(`Updated Lead id ${LeadId} with ${JSON.stringify(record)}`)
          } else {
            const ContactId = await upsertContact(conn, record)
            console.log(`Updated Contact id ${ContactId} with ${JSON.stringify(record)}`)
          }

        }

        return {}
      })
    }).catch((e) => { console.error(e);  process.exit(1); })
  }
}
