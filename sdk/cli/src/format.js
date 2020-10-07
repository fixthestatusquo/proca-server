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
    let t = c.id
    if (c.externalId) {
      t = t + ` (external: ${c.externalId})`
    }
    t = t + ` 🏁 ${c.name}: ${c.title}`

    if (c.org && this.org !== c.org.name) {
      t = t + ` partner of ${c.org.name} (${c.org.title})`
    }

    if (c.stats) {
      t = t + ` (🧑‍ ${c.stats.supporterCount} supporters)`
    }
    return t
  }

  campaignStats(c) {
    const t = c.stats.actionCount.map(({actionType, count}) => {
      const emoji = actionTypeEmojis[actionType] || actionTypeOtherEmoji;
      return `  ${emoji} ${actionType}: ${count}`
    })

    return t.join("\n")
  }

  errors(errs) {
    const x = errs.map((e) => {
      return e.message
    })

    return x.join("\n")
  }
}


export function getFormatter(argv) {
  return new Terminal(argv)
}
