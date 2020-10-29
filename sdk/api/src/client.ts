/*
  NodeJS compatibile Apollo Client 

  GraphQL, JavaScript and TypeScript is just a big ball of mud and this is why
  this file is terrible.

  Apollo Link is the abstract type of link inplemented by "transports", that
  know how to deliver a query to the server. The transport can ble "split" so
  there is a different method to run query or mutation (normal HTTP call), then
  import 'corss-fetch/pollyfill'
  to run subscription (Websocket).

  On top of that, the WebSocket is a layered interface, custom for each server
  (Apollo GraphQL implementation differs from how Phoenix/Absinthe handles
  things). For instance, the Phoenix websocket is multiplexing data and absinthe
  is just one of the "channels". So we need to use a special PhoenixSocket that
  handles this, and then wrap it in an apollo compatible socket, to play with
  Apollo.

  On top of that, browser and nodejs have different implementations of
  WebSocket. Node is missing it and you need to use 'ws' package which is good
  except it is not compatible in the "typed" sense - it does not implement the
  whole standard. 'ws' package devs know that but say that you can go implement
  it your self or GTFO (https://github.com/websockets/ws/issues/1583).

  A picture is worth a thousand words so:

        ApolloLink
            |
          (query hasSubscription?)
           / \
          no  yes
         /     \
 httpLink     wsLink (Apollo Style)
               |
              AbsintheSocketLink (an adapter)
               |
              AbsintheSocket (Absinthe way of using the channel)
               |
              PhoenixSocket (Phoenix way of using the channel)
               |
              WebSocket (from 'ws' or browser native)

*/

// apollo stack
//import ApolloClient from "apollo-client"
//import {InMemoryCache} from "apollo-cache-inmemory"

import {split, ApolloLink, execute, makePromise, FetchResult, Observable} from "apollo-link"
import {parse} from "graphql"

// http stack
import {createHttpLink} from "apollo-link-http"

// websocket stack
import {createAbsintheSocketLink} from "@absinthe/socket-apollo-link"
import * as AbsintheSocket from "@absinthe/socket"
import {Socket as PhoenixSocket} from "phoenix"
import WebSocket from "ws"

// Types used in our queries
import { TypedDocumentNode as DocumentNode } from '@graphql-typed-document-node/core';
import { DefinitionNode } from 'graphql'

import {AuthHeader} from './auth'

type Extensions = {
  captcha?: string
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
export function apiUrls(hostUrl: string) {
  return {
    url: (hostUrl + '/api'),
    wsUrl: (hostUrl + '/socket').replace(/^http/, 'ws')
  }
}

// Create the client
export function link(url: string, auth?: AuthHeader) {
  const config = apiUrls(url)

  const phoenixSocket = new PhoenixSocket(config.wsUrl, {transport: "WebSocket"})

  // horrible hack, but @types/phoenix does not allow to pass WebSocket as
  // transport because it allows only strings. We set a dummy value and set the "private" transport
  // field here. yey
  const x = phoenixSocket as any
  x['transport'] = WebSocket

  const wsLink = createAbsintheSocketLink(AbsintheSocket.create(phoenixSocket));
  const httpLink = createHttpLink({uri: config.url, headers: auth, includeExtensions: true})

  return split(
    (op) => hasSubscription(op.query),
    wsLink as ApolloLink,  // AbsintheSocketLink supposed to be compatible but a cast still needed.
    httpLink
  );
}

export async function request<Q,R>(link: ApolloLink, query: DocumentNode<Q,R>, variables: R, extensions?: Extensions) : Promise<FetchResult> {
  return makePromise(
    execute(link, {
      query,
      variables,
      extensions
    })
  )
}

export function subscribe<Q,R>(link: ApolloLink, query: DocumentNode<Q,R>, variables: R) : Observable<FetchResult> {
  return execute(link, {query, variables})
}
