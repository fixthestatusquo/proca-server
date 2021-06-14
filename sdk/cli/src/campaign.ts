
import client from './client'
import {request, types} from '@proca/api'
import * as admin from './proca'
import {getFormatter, FormatOpts, isPrivateCampaign} from './format'
import fs from 'fs'
import {CliConfig} from './config'
import {removeBlank} from './util';


export async function listCampaigns(argv : FormatOpts, config : CliConfig) {
  const c = client(config)
  const fmt = getFormatter(argv)

  const result = await request(c, admin.ListCampaignsDocument, {"org": config.org})
  if (result.error) throw result.error

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

  const {data, error} = await request(c, admin.GetCampaignDocument, {"org": config.org, "id": argv.id})

  if (error) throw error

  const campaign = data.org.campaign;
  console.log(fmt.campaign(campaign))

  console.log(fmt.campaignStats(campaign))
}


export async function listActionPages(argv : FormatOpts, config : CliConfig) {
  const c = client(config)
  const fmt = getFormatter(argv)

  const {data, error} = await request(c, admin.ListActionPagesDocument, {"org": config.org})
  if (error) throw error

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
    const {data, error} = await request(c, admin.GetPublicActionPageDocument, vars)
    if (error) throw error
    t = fmt.actionPage(data.actionPage, data.actionPage.org)
    console.log(t)
    return data.actionPage
  } else {
    const {data, error} = await request(c, admin.GetActionPageDocument, vars)
    if (error) throw error
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

  if (argv.config) { // json
    if (argv.config[0] == '{') {
      json = argv.config
    } else {
      json = fs.readFileSync(argv.config, 'utf8')
    }
    json = JSON.parse(json)
  }
  let actionPage : admin.ActionPageInput = removeBlank({
    name: argv.name,
    thankYouTemplateRef: argv.tytpl,
    extraSupporters: argv.extra,
    config: json
  })

  if (argv.json) {
    actionPage = fmt.addConfigKeysToAP(actionPage)
  }

  let response 
  try {
    response = await request(c, admin.UpdateActionPageDocument, {id: argv.id, actionPage: { config: actionPage.config} })
  } catch (e) {
    console.error(e)
  }
  if (response.error) { 
    console.error(response.error)
    throw response.error 
  }
}

interface UpsertCampaign {
  id?: number,
  name?: string,
  title?: string
}

export async function upsertCampaign(argv : UpsertCampaign & FormatOpts, config : CliConfig) {
  const c = client(config)
  const fmt = getFormatter(argv)

  const campaign  : admin.CampaignInput = removeBlank({
    name: argv.name,
    title: argv.title,
    actionPages: []
  })

  const {data, error} = await request(c, admin.UpsertCampaignDocument, {org: config.org, campaign})
  if (error) throw error

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

  const campaign  : admin.CampaignInput = {
    name: argv.campaign,
    actionPages: [removeBlank({
      name: argv.name, locale: argv.locale
    })]
  }

  const {data, error} = await request(c, admin.UpsertCampaignDocument, {org: config.org, campaign})
  if (error) throw error

  console.log(`Created action page`)
}
