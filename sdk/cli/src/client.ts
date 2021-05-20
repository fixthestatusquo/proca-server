
import {CliConfig} from './config'
import {basicAuth, BasicAuth, link, jsonExchange} from '@proca/api'
import {Exchange, debugExchange, exchange} from '@urql/core'


export default function getClient(config : CliConfig) : any {
  let a = null
  if (config.username && config.password) {
    a = basicAuth(config as BasicAuth)
  }
  let c = link(config.url, a, {exchanges: [debugExchange, jsonExchange]})
  return c
}
