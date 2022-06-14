/*
  NodeJS compatibile Apollo Client


*/

// apollo stack

import {
  createClient, Client, OperationResult, Exchange,
  dedupExchange, fetchExchange, OperationContext, PromisifiedSource
} from '@urql/core'
import {subscribe as makeSink, pipe} from 'wonka'
import util from 'util'
import {tap, Source} from 'wonka'

// websocket stack
import createAbsintheExchange from './absintheExchange'

// Types used in our queries
import { TypedDocumentNode } from '@graphql-typed-document-node/core';
import { DefinitionNode } from 'graphql'

import { AuthHeader, AuthHeaderFetcher, tokenAuth} from './auth'

type Extensions = {
  captcha?: string
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

function hasSubscription(documentNode:TypedDocumentNode): boolean {
  return documentNode.definitions.some(isSubscription)
}

function hasMutation(documentNode:TypedDocumentNode): boolean {
  return documentNode.definitions.some((def) =>
    def.kind === "OperationDefinition" && def.operation === "mutation");
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

function fetchOptions(auth? : AuthHeader | AuthHeaderFetcher) : RequestInit | (() => RequestInit) {
  if (!auth) return {};

  if (typeof auth === 'function') {
    return () => {
      const token = auth();
      if (token !== null) {
        return {headers: tokenAuth({token})}
      } else {
        return {}
      }
    }
  } else {
    return {headers: auth || {}}
  }
}

export function link(url: string, auth?: AuthHeader | AuthHeaderFetcher, options?: LinkOptions) {
  const config = apiUrlsConfig(url, options);

  const absintheExchange = createAbsintheExchange(config.wsUrl)

  const exchanges = [ dedupExchange, fetchExchange, absintheExchange]
  if (options?.exchanges) exchanges.splice(0, 0, ...options.exchanges)

  const link = createClient({url: config.url, fetchOptions: fetchOptions(auth), exchanges})

  return link
}

export function httpLink(url: string, auth?: AuthHeader | AuthHeaderFetcher, options?: LinkOptions) {
  const config = apiUrlsConfig(url, options)

  const exchanges = [dedupExchange, fetchExchange]
  if (options?.exchanges) exchanges.splice(0, 0, ...options.exchanges)

  const httpLink = createClient({url: config.url, fetchOptions: fetchOptions(auth), exchanges})
  return httpLink
}

/**
 * Because the query document has a generic type narrowed for <Q - thing we get, R - arguments we send>,
 * these two generics are used to cast the result:
 * it is composed from:
 * - OperationResult: data: Q
 * - CombinedError: error (from @urql/core)
 * - FetchResult: other keys like extensions
 *
 */


// XXX monkey patch urql type
// XXX If you encounter subtle TypedDocumentNode typescript discrepancies,
//     break the glass below and cast method
//
// the urql signature has:
// DocumentNode | TypeDocumentNode<Data, Variables>
// my suspicion is that TS inference chooses the first one
// and uses generic type info
//
// type UrqlMethod = <Data = any, Variables extends object = {}>(
//   query: TypedDocumentNode<Data, Variables>,
//   variables?: Variables,
//   context?: Partial<OperationContext>
// ) => PromisifiedSource<OperationResult<Data, Variables>>;

export async function request<Q,R extends object>(
  link: Client,
  query: TypedDocumentNode<Q,R>,
  variables: R,
  extensions?: Extensions) : Promise<OperationResult<Q, R>> {

  const method = hasMutation(query) ? link.mutation : link.query;
  return method(query, variables).toPromise();
}


// XXX If you encounter subtle TypedDocumentNode typescript discrepancies,
//     break the glass below and cast subscription
// type UrqlSubscription = <Data = any, Variables extends object = {}>(
//   query: TypedDocumentNode<Data, Variables>,
//   variables?: Variables,
//   context?: Partial<OperationContext>
// ) => Source<OperationResult<Data, Variables>>;

export function subscription<Q,R extends object>(
  link: Client,
  query:TypedDocumentNode<Q,R>,
  variables: R
)  {
  const subscription = link.subscription;
  return subscription(query, variables);
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



