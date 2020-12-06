
import mailjet from "node-mailjet"
import {ActionMessage} from '../queueMessage'
import {CliConfig} from '../config'
import {ServiceOpts} from '../cli'

export async function syncAction(action : ActionMessage, _1: ServiceOpts, _2 : CliConfig) {
  const conn = connect()

  const tmplId = process.env['MAILJET_TEMPLATE'] || action.actionPage.thankYouTemplateRef
  if (!tmplId) throw new Error('No MAILJET_TEMPLATE set not thankYouTemplateRef on action page')

  const vars = varsFromAction(action)
  // console.log(vars)

  let res = await conn.post("send").request({
    FromEmail: 'noreply@proca.app',
    FromName: 'Is this correct',
		'Mj-TemplateID': tmplId,
		'Mj-TemplateLanguage': true,
    Recipients: [{'Email': 'marcin@cahoots.pl', 'Vars': vars}]
  })

  return res
}

export function connect() {
  const mjKey = process.env['MAILJET_KEY']
  const mjSec = process.env['MAILJET_SECRET']
  if (!mjKey || !mjSec) {
    throw new Error('No MAILJET_KEY or MAILJET_SECRET set')
  }
  const conn = mailjet.connect(mjKey, mjSec)
  return conn
}

export function varsFromAction(action : ActionMessage) {
  let vars = {
    first_name: action.contact ? action.contact.firstName : null,
    email: action.contact ? action.contact.email : null,
    ref: action.contact ? action.contact.ref : null,
    campaign_name: action.campaign ? action.campaign.name : null,
    campaign_title: action.campaign ? action.campaign.title : null,
    action_page_name: action.actionPage ? action.actionPage.name : null,
  }

  if (action.tracking) {
    vars = Object.assign(vars, {
      utm_source: action.tracking.source,
      utm_medium: action.tracking.medium,
      utm_campaign: action.tracking.campaign,
      utm_content: action.tracking.content
    })
  }

  vars = Object.assign(vars, action.action.fields)

  return vars
}
