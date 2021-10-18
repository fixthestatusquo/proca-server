import amqplib from 'amqplib'
import fs from 'fs'
import LineByLine from 'line-by-line'
import {decrypt,EncryptedContact } from './crypto'
import {getContact, DecryptOpts} from './decrypt'
import {decryptAction} from './export'
import {CliConfig} from './config'
import {CliOpts } from './cli'
import {ActionMessage, ProcessStage} from './queueMessage'
import {getService, ServiceOpts} from './service'
export {ActionMessage, ProcessStage} from './queueMessage'


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


export async function syncQueue(opts : ServiceOpts & DecryptOpts, config:CliConfig) {
  const conn = await connect(config)
  const ch = await conn.createChannel()
  const qn = opts.queueName || queueName('deliver', config)
  const service = getService(opts)

  let status = { tag: null as string, running: 0, stopping: false}

  const startShutdown = async () => {
    if (status.tag && !status.stopping) {
      const ct = status.tag
      status.tag = null
      status.stopping = true
      await ch.cancel(ct)
    }
  }

  const finalizeShutdown = async () => {
    if (status.stopping) 
      console.log(`Shutting down the processing. Wating for ${status.running} threads running.`)
    if (status.stopping && status.running === 0) {
      console.log("All finished, closing channel!")
      await ch.close()
      await conn.close()
    }
  }
  console.error(`⏳ waiting for actions from ${qn}`)

  return new Promise(async (_, fail) => {
    if (typeof opts.queuePrefetch !== 'undefined') {
      await ch.prefetch(opts.queuePrefetch)
    }
    const ret = await ch.consume(qn, (msg : amqplib.Message) => {
      let action = JSON.parse(msg.content.toString())

      decryptActionMessage(action, opts, config)
      
      status.running += 1
      const syncing = service.syncAction(action, opts, config, msg)
        .then((v : any) => {
          try {
            ch.ack(msg)
            status.running -= 1
            return finalizeShutdown()
          } catch (e) {
            console.error("Could not ack a successful message! Action Id", action.actionId, e)  
            throw e
          }
        })
        .catch(async (e : Error) => {
          status.running -= 1

          console.error(`Error thrown during sync actionId=${action.actionId}, try to nack the current message:`, e)
          await ch.nack(msg, false, false)

          await startShutdown();
          await finalizeShutdown();
          console.error(`failure to syncAction (actionId: ${action.actionId}):`, e)
        })
    })    
    status.tag = ret.consumerTag
  })
}

export async function syncFile(opts : ServiceOpts & DecryptOpts, config: CliConfig) {
  const service = getService(opts)
  const lines = new LineByLine(opts.filePath)

  lines.on('line', async (l) => {
    let action = JSON.parse(l)
    
    decryptActionMessage(action, opts, config)
    lines.pause()
    await service.syncAction(action, opts, config)
    lines.resume()
  })
}




export function decryptActionMessage(action : ActionMessage, argv : DecryptOpts, config : CliConfig) {
  const contact : EncryptedContact = {
    signKey: { public: action.contact.signKey},
    publicKey: { public: action.contact.publicKey},
    nonce: action.contact.nonce,
    payload: action.contact.payload,
    contactRef: action.contact.ref
  }

  const pii = getContact(contact, argv, config)
  action.contact.pii = pii
  if (!action.contact.firstName && action.contact.pii.firstName)
    action.contact.firstName = action.contact.pii.firstName
  if (!action.contact.email && action.contact.pii.email)
    action.contact.email = action.contact.pii.email
  return action
}
