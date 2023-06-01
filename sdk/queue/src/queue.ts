import { decryptPersonalInfo } from '@proca/crypto'
import amqplib from 'amqplib'
import LineByLine from 'line-by-line'
export {ActionMessage, ActionMessageV2, ProcessStage} from './actionMessage'

import {
  ActionMessage,
  actionMessageV1to2
} from './actionMessage'

import {QueueOpts, SyncCallback} from './types'


export function connect(queueUrl : string) {
  return amqplib.connect(queueUrl) as any
}

const pause = (time = 1) => { //by default, wait 1 sec
    return new Promise(resolve => setTimeout(resolve, time*1000));
}

export async function testQueue(queueUrl : string, queueName : string) {
  const conn = await connect(queueUrl)
  const ch = await conn.createChannel()
  try {
    const status = await ch.checkQueue(queueName)
    return status
  } finally {
    ch.close()
    conn.close()
  }
}


export async function syncQueue(
  queueUrl : string,
  queueName : string,
  syncer : SyncCallback,
  opts? : QueueOpts) {
  const conn = await connect(queueUrl)
  const ch = await conn.createChannel()
  const qn = queueName;
  let errorCount = 0; //number of continuous errors

  let status = {
    tag: null as string | null,
    running: 0,
    stopping: false
  }

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
      console.log(`🛬 Shutting down the processing. Wating for ${status.running} threads running.`)
    if (status.stopping && status.running === 0) {
      console.log("🏁 All finished, closing channel!")
      await ch.close()
      await conn.close()
    }
  }
  console.error(`⏳ waiting for actions from ${qn}`)

  return new Promise(async (_, _fail) => {
    if (typeof opts?.prefetch !== 'undefined') {
      await ch.prefetch(opts.prefetch)
    }
    const ret = await ch.consume(qn, (msg : amqplib.Message) => {
      let action : ActionMessage = JSON.parse(msg.content.toString())

      // upgrade old v1 message format to v2
      if (action.schema === "proca:action:1") {
        action = actionMessageV1to2(action)
      }

      // optional decrypt
      if (action.personalInfo && opts?.keyStore) {
        const plainPII = decryptPersonalInfo(action.personalInfo, opts.keyStore)
        action.contact = {...action.contact, ...plainPII}
      }

      status.running += 1
      try {
        const processed = syncer(action, msg, ch);

          if (typeof processed !== 'boolean') {
            await ch.nack(msg, false, false)

            await startShutdown();
            await finalizeShutdown();
            console.error(`Returned value must be boolean. Nack action, actionId: ${action.actionId}):`)
          }
          if (processed) {
            try {
              errorCount = 0;
              ch.ack(msg)
              status.running -= 1
              return finalizeShutdown();
            } catch (e) {
              console.error("Could not ack a successful message! Action Id", action.actionId, e)
              throw e
            }
          } else { //the CRM didn't process the message
            const delay = 1 << errorCount;
            await ch.nack(msg, false, false)
            console.error("Requeued due to error! Action Id:", action.actionId, "pausing for ", delay,"s");
            if (delay  > 10800) { // if we need to wait more than 3 hours, restart instead
              console.error('restart because errorCount=', errorCount);
              await startShutdown();
              return finalizeShutdown();
            }
            await pause(delay) // exponential waiting
            errorCount++;
            return finalizeShutdown();
          }
        } catch (e : Error)  {
          status.running -= 1

          console.error(`Error thrown during sync actionId=${action.actionId}, try to nack the current message:`, e)
          await ch.nack(msg, false, false)

          await startShutdown();
          await finalizeShutdown();
          console.error(`failure to syncAction (actionId: ${action.actionId}):`, e)
        }
    })
    status.tag = ret.consumerTag
  })
}

export async function syncFile(filePath : string, syncer : SyncCallback, opts? : QueueOpts) {
  const lines = new LineByLine(filePath)

  lines.on('line', async (l) => {
    let action : ActionMessage = JSON.parse(l)

    if (action.schema === "proca:action:1") {
      action = actionMessageV1to2(action)
    }

    // optional decrypt
    if (action.personalInfo && opts?.keyStore) {
      const plainPII = decryptPersonalInfo(action.personalInfo, opts.keyStore)
      action.contact = {...action.contact, ...plainPII}
    }

    lines.pause()
    await syncer(action);
    lines.resume()
  })
}



