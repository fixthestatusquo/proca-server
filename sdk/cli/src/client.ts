
import {CliConfig} from './config'
import createSerializeScalarsExchange from 'urql-serialize-scalars-exchange';
import {basicAuth, BasicAuth, link, scalarSerializers } from '@proca/api'
import {scalarLocations} from './proca';



export default function getClient(config : CliConfig) : any {
  let a = null
  if (config.username && config.password) {
    a = basicAuth(config as BasicAuth)
  }
  let c = link(config.url, a, {exchanges: [createSerializeScalarsExchange(scalarLocations, scalarSerializers)]})
  return c
}
