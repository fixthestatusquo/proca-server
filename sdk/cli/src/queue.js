import amqplib from 'amqplib'
import backoff from 'backoff'
import {decryptAction} from './crypto'


export function connect(argv) {
  if (!argv.queue) {
    throw Error("Please configure queue url with -q or QUEUE_URL")
  }
  return amqplib.connect(argv.queue)
}

function queueName(type, argv) {
  if (type == 'deliver' || type == 'confirm') {
    return `custom.${argv.org}.${type}`
  }
  throw Error("queue type must by either deliver or configm")
}

export async function testQueue(argv) {
  const conn = await connect(argv)
  const ch = await conn.createChannel()
  try {
    const status = await ch.checkQueue(queueName('deliver', argv))
    console.log(status)
    return status
  } finally {
    ch.close()
    conn.close()
  }
}

function getService(argv) {
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


export async function syncQueue(argv, config) {
  const conn = await connect(argv)
  const ch = await conn.createChannel()
  const qn = queueName('deliver', argv)
  const service = getService(argv)
  let consumerTag = null
  console.error(`⏳ waiting for actions from ${qn}`)

  return new Promise(async (ok, fail) => {
    const ret = await ch.consume(qn, (msg) => {
      let action = JSON.parse(msg.content.toString())

      action = decryptAction(action, argv)

      const syncing = service.syncAction(action, argv, config)
            .then((v) => {
              ch.ack(msg)
            })
            .catch((e) => {
              ch.nack(msg)
              ch.cancel(consumerTag)
              ch.close()
              conn.close()
              fail(e)
            })
    })
    consumerTag = ret.consumerTag
  })
}


export function addBackoff(fun) {
  async function newFun(...args) {
    return new Promise((ok, fail) => {
      const bo = backoff.exponential({
        randomisationFactor: 0,
        initialDelay: 100,
        maxDelay: 30000
      });
      bo.failAfter(10)
      bo.on('ready', function(number, delay) {
        try {
          fun.apply(null, args).then((r) => ok(r)).catch((err) => {
            console.log(`😵 rejected: ${err}`)
            bo.backoff()
          })
        } catch(error) {
          console.log(`😵 exception: ${err}`)
          bo.backoff()
        }
      })

      bo.on('fail', () => fail('failed too many times'))

      bo.backoff()
    })
  }
  return newFun
}
