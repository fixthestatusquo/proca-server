import backoff from 'backoff'
import {CliConfig} from '../config'
import {ActionMessage, ProcessStage} from '../queueMessage'

export type SyncFunction = (action : ActionMessage, argv : ServiceOpts, config : CliConfig) => any


export interface ServiceOpts {
  service?: string,
  service_url?: string,
  queueName?: string,
  backoff?: boolean,
  filePath?: string
}

export function getService(argv : ServiceOpts) {
  if (typeof argv.service === 'string') {
    let service = require(`./${argv.service}`);
    if (argv.backoff) {
      service.syncAction = addBackoff(service.syncAction);
    }
    return service
  }

  if (typeof argv.service === 'object') {
    return argv.service
  }

  throw "argv.service should be a name of module in src/service or function"
}


export function addBackoff(fun : SyncFunction) {
  async function newFun(...args : any[]) : Promise<any> {
    return new Promise((ok, fail) => {
      const bo = backoff.exponential({
        randomisationFactor: 0,
        initialDelay: 100,
        maxDelay: 30000
      });
      bo.failAfter(10)
      bo.on('ready', function(number, delay) {
        try {
          fun.apply(null, args).then((r : any) => ok(r )).catch((err : Error) => {
            console.log(`😵 rejected: ${err}`)
            bo.backoff()
          })
        } catch(error : any) {
          console.log(`😵 exception: ${error}`)
          bo.backoff()
        }
      })

      bo.on('fail', () => fail('failed too many times'))

      bo.backoff()
    })
  }
  return newFun
}
