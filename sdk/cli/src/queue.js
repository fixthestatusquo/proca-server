import amqplib from 'amqplib'
import backoff from 'backoff'

export function connect(config) {
  if (!config.queue_url) {
    throw "Please configure queue url with -q or QUEUE_URL"
  }
  return amqplib.connect(config.queue_url)
}

function queueName(type, config) {
  if (type == 'deliver' || type == 'confirm') {
    return `custom.${config.org}.${type}`
  }
  throw "queue type must by either deliver or config"
}

export async function testQueue(config) {
  const conn = await connect(config)
  const ch = await conn.createChannel()
  try {
    const status = await ch.checkQueue(queueName('deliver', config))
    console.log(status)
    return status
  } finally {
    ch.close()
    conn.close()
  }
}

export async function syncQueue(service, config, argv) {
  const conn = await connect(config)
  const ch = await conn.createChannel()
  const qn = queueName('deliver', config)
  let consumerTag = null
  console.log(`⏳ waiting for actions from ${qn}`)

  return new Promise(async (ok, fail) => {
    const ret = await ch.consume(qn, (msg) => {
      let action = JSON.parse(msg.content.toString());
      action.contact.pii = JSON.parse(action.contact.payload)
      const syncing = service.syncAction(action, config, argv)
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
