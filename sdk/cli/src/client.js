
import {link, basicAuth} from '@proca/api'

export default function getClient(config) {
  let a = null
  if (config.username && config.password) {
    a = basicAuth(config)
  }
  let c = link(config.url, a)
  return c
}
