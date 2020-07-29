import debug from 'debug'
import bent from 'bent'

const log = debug('proca:service:identity')

export async function syncAction(action, config) {
  const url = config.service_url
  const api_token = config.identity_api_token
  const comm_consent = config.identity_consent

  let consent = {}
  if (comm_consent === null) {
    log('ProcaCli config.identity_consent is not set')
    throw "Please set IDENTITY_CONSENT"
  }
  if (comm_consent[0] == "{") {
    log('ProcaCli config.identity_consent has JSON config')
    // this is a hash with consent map
    consent = JSON.parse(comm_consent)
  } else {
    log(`ProcaCli config.identity_consent uses ${comm_consent} as commmunication consent`)
    consent[comm_consent] = { level: 'communication' }
  }

  if (action.contact.pii === null) {
    log(`Cannot decrypt PII; sender key is ${action.contact.signKey}`)
    throw "Cannot decrypt personal data, please check KEYS"
  }

  const payload = toDataApi(action, consent)
  log(`Identity DATA API payload (without api_token)`, payload)

  payload.api_token = api_token

  const post = bent(url, 'POST', 200)
  const r = await post('/api/actions', payload)
  return r
}


/* 
   PROCA ACTION JSON
   {
   "action":{
   "actionType":"download",
   "createdAt":"2020-06-15T10:10:23",
   "fields":{
   "postcardUrl":"https://pepe"
   }
   },
   "actionId":73,
   "actionPage":{
   "locale":"de",
   "thankYouTemplateRef":null,
   "url":"https://campax.org/1"
   },
   "actionPageId":4,
   "campaign":{
   "name":"r1"
   },
   "campaignId":3,
   "contact":{
   "email":"dump+test2@cahoots.pl",
   "firstName":"Mee",
   "pii": {
   "birth_date":"1990-10-12",
   "email":"dump+test2@cahoots.pl",
   "first_name":"Mee",
   "last_name":"Bacheli",
   "locality":"Vissay",
   "postcode":"1234",
   "region":"Canton1"
   },
   "payload":"{\"birth_date\":\"1990-10-12\",\"email\":\"dump+test2@cahoots.pl\",\"first_name\":\"Mee\",\"last_name\":\"Bacheli\",\"locality\":\"Vissay\",\"postcode\":\"1234\",\"region\":\"Canton1\"}",
   "ref":"GiYjjcsLwOBSdBvNEYMk6TLRe8b1-eYPNJuwD2eT8sA"
   },
   "orgId":3,
   "privacy":{
   "communication":true,
   "givenAt":"2020-06-15T10:10:23Z"
   },
   "schema":"proca:action:1",
   "source":null,
   "stage":"deliver"
}
*/ 

export function toDataApi(action, consent_map) {
  const ah = {
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
      addresses: [{
        postcode: action.contact.pii.postcode,
        country: action.contact.pii.country,
        town: action.contact.pii.locality,
        state: action.contact.pii.region
      }]
    }
  }

  if (action.action.fields.length > 0) {
    ah['custom_fields'] = Object.entries(action.action.fields).map(([k,v]) => { return {'name': k, 'value': v}})
  }

  if (action.source) {
    ah['source'] = {
      campaign: action.source.campaign,
      source: action.source.source,
      medium: action.source.medium,
    }
  }

  if (action.action.fields) {
    ah['metadata'] = action.action.fields
  }

  return ah
}
export function toConsent(action, consent_id, {level, locale}) {
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

  throw `unsuported config for consent ${consent_id}: ${level} for locale ${locale}`
}
