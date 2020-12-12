
import client from './client'
import {admin, widget, request, types} from '@proca/api'
import {getFormatter, FormatOpts} from './format'
import fs from 'fs'
import {CliConfig} from './config'


export async function listCampaigns(argv : FormatOpts, config : CliConfig) {
  const c = client(config)
  const fmt = getFormatter(argv)

  const result = await request(c, admin.ListCampaignsDocument, {"org": config.org})
  if (result.errors) throw result.errors

  result.data.org.campaigns
    .map(c => fmt.campaign(c))
    .forEach((c) => {
      console.log(c)
    })
  return result.data.org.campaigns
}

interface IdOpt {
  id?: number
}

export async function getCampaign(argv : IdOpt & FormatOpts, config : CliConfig) {
  const c = client(config)
  const fmt = getFormatter(argv)

  const {data, errors} = await request(c, admin.GetCampaignDocument, {"org": config.org, "id": argv.id})

  if (errors) throw errors

  console.log(fmt.campaign(data.org.campaign))
}


export async function listActionPages(argv : FormatOpts, config : CliConfig) {
  const c = client(config)
  const fmt = getFormatter(argv)

  const {data, errors} = await request(c, admin.ListActionPagesDocument, {"org": config.org})
  if (errors) throw errors

  data.org.actionPages
    .map(ap => fmt.actionPage(ap, data.org))
    .forEach((ap) => {console.log(ap)})

  data.org.actionPages
}

interface GetActionPageOpts {
  name?: string,
  id?: number,
  public: boolean
}

type GetActionPageVars = {
  name?: string,
  id?: number,
  org?: string
}

export async function getActionPage(argv : GetActionPageOpts & FormatOpts, config : CliConfig) {
  const c = client(config)
  const fmt = getFormatter(argv)

  let vars : GetActionPageVars = {}
  let t = null

  if (argv.name)
    vars.name = argv.name

  if (argv.id)
    vars.id = argv.id

  if (!argv.public)
    vars.org = config.org

  if (argv.public) {
    const {data, errors} = await request(c, widget.GetActionPageDocument, vars)
    if (errors) throw errors
    t = fmt.actionPage(data.actionPage, data.actionPage.org)
    console.log(t)
    return data.actionPage
  } else {
    const {data, errors} = await request(c, admin.GetActionPageDocument, vars)
    if (errors) throw errors
    t = fmt.actionPage(data.org.actionPage, data.org)
    console.log(t)
    return data.org.actionPage
  }
}

interface UpdateActionPageOpts {
  id: number,
  name?: string,
  config?: string,
  tytpl?: string,
  extra?: number
}

export async function updateActionPage(argv : UpdateActionPageOpts & FormatOpts, config : CliConfig) {
  const c = client(config)
  const fmt = getFormatter(argv)

  let json = null

  // json
  if (argv.config) {
    if (argv.config[0] == '{') {
      json = argv.config
    } else {
      json = fs.readFileSync(argv.config, 'utf8')
    }
  }

  let actionPage : types.ActionPageInput = {
    name: argv.name,
    thankYouTemplateRef: argv.tytpl,
    extraSupporters: argv.extra,
    config: json
  }

  if (argv.json) {
    actionPage = fmt.addConfigKeysToAP(actionPage)
  }

  // DEBUG
  // console.debug(`updateActionPage(${JSON.stringify(ap_in)})`)

  const {errors} = await request(c, admin.UpdateActionPageDocument, {id: argv.id, actionPage})
  if (errors) { throw errors }
}

interface UpsertCampaign {
  id?: number,
  name?: string,
  title?: string
}

export async function upsertCampaign(argv : UpsertCampaign & FormatOpts, config : CliConfig) {
  const c = client(config)
  const fmt = getFormatter(argv)

  const campaign  : types.CampaignInput = {
    name: argv.name,
    title: argv.title,
    actionPages: []
  }

  const {data, errors} = await request(c, admin.UpsertCampaignDocument, {org: config.org, campaign})
  if (errors) throw errors

  console.log(`Created campaign id: ${data.upsertCampaign.id}`)
}

interface UpsertActionPage {
  campaign?: string,
  name?: string,
  locale?: string
}

export async function upsertActionPage(argv : UpsertActionPage & FormatOpts, config : CliConfig) {
  const c = client(config)
  const fmt = getFormatter(argv)

  const campaign  : types.CampaignInput = {
    name: argv.campaign,
    actionPages: [{
      name: argv.name, locale: argv.locale
    }]
  }

  const {data, errors} = await request(c, admin.UpsertCampaignDocument, {org: config.org, campaign})
  if (errors) throw errors

  console.log(`Created action page`)
}
