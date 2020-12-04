
import {CliConfig} from './config'
import {basicAuth, BasicAuth, link} from '@proca/api'

export default function getClient(config : CliConfig) {
  let a = null
  if (config.username && config.password) {
    a = basicAuth(config as BasicAuth)
  }
  let c = link(config.url, a)
  return c
}
