import bent from 'bent'


export async function syncAction(action, config) {
  console.info(action)
  const url = config.service_url
  const api_token = config.identity_api_token
  const comm_consent = config.identity_consent

  let consent = {}
  if (comm_consent === null) {
    throw "Please set IDENTITY_CONSENT"
  }
  consent[comm_consent] = 'communication'

  const payload = toDataApi(action, consent)

  payload.api_token = api_token

  const post = bent(url, 'POST', 200)
  console.info(payload)
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
    create_dt: action.action.createdAt,
    action_name: action.campaign.name,
    action_public_name: action.campaign.name,
    external_id: action.campaignId,
    consents: Object.entries(consent_map).map(([pub_id, con_conf]) => toConsent(action, pub_id, con_conf)),
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

// XXX add source

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
