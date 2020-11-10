
import client from './client'
import {admin, widget, request} from '@proca/api'
import {getFormatter} from './format'
import fs from 'fs'

export async function listCampaigns(argv, config) {
  const c = client(config)
  const fmt = getFormatter(argv)

  const {data, errors} = await request(c, admin.ListCampaignsDocument, {"org": config.org})
  if (errors) throw errors

  data.org.campaigns
    .map(c => fmt.campaign(c))
    .forEach((c) => {
      console.log(c)
    })
}

export async function getCampaign(argv, config) {
  const c = client(config)
  const fmt = getFormatter(argv)
  
  const {data, errors} = await request(c, admin.GetCampaignDocument, {"org": config.org, "id": argv.id})

  if (errors) throw errors

  console.log(fmt.campaign(data.org.campaign))
}


export async function listActionPages(argv, config) {
  const c = client(config)
  const fmt = getFormatter(argv)

  const {data, errors} = await request(c, admin.ListActionPagesDocument, {"org": config.org})
  if (errors) throw errors

  data.org.actionPages
    .map(ap => fmt.actionPage(ap))
    .forEach((ap) => {console.log(ap)})
}


export async function getActionPage(argv, config) {
  const c = client(config)
  const fmt = getFormatter(argv)

  let query = admin.GetActionPageDocument
  if (argv.public) query = widget.GetActionPageDocument

  let vars = {}
  if (argv.name) vars.name = argv.name
  if (argv.id) vars.id = argv.id
  if (!argv.public) vars.org = config.org

  const {data, errors} = await request(c, query, vars)
  if (errors) throw errors

  const ap = argv.public ? data.actionPage : data.org.actionPage

  let t = null
  t = fmt.actionPage(ap, data.org)
  console.log(t)
}


export async function updateActionPage(argv, config) {
  const c = client(config)
  const fmt = getFormatter(argv)

  let json = null

  // json
  if (argv.c) {
    if (argv.c[0] == '{') {
      json = argv.c
    } else {
      json = fs.readFileSync(argv.c, 'utf8')
    }
  }

  let ap_in = {
    id: argv.i,
    name: argv.name,
    thankYouTemplateRef: argv.tytpl,
    extraSupporters: argv.extra,
    config: json
  }

  if (argv.J) {
    ap_in = fmt.addConfigKeysToAP(ap_in)
  }

  // DEBUG
  // console.debug(`updateActionPage(${JSON.stringify(ap_in)})`)

  const {data, errors} = await request(c, admin.UpdateActionPageDocument, ap_in)
  if (errors) { throw errors }
}
