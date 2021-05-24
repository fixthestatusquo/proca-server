import client from './client'
import {admin, subscription, subscribe, types} from '@proca/api'
import {getFormatter,FormatOpts} from './format'
import {execSync} from 'child_process'
import {CliConfig} from './config'
import util from 'util'

interface WatchOpts {
  all: boolean,
  org?: string,
  exec?: string
}

export async function watchPages(argv : WatchOpts & FormatOpts, config: CliConfig) {
  const c = client(config)
  const fmt = getFormatter(argv)

  const orgName = argv.all ? null : argv.org

  const query = subscription(c, admin.ActionPageUpsertedDocument, {org: orgName})

  const sub = subscribe(query, (x) => {
    console.log('sub: '+util.inspect(x, {depth: 10}))
    const {data} = x
    const ap = data.actionPageUpserted;
    const t = fmt.actionPage(ap as types.PublicActionPage, ap.org)

    if (argv.exec) {
      try {
        const output = execSync(argv.exec, { input: t })
        console.info(output.toString())
      } catch (e) {
        console.error(`-- Error from command ${argv.exec} ------------`)
        if (e.stdout) {
          console.log(e.stdout.toString())
        }
        if (e.stderr) {
          console.error(e.stderr.toString())
        } else {
          console.error(e)
        }
      }
    } else {
      console.log(t)
    }
  })


  return sub as any
}
