global.fetch = require("node-fetch");
import { request, GraphQLClient} from 'graphql-request'
import {decrypt} from './crypto'


export function client({url, user, password}) {
  var auth = 'Basic ' + Buffer.from(user + ':' + password).toString('base64')
  const c = new GraphQLClient(`${url}/api`, {
    headers: {
      authorization: auth,
    },
  })
  return c
}


export async function campaigns(client, org) {
  const query = `query Org($org: String!) {
    org(name: $org) {
      campaigns {
        id, title, name,
        org { title },
        stats {
          supporterCount, actionCount { actionType, count }
        }
      }
    }
  }`
  return client.rawRequest(query, { org })
}

export async function streamSignatures(client, org, campaignId, cb) {
  const varCampaignId = campaignId !== null ? ', campaignId: $campaignId' : ''
  const query = `query GetSigs($org: String!, $start: Int!, $limit: Int!, $campaignId: Int) {
    org(name: $org) {
      signatures(start: $start, limit: $limit ${varCampaignId}) {
        publicKey, list {
          campaignId, actionPageId, contact, created, id, nonce, optIn
        }
      }
    }
  }`
  let idx = 0

  for (;;) {
    const start = idx + 1
    const limit = 10
    const ret = await client.rawRequest(query, { org, campaignId, start, limit})
    const sigs = ret.data.org.signatures.list
    const count = sigs.length

    if (count == 0)
      break;

    idx = sigs[count-1].id

    cb(ret.data.org.signatures)
  }

  return
}

module.exports = {
  client,
  campaigns,
  streamSignatures
}

/*
query Li {
  org(name:"test") {
    campaigns {
      title, name 
    }
  }
}
  */
