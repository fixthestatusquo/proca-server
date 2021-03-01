import csvStringify from 'csv-stringify/lib/sync'
import {admin,types} from '@proca/api'
import {ActionWithPII, KeyStore} from './crypto'
import {WidgetConfig} from './config'
import {ActionFromExport} from './export'


export interface FormatOpts {
  org?: string,
  json?: boolean,
  csv?: boolean,
  campaign?: string,
  fields?: string,
  indent?: number,
}

interface OrgDetails {
  title?: string
  name: string
}

function isPublicActionPage(ap: types.ActionPage | types.PublicActionPage):  ap is types.PublicActionPage {
  return (ap as types.ActionPage).extraSupporters === undefined
}

const actionTypeEmojis : { [key: string]: string } = {
  petition: "✍️ ",
  register: "📥",
  share_click: "📣",
  share_close: "📣",
  twitter_click: "🐦",
  twitter_close: "🐦"
};

const actionTypeOtherEmoji = "👉";


class Terminal {
  org: string

  constructor(options : FormatOpts) {
    this.org = options.org
  }

  campaign(c : types.Campaign) {
    let t = `${c.id}`
    if (c.externalId) {
      t += ` (external: ${c.externalId})`
    }
    t += ` 🏁 ${c.name}: ${c.title}`

    if (c.org && this.org !== c.org.name) {
      t += ` partner of ${c.org.name} (${c.org.title})`
    }

    if (c.stats) {
      t += ` (🧑‍ ${c.stats.supporterCount} supporters)`

      if (c.stats.actionCount) {
        const x = c.stats.actionCount.map(({actionType, count}) => {
          const emoji = actionTypeEmojis[actionType] || actionTypeOtherEmoji

          return `    ${emoji} ${actionType}: ${count}`
        })

        t += "\n" + x.join("\n")
      }
    }

    return t
  }


  actionPage(ap : types.ActionPage | types.PublicActionPage, org : any) {
    let t = ''
    if (ap.id && ap.name && ap.locale) {
      t += `${ap.id} ${ap.name} [${ap.locale}]`

      if ('extraSupporters' in ap && ap.extraSupporters != 0) {

        t += ` (🧑‍ ${ap.extraSupporters} extra supporters)`
      }

      if (ap.campaign) {
        const ex_id = ap.campaign.externalId ? `, ${ap.campaign.externalId}` : ''
        t += ` campaign: ${ap.campaign.name} (id: ${ap.campaign.id}${ex_id})`
      }
    }

    if (ap.thankYouTemplateRef) {
      t += `\nThankYou email template: ${ap.thankYouTemplateRef}`
    }

    if (ap.config) {
      const conf = JSON.parse(ap.config)
      t += t ? "\n" : ""
      t += JSON.stringify(conf, null, 2)
    }

    return t
  }

  // The standalone json files used to generate widget for action page
  // is using a different format today
  addAPkeysToConfig(ap : types.ActionPage, org : OrgDetails) {
    const c = JSON.parse(ap.config || '{}') || {}

    const pickLead = ({name, title} : {name: string, title:string}) => ({name, title}); // argh! All this to pick sub-keys. Typescript is terrible.

    const m : WidgetConfig = {
      actionpage: ap.id,
      lang: ap.locale,
      journey: ap.journey,
      filename: ap.name,
      organisation: org.title || '',
      lead: ap.campaign?.org ? pickLead(ap.campaign.org) : undefined,
      campaign: ap.campaign ? {title: ap.campaign.title, name: ap.campaign.name} : undefined
    }

    return Object.assign(c, m)
  }

  addConfigKeysToAP(ap : types.ActionPageInput) {
    if (!ap.config) {
      return ap
    }
    const config = JSON.parse(ap.config)

    delete config.actionpage

    // actionpage (id) should be passed in options
    ap.locale = config.lang || ap.locale
    delete config.lang

    ap.journey = config.journey || ap.journey
    delete config.journey

    ap.name = config.filename || ap.name
    delete config.filename

    // organisation - we ignore it

    ap.config = JSON.stringify(config)

    return ap
  }

  action(a : ActionFromExport) {
    const c = a.campaign !== undefined ? a.campaign.name : ''
    const t = `${a.actionId} ${a.createdAt}: [${c}] ${a.actionType} ${a.contact.contactRef}`
    return t
  }

  hasPublicKey(key : types.Key, keyStore : KeyStore) {
    return keyStore && keyStore.keys.some((k) => k.public == key.public)
  }

  key(k : types.Key, keys : KeyStore) {
    const present = this.hasPublicKey(k, keys)
    return `[${present?"*":" "}] ${k.active?"active> ":"        "}${k.public} ${k.name} ${k.expired?"(expired: " + k.expiredAt +")" : ""}`
  }

  error(err : any) {
    if (err.response && err.response.errors) {
      const x = err.response.errors.map((e : any) => {
        return e.message || '(no error message)'
      })

      return x.join("\n")
    } else {
      return err
    }

  }
}


class Json extends Terminal {
  indent: number

  constructor(opts : FormatOpts) {
    super(opts)
    this.indent = opts.indent === undefined ? 2 : opts.indent
  }

  actionPage(ap : types.ActionPage, org : any) {
    const config = this.addAPkeysToConfig(ap, org)
    return JSON.stringify(config, null, this.indent)
  }

  action(a : ActionFromExport) {
    return JSON.stringify(a, null, this.indent)
  }

}

class Csv extends Terminal {
  rowCount: number
  campaignName: string
  fields: string[]

  // not so smart because it generates CSV line by line
  // but for now this is not a big issue
  constructor(argv : FormatOpts) {
    super(argv)
    this.campaignName = argv.campaign
    this.rowCount = 0
    this.fields = argv.fields.split(',')
  }

  getField(a : ActionFromExport, f : string) {
    const kv = a.fields.find(({key}) => key == f)
    if (kv !== undefined)
      return kv.value
    return ''
  }

  action(a : ActionFromExport) {
    let [input, opts] : Parameters<typeof csvStringify> = [[], {}]

    const pii = 'pii' in a.contact ? 
      (a.contact as ActionWithPII).contact.pii : undefined;

    if (this.rowCount == 0) {
      opts.columns = [
        'campaignName',
        'actionPageName',
        'actionType',
        'contact.first_name',
        'contact.last_name',
        'contact.email',
        'contact.phone',
        'contact.postcode',
        'contact.country',
        'created',
        'id',
        'optIn'
      ].concat(this.fields)

      opts.header = true
    }

    this.rowCount += 1

    input = [[
      a.campaign !== undefined ? a.campaign.name : this.campaignName,
      a.actionPage.name,
      a.actionType,
      pii?.firstName || '',
      pii?.lastName || '',
      pii?.email || '',
      pii?.phone || '',
      pii?.postcode || '',
      pii?.country || '',
      a.createdAt,
      a.actionId,
      a.privacy.optIn
    ].concat(
      this.fields.map((f) => this.getField(a, f))
    )]

    return csvStringify(input, opts).slice(0, -1) // chomp newline
  }
}


export function getFormatter(argv : FormatOpts) {
  if (argv.json) {
    return new Json(argv)
  } else if (argv.csv) {
    return new Csv(argv)
  } else {
    return new Terminal(argv)
  }
}
