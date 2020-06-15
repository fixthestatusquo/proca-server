import request from 'request'

function actionsApiUrl(identity_url, config) {
  const format = /^https?:\/\/[\w\d_.-]+$/
  if (!identity_url || !identity_url.match(format)) {
    throw "Use https://just.identity.host for identity service_url"
  }

  return `${identity_url}/api/actions`
}



export async function syncAction(action, config, argv) {
  const url = actionsApiUrl(argv.service_url || process.env.IDENTITY_URL, config)
  const api_token = process.env.IDENTITY_API_TOKEN
  const comm_consent = process.env.IDENTITY_CONSENT

  let consent = {}
  if (comm_consent === null) {
    throw "Please set IDENTITY_CONSENT"
  }
  consent[comm_consent] = 'communication'

  const payload = toDataApi(action, consent)
  console.log(payload)
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
   "locale":"en",
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

function toDataApi(action, consent_map) {
  const ah = {
    action_type: action.action.actionType,
    action_technical_type: `proca:${action.action.actionType}`,
    created_dt: action.action.createdAt,
    action_name: action.campaign.name,
    action_public_name: action.campaign.name,
    external_id: action.campaignId,
    consents: Object.entries(consent_map).map(([pub_id, con_conf]) => toConsent(action, pub_id, con_conf)),
    cons_hash: {
      firstname: action.contact.pii.first_name,
      lastname: action.contact.pii.last_name,
      emails: [{ email: action.contact.pii.email }],
      addr: {
        zip: action.contact.pii.postcode,
        country: action.contact.pii.country
      }
    }
  }

  if (action.action.fields.length > 0) {
    ah['custom_fields'] = Object.entries(action.action.fields).map(([k,v]) => { return {'name': k, 'value': v}})
  }

  return ah
}

function toConsent(action, consent_id, consent_config) {
  if (consent_config == 'implicit' || consent_config == 'explicit') {
    return {
      public_id: consent_id,
      consent_level: consent_config
    }
  } else if (consent_config == 'communication') {
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
}
