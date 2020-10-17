
import {link, basicAuth} from '@proca/api'

export default function getClient(argv) {
  let a = null
  if (argv.user && argv.password) {
    a = basicAuth({username: argv.user, password: argv.password})
  }
  let c = link(argv.host, a)
  return c
}
