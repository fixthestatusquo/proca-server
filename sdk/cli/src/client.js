
import {client, authBasic} from '@proca/api'

export default function getClient(argv) {
  let c = client(argv.url)
  if (argv.user && argv.password) {
    c = authBasic(c, argv.user, argv.password)
  }
  return c
}
