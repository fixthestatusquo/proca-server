import client from './client'
import {admin, subscribe} from '@proca/api'
import {getFormatter} from './format'
import {execSync} from 'child_process'

export async function watchPages(argv) {
  const c = client(argv)
  const fmt = getFormatter(argv)

  const orgName = argv.A ? null : argv.o

  const query = subscribe(c, admin.ActionPageUpsertedDocument, {org: orgName})

  const sub = query.subscribe(({data}) => {
        const ap = data.actionPageUpserted
        const t = fmt.actionPage(ap, ap.org)

        if (argv.x) {
          const output = execSync(argv.x, {input: t})
          console.info(output)
        } else {
          console.log(t)
        }
  })

  return sub
}
