import csvStringify from 'csv-stringify/lib/sync'


const actionTypeEmojis = {
  petition: "✍️ ",
  register: "📥",
  share_click: "📣",
  share_close: "📣",
  twitter_click: "🐦",
  twitter_close: "🐦"
};

const actionTypeOtherEmoji = "👉";


class Terminal {
  constructor(options) {
    this.org = options.org
  }

  campaign(c) {
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
          const emoji = actionTypeEmojis[actionType] || actionTypeOtherEmoji;
          return `  ${emoji} ${actionType}: ${count}`
        })

        t += "\n" + x.join("\n")
      }
    }

    return t
  }

  actionPage(ap, org) {
    let t = ''
    if (ap.id && ap.name && ap.locale) {
      t += `${ap.id} ${ap.name} [${ap.locale}]`

      if (ap.extraSupporters != 0) {
        t += ` (🧑‍ ${ap.extraSupporters} extra supporters)`
      }

      if (ap.campaign) {
        const ex_id = ap.campaign.externalId ? `, ${ap.campaign.externalId}` : ''
        t += ` campaign: ${ap.campaign.name} (id: ${ap.campaign.id}${ex_id})`
      }
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
  addAPkeysToConfig(ap, org) {
    const c = JSON.parse(ap.config || '{}') || {}
    
    const m = {
      actionpage: ap.id,
      lang: ap.locale,
      journey: ap.journey,
      filename: ap.name
    }

    if (org && org.title) {
      m.organisation = org.title
    }

    return Object.assign(c, m)
  }

  addConfigKeysToAP(ap) {
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

  action(a) {
    const c = a.campaign !== undefined ? a.campaign.name : ''
    const t = `${a.actionId} ${a.createdAt}: [${c}] ${a.actionType} ${a.contact.contactRef}`
    return t
  }

  hasPublicKey(key, keyStore) {
    return keyStore && keyStore.keys.some((k) => k.public == key.public)
  }

  key(k, keys) {
    const present = this.hasPublicKey(k, keys)
    const active = k.expiredAt === null
    return `${k.public} [${present?"PRESENT":"ABSENT!"}] ${active?"ACTIVE":"EXPIRED: " + k.expiredAt} ${k.name}`
  }

  error(err) {
    if (err.response && err.response.errors) {
      const x = errs.map((e) => {
        return e.message
      })

      return x.join("\n")
    } else {
      return err
    }

  }
}


class Json extends Terminal {
  actionPage(ap, org) {
    const config = this.addAPkeysToConfig(ap, org)
    return JSON.stringify(config, null, 2)
  }

  action(a) {
    return JSON.stringify(a)
  }

}

class Csv extends Terminal {
  // not so smart because it generates CSV line by line
  // but for now this is not a big issue
  constructor(argv) {
    super(argv)
    this.campaignName = argv.campaign
    this.rowCount = 0
    this.fields = argv.fields.split(',')
  }

  getField(a, f) {
    const kv = a.fields.find(({key, value}) => key == f)
    if (kv !== undefined)
      return kv.value
    return ''
  }

  action(a) {
    const opts = {}
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

    return csvStringify([[
      a.campaign !== undefined ? a.campaign.name : this.campaignName,
      a.actionPage.name,
      a.actionType,
      a.contact.pii.firstName,
      a.contact.pii.lastName,
      a.contact.pii.email,
      a.contact.pii.phone,
      a.contact.pii.postcode,
      a.contact.pii.country,
      a.createdAt,
      a.actionId,
      a.privacy.optIn
    ].concat(
      this.fields.map((f) => this.getField(a, f))
    )], opts).slice(0, -1) // chomp newline
  }
}


export function getFormatter(argv) {
  if (argv.J) {
    return new Json(argv)
  } else if (argv.X) {
    return new Csv(argv)
  } else {
    return new Terminal(argv)
  }
}

