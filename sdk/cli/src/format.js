import {createObjectCsvWriter} from 'csv-writer'


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
  constructor({org}) {
    this.org = org
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

      if (ap.extraSupporters > 0) {
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
    const c = JSON.parse(ap.config || '{}')
    
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

    // actionpage (id) should be passed in options
    ap.locale = config.lang || ap.locale
    delete config.lang

    ap.journey = config.journey || ap.journey
    delete config.journey

    ap.filename = config.name || ap.filename
    delete config.name

    // organisation - we ignore it

    ap.config = JSON.stringify(config)

    return ap
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

}


export function getFormatter(argv) {
  if (argv.J) {
    return new Json(argv)
  } else {
    return new Terminal(argv)
  }
}

