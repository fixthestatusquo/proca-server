import { decryptPersonalInfo } from '@proca/crypto';
import { Connection, AsyncMessage } from 'rabbitmq-client';

import LineByLine from 'line-by-line';
export { ActionMessage, ActionMessageV2, ProcessStage } from './actionMessage';

import { ActionMessage, actionMessageV1to2 } from './actionMessage';

import { ConsumerOpts, SyncCallback } from './types';

let connection: any = null;

async function exitHandler(evtOrExitCodeOrError: number | string | Error) {
  try {
  if (connection) {
    console.log('closing');
    await connection.close();
  }
  console.log('closed, exit now');
  
  process.exit(0);
  } catch (e) {
    console.error('EXIT HANDLER ERROR', e);
  }

  process.exit(isNaN(+evtOrExitCodeOrError) ? 1 : +evtOrExitCodeOrError);
}

[
  'beforeExit', 'uncaughtException', 'unhandledRejection', 
  'SIGHUP', 'SIGINT', 'SIGQUIT', 'SIGILL', 'SIGTRAP', 
  'SIGABRT','SIGBUS', 'SIGFPE', 'SIGUSR1', 'SIGSEGV', 
  'SIGUSR2', 'SIGTERM', 
].forEach(evt => process.on(evt, exitHandler));


export const connect = (queueUrl: string) => {
  const rabbit = new Connection(queueUrl);
  connection = rabbit; //global
  rabbit.on('error', (err) => {
    console.log('RabbitMQ connection error', err);
  });
  rabbit.on('connection', () => {
    console.log('Connection successfully (re)established');
  });

  return rabbit as any;
}

export async function testQueue(queueUrl: string, queueName: string) {
  throw new Error("it shouldn't call testQueue " + queueUrl + ':' + queueName);

  /*
  const conn = await connect(queueUrl)
  const ch = await conn.createChannel()
  try {
    const status = await ch.checkQueue(queueName)
    return status
  } finally {
    ch.close()
    conn.close()
  }
*/
}

export const syncQueue = async (
  queueUrl: string,
  queueName: string,
  syncer: SyncCallback,
  opts?: ConsumerOpts
) => {
  console.log('syncQueue options', opts);
  const concurrency = opts?.concurrency || 1;
  const prefetch = 2 * concurrency;
  const rabbit = await connect(queueUrl);

  const sub = rabbit.createConsumer(
    {
      queue: queueName,
      queueOptions: { passive: true },
      // handle 2 messages at a time
      concurrency: concurrency,
      qos: { prefetchCount: prefetch },
      // Optionally ensure an exchange exists
    },
    async (msg: AsyncMessage) => {
      // The message is automatically acknowledged when this function ends.
      // If this function throws an error, then msg is NACK'd (rejected) and
      // possibly requeued or sent to a dead-letter exchange
      let action: ActionMessage = JSON.parse(msg.body.toString());

      // upgrade old v1 message format to v2
      if (action.schema === 'proca:action:1') {
        action = actionMessageV1to2(action);
      }

      // optional decrypt
      if (action.personalInfo && opts?.keyStore) {
        const plainPII = decryptPersonalInfo(
          action.personalInfo,
          opts.keyStore
        );
        action.contact = { ...action.contact, ...plainPII };
      }
      try {
        const processed = await syncer(action);
        // returning a false or {processed:false}-> message should be nacked
        console.error('processed', processed);
        console.log('processed', processed);
        if (typeof processed !== 'boolean') {
          console.error(
            `Returned value must be boolean. Nack action, actionId: ${action.actionId}):`
          );
          rabbit.close(); // we need to shutdown
        }
        if (processed) {
          return;
        } else {
          throw new Error(
            'Requeued due to error! Action Id:' + action.actionId
          );
        }
      } catch (e) {
        //if the syncer throw an error it's a permanent problem, we need to close
        console.error('error processing',e);
        rabbit.close();
      }
      sub.on('error', (err: any) => {
        // Maybe the consumer was cancelled, or the connection was reset before a
        // message could be acknowledged.
        console.log('rabbit error', err);
      });
    }
  );

}

export const syncFile = (
  filePath: string,
  syncer: SyncCallback,
  opts?: ConsumerOpts
) => {
  const lines = new LineByLine(filePath);

  lines.on('line', async (l) => {
    let action: ActionMessage = JSON.parse(l);

    if (action.schema === 'proca:action:1') {
      action = actionMessageV1to2(action);
    }

    // optional decrypt
    if (action.personalInfo && opts?.keyStore) {
      const plainPII = decryptPersonalInfo(action.personalInfo, opts.keyStore);
      action.contact = { ...action.contact, ...plainPII };
    }

    lines.pause();
    await syncer(action);
    lines.resume();
  });
}
