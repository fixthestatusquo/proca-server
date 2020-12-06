import bent from 'bent'
import debug from 'debug'
import {ActionMessage} from '../queueMessage'
import {CliConfig} from '../config'
import {ServiceOpts} from '../cli'


const log = debug('proca:service:identity')

type ConsentConfig = {
  [key: string]: Consent
}

type Consent = {
  level: "communication" | "none_given" | "implicit" | "explicit_not_opt_out" | "explicit_opt_in",
  locale?: string
}

export async function syncAction(action : ActionMessage, argv : ServiceOpts, config : CliConfig) {
  const url = argv.service_url
  const api_token = config.identity_api_token
  const comm_consent = config.identity_consent

  let consent : ConsentConfig = null
  if (comm_consent === null || comm_consent === undefined) {
    log('ProcaCli argv.identity_consent is not set')
    throw "Please set IDENTITY_CONSENT"
  }
  if (comm_consent[0] == "{") {
    log('ProcaCli argv.identity_consent has JSON argv')
    // this is a hash with consent map
    consent = JSON.parse(comm_consent)
  } else {
    log(`ProcaCli argv.identity_consent uses ${comm_consent} as commmunication consent`)
    consent = {}
    consent[comm_consent] = { level: 'communication' }
  }

  if (Object.keys(action.contact.pii).length == 0) {
    log(`Cannot decrypt PII; sender key is ${action.contact.signKey}`)
    throw "Cannot decrypt personal data, please check KEYS"
  }

  const payload = toDataApi(action, consent, config.identity_action_fields, config.identity_contact_fields)
  log(`Identity DATA API payload (without api_token)`, payload)

  payload.api_token = api_token

  const post = bent(url, 'POST', 200)
  const r = await post('/api/actions', payload)
  return r
}


type DataApiCustomField = {
  name: string,
  value: string
}

type DataApiSource = {
  source: string,
  medium: string,
  campaign: string
}

export function toDataApi(action : ActionMessage,
                          consent_map : ConsentConfig,
                          action_fields : string[],
                          contact_fields : string[]) {
  const ah = {
    api_token: null as string,
    metadata: {} as Record<string,string>,
    source: null as DataApiSource,
    action_type: action.action.actionType,
    action_technical_type: `proca:${action.action.actionType}`,
    create_dt: action.action.createdAt,
    action_name: action.campaign.name,
    action_public_name: action.campaign.name,
    external_id: action.campaignId,
    consents: Object.entries(consent_map).map(
      ([pub_id, con_conf]) => toConsent(action, pub_id, con_conf)
    ).filter(x => x),
    cons_hash: {
      firstname: action.contact.pii.firstName,
      lastname: action.contact.pii.lastName,
      emails: [{ email: action.contact.pii.email }],
      custom_fields: [] as DataApiCustomField[],
      addresses: [{
        postcode: action.contact.pii.postcode,
        country: action.contact.pii.country,
        town: action.contact.pii.locality,
        state: action.contact.pii.region
      }]
    }
  }

  const custom_fields = []
  const metadata : Record<string, string> = {}

  for (const [key,value] of Object.entries(action.action.fields)) {
    if ((action_fields || []).includes(key.toLowerCase())) {
      metadata[key] = value
    }

    if ((contact_fields || []).includes(key.toLowerCase())) {
      custom_fields.push({name: key, value: value})
    }
  }

  if (Object.keys(metadata).length > 0)
    ah.metadata = metadata

  if (custom_fields.length > 0)
    ah.cons_hash.custom_fields = custom_fields


  if (action.tracking) {
    ah.source = {
      campaign: action.tracking.campaign,
      source: action.tracking.source,
      medium: action.tracking.medium,
    }
  }

  return ah
}

export function toConsent(action : ActionMessage, consent_id : string, consent : Consent) {
  const {level, locale} = consent
  // Skip if this is not this locale
  if (locale && locale.toLowerCase() != action.actionPage.locale.toLowerCase())
    return null;

  // If it's a hardcoded consent, send it
  if (level == 'implicit' || level == 'explicit_opt_in')
    return {
      public_id: consent_id,
      consent_level: level
    }

  // Handle opt in to communication
  if (level == 'communication') {
    if (action.privacy) {
      if (action.privacy.communication) {
        return {
          public_id: consent_id,
          consent_level: 'explicit_opt_in'
        }
      } else {
        return {
          public_id: consent_id,
          consent_level: 'none_given'
        }
      }
    } else {
      return {
        public_id: consent_id,
        consent_level: 'no_change'
      }
    }
  }

  throw `unsuported argv for consent ${consent_id}: ${level} for locale ${locale}`
}
