import {GraphQLClient} from 'graphql-request'
import 'cross-fetch/polyfill';
import {encode} from 'js-base64';


export function authBasic(client: GraphQLClient, username: String, password: String) {
  const up = username + ":" + password
  const baseup = encode(up)
  client.setHeader("authorization", "Basic " + baseup)
  return client
}

export function authToken(client: GraphQLClient, token: String) {
  client.setHeader("authorization", "Bearer " + token)
  return client
}
