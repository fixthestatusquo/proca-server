import amqplib from 'amqplib'
import backoff from 'backoff'
import {decryptAction, DecryptOpts} from './crypto'
import {CliConfig} from './config'
import {CliOpts, ServiceOpts} from './cli'
import {ActionMessage} from './queueMessage'

export type ProcessStage = "confirm" | "deliver"
export type SyncFunction = (action : ActionMessage, argv : ServiceOpts, config : CliConfig) => any


export function connect(config : CliConfig) {
  if (!config.queue_url) {
    throw Error("Please configure queue url with -q or QUEUE_URL")
  }
  return amqplib.connect(config.queue_url) as any
}

function queueName(type : ProcessStage, argv:CliOpts) {
  if (type == 'deliver' || type == 'confirm') {
    return `custom.${argv.org}.${type}`
  }
  throw Error("queue type must by either deliver or configm")
}

export async function testQueue(opts : ServiceOpts, config : CliConfig) {
  const conn = await connect(config)
  const ch = await conn.createChannel()
  try {
    const status = await ch.checkQueue(opts.queueName || queueName('deliver', config))
    console.log(status)
    return status
  } finally {
    ch.close()
    conn.close()
  }
}

function getService(argv : ServiceOpts) {
  if (typeof argv.service === 'string') {
    let service = require(`./service/${argv.service}`);
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


export async function syncQueue(opts : ServiceOpts & DecryptOpts, config:CliConfig) {
  const conn = await connect(config)
  const ch = await conn.createChannel()
  const qn = opts.queueName || queueName('deliver', config)
  const service = getService(opts)
  let consumerTag :string = null
  console.error(`⏳ waiting for actions from ${qn}`)

  return new Promise(async (_, fail) => {
    const ret = await ch.consume(qn, (msg : amqplib.Message) => {
      let action = JSON.parse(msg.content.toString())

      action = decryptAction(action, opts, config)

      const syncing = service.syncAction(action, opts, config)
        .then((v : any) => {
          ch.ack(msg)
        })
        .catch((e : Error) => {
          ch.nack(msg)
          ch.cancel(consumerTag)
          ch.close()
          conn.close()
          console.error('failure to syncAction:', e)
          fail(e)
        })
    })
    consumerTag = ret.consumerTag
  })
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
