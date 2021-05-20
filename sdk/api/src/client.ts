/*
  NodeJS compatibile Apollo Client


*/

// apollo stack

import {createClient, Client, OperationResult, Exchange, dedupExchange, fetchExchange} from '@urql/core';
import {Source, subscribe as makeSink, pipe} from 'wonka';



// websocket stack
import createAbsintheExchange from './absintheExchange'

// Types used in our queries
import { TypedDocumentNode as DocumentNode } from '@graphql-typed-document-node/core';
import { DefinitionNode } from 'graphql'

import {AuthHeader} from './auth'

type Extensions = {
  captcha?: string
}

type Error = {
  message: string,
  extensions?: {
    [key: string]: string
  },
  path: string[],
  locations: [ [Object] ],
}

export interface ExecutionErrors {
  errors?: Error[]
}

type LinkOptions = {
  wsUrl?: string,
  exchanges: Exchange[]
}

// hasSubscription - helper func to see if we have an operation with subscription
// taken from @jumpn/utils-graphql which is not really useful as has not types
function isSubscription(definition: DefinitionNode) {
  return definition.kind === "OperationDefinition" &&
    definition.operation === "subscription"
}

function hasSubscription(documentNode: DocumentNode): boolean {
  return documentNode.definitions.some(isSubscription)
}

// structure of http/ws endpoints
// Will use /api, /socket with no path given.
// Otherwise will use the path for HTTP api, and /socket for WS.
// You can provide a complete url or path for websocket in second argument
export function apiUrls(apiUrl: string, wsUrl = "/socket") {
  const api = new URL(apiUrl)
  let ws : URL = null

  if (api.pathname == '/') {
    api.pathname = '/api'
  }

  try {
    ws = new URL(wsUrl)
  } catch (e) {
    if (e instanceof TypeError) {
      // consider a path
      ws = new URL(apiUrl)
      ws.pathname = wsUrl
    } else {
      throw e;
    }
  }

  return {
    url: api.href ,
    wsUrl: ws.href
  }
}

function apiUrlsConfig (url: string, options?: LinkOptions) {
  if (url === null || url === undefined) {
    throw new Error("api url must not be null or undefined")
  }
  const config = apiUrls(url, options ? options.wsUrl : undefined)
  return config;
  
}

export function link(url: string, auth?: AuthHeader, options?: LinkOptions) {
  const config = apiUrlsConfig(url, options);

  const absintheExchange = createAbsintheExchange(config.wsUrl)

  const exchanges = [dedupExchange, fetchExchange, absintheExchange]
  if (options.exchanges) exchanges.splice(1, 0, ...options.exchanges)

  const link = createClient({url: config.url, fetchOptions: {headers: auth}, exchanges})

  return link
}

export function httpLink(url: string, auth?: AuthHeader, options?: LinkOptions) {
  const config = apiUrlsConfig(url, options)

  const exchanges = [dedupExchange, fetchExchange]
  if (options.exchanges) exchanges.splice(1, 0, ...options.exchanges)

  const httpLink = createClient({url: config.url, fetchOptions: {headers: auth}})
  return httpLink
}

/**
 * Because the query document has a generic type narrowed for <Q - thing we get, R - arguments we send>,
 * these two generics are used to cast the result:
 * it is composed from:
 * - ExecutionResult: data: Q
 * - ExecutionErrors: errors?: Error  - not sure why apollo-link does not provide this type
 * - FetchResult: other keys like extensions
 *
 */


export async function request<Q,R>(
  link: Client,
  query: DocumentNode<Q,R>,
  variables: R,
  extensions?: Extensions) : Promise<OperationResult<Q, R>> {
    const res = link.query(query, variables as undefined as object).toPromise();
    return res as undefined as Promise<OperationResult<Q,R>>;
}

export function subscription<Q,R>(
  link: Client,
  query: DocumentNode<Q,R>,
  variables: R
)  {
  const source = link.subscription(query, variables as unknown as object)
  return source as undefined as Source<OperationResult<Q,R>>
}

export function subscribe<Q,R>(
  source: Source<OperationResult<Q,R>>,
  callback : (event : OperationResult<Q,R>)=>void
) {
  const sink = makeSink(callback)

  return pipe(
    source,
    sink
  ) // returns [unsubscribe] fun
}



