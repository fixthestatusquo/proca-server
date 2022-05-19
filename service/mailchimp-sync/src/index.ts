import parseArg from 'minimist'
import {syncQueue, ActionMessageV2, EventMessageV2} from '@proca/queue'

import {
  ping,
  allLists,
  senders,
  makeClient,
  upsertList,
  addContactToList,
  findMember
} from './client'

import {
  actionToContactRecord,
  isActionSyncable, listName,
  emailChangedToContactRecord
} from './contact'


export const cli = async (argv : string[]) => {
  const opt = parseArg(argv)
  const client = makeClient()

  if (opt.h || opt.help) {
    console.log(`mailchimp-sync [-psl]
-t test sign-in (ping API)
-s list senders
-e email - search member by email
-l get lists
-L break-down lists by language
-T audienceName audience name used as template for new lists
-A audienceName - just add all to that audience
-U upsert list (-c listname)
-D subcribe after DOI
-O opt out as transactional
-S skip campaigns
-P amqp prefetch count
    `)
  }

  if (opt.t) {
    console.log(await ping(client))
  }
  if (opt.s) {
    const r = await senders(client)
    console.log(r)
  }
  if (opt.l) {
    const {lists} =  await allLists(client)
    console.log(JSON.stringify(lists, null, 2))
  }

  if (opt.U) {
    upsertList(client, opt.c, opt.T)
      .then(x => console.log(x))
      .catch(e => console.error('cant upsert', e))
  }

  if (opt.e) {
    findMember(client, opt.e)
      .then(x => console.log(JSON.stringify(x, null, 2)))
      .catch(e => console.error('cont find', e))
  }

  if (opt.q) {
    const url = opt.u || process.env.QUEUE_URL
    const templateList = opt.T || process.env.TEMPLATE_LIST
    const targetList = opt.A || process.env.TARGET_LIST
    const listPerLang = Boolean(opt.L)
    const skipCampaigns = opt.S ? opt.S.split(",") : []

    if (!targetList && !templateList)
      throw Error("Please provide target audience with -A or template audience with -T")

    if (!url) throw Error(`Provide -u or set QUEUE_URL`)
    syncQueue(url, opt.q, async (action : ActionMessageV2 | EventMessageV2) => {
      if (action.schema === 'proca:action:2') {
        if (action.campaign.name in skipCampaigns) {
          console.info(`Not syncing action because ${action.campaign.name} is skipped`)
          return false;
        }

        if (!isActionSyncable(action)) {
          console.info(`Not syncing action id ${action.actionId} (no consent/opt in)`)
          return false
        }

        const list = targetList ?
          await upsertList(client, targetList, targetList) : // XXX use upsert to fetch
          await upsertList(client, listName(action, listPerLang), templateList)

        const member = actionToContactRecord(action, Boolean(opt.D), Boolean(opt.O))
        const r = await addContactToList(client, list.id, member)
        console.log(`added ${member.email_address} (status ${member.status_if_new}) to list ${list.name} (id ${list.id})`)
        // console.log(r)

        return r
      }
      if (action.schema === 'proca:event:2' && action.eventType === 'email_status') {
        const record = emailChangedToContactRecord(action)

        if (record) {
          const search = await findMember(client, action.supporter.contact.email)
          if (search.exact_matches.members.length === 0) {
            throw Error(`Did not find ${action.supporter.contact.email}`)
          }

          for (const member of search.exact_matches.members) {
            try {
              const r = await addContactToList(client, member.list_id, record)
              console.log(`Update ${action.supporter.contact.contactRef} status to ${r.status}`)
            } catch (e) {
              const reason = e.response?.error?.text?.title
              if (reason === "Member In Compliance State") {
                console.warn(`Cannot update ${action.supporter.contact.email} because ${reason}`)
              } else {
                throw e
              }
            }
          }
        } else {
          console.log(action)
          console.warn(`Ignore event ${action.eventType} for ${action.supporter.contact.email}`)
        }

        // XXX handle clear and double opt in
        return false
      }
    }, {prefetch: opt.P || 10}).catch(e => console.error(e))


  }
}

/*
 *
 * */
