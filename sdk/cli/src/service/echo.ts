import {ActionMessage} from '../queueMessage'
import {CliConfig} from '../config'
import {ServiceOpts} from '../cli'

export async function syncAction(action : ActionMessage, _1 : ServiceOpts, _2 : CliConfig) {
  console.log(JSON.stringify(action, null, 2))
}
