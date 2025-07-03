import bent from 'bent'
import debug from 'debug'
import {ActionMessageV2} from '../queueMessage'
import {CliConfig} from '../config'
import {ServiceOpts} from '.'
import {removeBlank} from '../util'

/*
 * How to configure Identity consent.
 *
 * Consents in speakout/identity have levels:
 * - none_given             # complex way to say: opt out
 * - implicit               # complex way to say: no checkbox, opt in assumed
 * - explicit_not_opt_out   # complex way to say: prechecked opt in
 * - explicit_opt_in        # complex way to say: checked opt in
 *
 * In Proca we have:
 * - opt_in: false/true
 * - email_status: null/double_opt_in
 *
 * Identity might require a few different consents (each for some different goal)
 * For identity we want to configure mapping
 * {
 *  data_processing_2022: { level: 'explicit_opt_in' }
 *  newsletter_v2: { level: 'communication' }  # will depend on Proca optIn ? 'explicit_opt_in' : 'none_given',
 *  newsletter_v3: { level: 'double_opt_in' }  # will depend on Proca double_opt_in ? 'explicit_opt_in' : 'none_given'
 * }
 *
 */

const log = debug('proca:service:identity')

type ConsentConfig = {
  [key: string]: Consent
}

type Consent = {
  level: "communication" | "double_opt_in" | "none_given" | "implicit" | "explicit_not_opt_out" | "explicit_opt_in",
  locale?: string
}

export async function syncAction(action : ActionMessageV2, argv : ServiceOpts, config : CliConfig) {
  const url = argv.service_url || config.identity_url
  const api_token = config.identity_api_token 
  const comm_consent = config.identity_consent
  const only_opt_in = 'IDENTITY_ONLY_OPT_IN' in process.env
  const only_double_opt_in = 'IDENTITY_ONLY_DOUBLE_OPT_IN' in process.env

  if (!url) throw new Error("identity url not set")
  if (!api_token) throw new Error("identity api token not set")

  // XXX the only_* mode indents to drop data where
  if (only_double_opt_in && action.privacy.emailStatus !== 'double_opt_in')  {
    return false;
  }
  if (only_opt_in && action.privacy.optIn === false) {
    return false;
  }

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

  const payload = toDataApi(action, consent, config.identity_action_fields, config.identity_contact_fields)
  log(`Identity DATA API payload (without api_token)`, payload)

  payload.api_token = api_token

  const post = bent(url, 'POST', 200)
  const r = await post('/api/actions', removeBlank(payload))
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

/* identity uses these keys to find Action
 * - external_id
 * - action_technical_type
 * - language
 */
export function toDataApi(action : ActionMessageV2,
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
    language: action.actionPage.locale,
    external_id: action.actionPageId,
    consents: Object.entries(consent_map).map(
      ([pub_id, con_conf]) => toConsent(action, pub_id, con_conf)
    ).filter(x => x),
    cons_hash: {
      firstname: action.contact.firstName,
      lastname: action.contact.lastName,
      emails: [{ email: action.contact.email }],
      custom_fields: [] as DataApiCustomField[],
      addresses: [{
        postcode: action.contact.postcode,
        country: action.contact.country,
        town: action.contact.locality,
        state: action.contact.region
      }]
    }
  }

  const custom_fields = []
  const metadata : Record<string, string> = {}

  custom_fields.push({name: "contactRef", value: action.contact.ref});

  for (const [key,value] of Object.entries(action.action.customFields)) {
    if ((action_fields || []).includes(key.toLowerCase())) {
      metadata[key] = `${value}`
    }

    if ((contact_fields || []).includes(key.toLowerCase())) {
      custom_fields.push({name: key, value: `${value}`})
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

export function toConsent(action : ActionMessageV2, consent_id : string, consent : Consent) {
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
  if (level === 'communication') {
    if (action.privacy) {
      if (action.privacy.optIn === true) {
        return {
          public_id: consent_id,
          consent_level: 'explicit_opt_in'
        }
      } else if (action.privacy.optIn === false) {
        return {
          public_id: consent_id,
          consent_level: 'none_given'
        }
      }
      // watch out, optIn key can be missing if this is non-consent action
    }
    return {
      public_id: consent_id,
      consent_level: 'no_change'
    }
  }

  if (level === 'double_opt_in') {
    if (action.privacy.emailStatus === 'double_opt_in')  {
      return {
        public_id: consent_id,
        consent_level: 'explicit_opt_in'
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
