import {GraphQLClient} from 'graphql-request'

export function client(url: string) {
  const client = new GraphQLClient(url)
  return client
}
