import { syncQueue, ActionMessageV2, EventMessageV2 } from '@proca/queue';
import { changeDate } from "./helpers"
import amqplib from 'amqplib';
import { Level } from "level";
import schedule from "node-schedule";
import parseArg from "minimist";


// READ PARAMS
const args = parseArg(process.argv.slice(2));
const db = new Level(process.env.DB_PATH || args.db || "./reminder.db", { valueEncoding: 'json' })
const user = process.env.RABBIT_USER || args.user;
const pass = process.env.RABBIT_PASSWORD || args.password;
const queueConfirm = process.env.CONFIRM_QUEUE || args.qc || "";
const queueConfirmed = process.env.CONFIRMED_QUEUE || args.qd || "";
const emailQueue = process.env.EMAIL_QUEUE || args.qe || "";
const remindExchange = process.env.REMIND_EXCHANGE || args.qe || "";
const maxRetries = parseInt(process.env.MAX_RETIRES || args.r || "3");
const retryArray = (process.env.RETRY_INTERVAL || "2,3").split(",").map(x => parseInt(x)).filter(x => x > 0);
// debug
const debugDayOffset = parseInt(process.env.ADD_DAYS || args.A || "0");


const amqp_url = `amqps://${user}:${pass}@api.proca.app/proca_live`;

// types

type LevelError = {
  code: string;
  notFound: boolean;
  status: number;
};

type RetryRecord = {
  attempts: number;
  retry: string;
};

type DoneRecord = {
  done: boolean;
}

//TODO: run every 10 min

const job = schedule.scheduleJob('* * * * *', async () => {
  console.log('running every minute', maxRetries);

  const conn = await amqplib.connect(amqp_url);
  const chan = await conn.createChannel()

  try {
    for await (const [key, value] of db.iterator<string, RetryRecord>({ gt: 'retry-' })) {
      console.log("Confirm:", key, value);
      const actionId = key.split("-")[1];

      if (value.attempts >= maxRetries) { // attempts counts also 1st normal confirm
        console.log(`Confirm ${actionId} had already ${value.attempts}, deleting`);
        await db.put<string, DoneRecord>('done-' + actionId, { done: false }, {});
        await db.del('action-' + actionId);
        await db.del('retry-' + actionId);
      } else {

        const today = new Date()
        today.setDate(today.getDate() + debugDayOffset);

        console.log(`${new Date(value.retry)} < ${today} ?`);
        if ((new Date(value.retry)) < today && value.attempts < maxRetries) {

          console.log(`Reminding action ${actionId} (due ${value.retry})`);

          // publish
          const action = await db.get<string, ActionMessageV2>("action-" + actionId, {});
          action.action.customFields.reminder = true;

          const r = await chan.publish(remindExchange,
                                       action.action.actionType + '.' + action.campaign.name,
                                       Buffer.from(JSON.stringify(action)));
          console.log('publish', r);

          let retry = await db.get<string, RetryRecord>("retry-" + actionId, {});
          retry = { retry: changeDate(value.retry, value.attempts+1, retryArray), attempts: value.attempts + 1};
          console.debug("Retried", retry)
          await db.put<string, RetryRecord>('retry-' + actionId, retry, {});
        }
      }
    }
  } finally {
    await chan.close();
    await conn.close()
  }
});

syncQueue(amqp_url, queueConfirm, async (action: ActionMessageV2 | EventMessageV2) => {
  if (action.schema === 'proca:action:2' && action.contact.dupeRank === 0) {

    console.log(`New confirm `, action.actionId);
    try {
      // ignore if we have it
      const _payload =  await db.get('action-' + action.actionId);
    } catch (_error) {
      console.error('catch', _error);
      const error = _error as LevelError;

      if (error.notFound) {
        await db.put<string, ActionMessageV2>('action-' + action.actionId, action, {});
        const retry = { retry: changeDate(action.action.createdAt, 1, retryArray), attempts: 1 };
        await db.put<string, RetryRecord>('retry-' + action.actionId, retry, {});

        console.log(`Scheduled confirm reminder: ${action.actionId}`, action);
      } else {
        console.error(`Error checking if confirm scheduled in DB`, error);
        throw error;
      }
    }
  }
})

syncQueue(amqp_url, queueConfirmed, async (action: ActionMessageV2 | EventMessageV2) => {
  if (action.schema === 'proca:action:2') {
    console.log("Confirmed:", action.actionId);
    await db.put<string, DoneRecord>('done-' + action.actionId, { done: true }, {});
    await db.del('action-' + action.actionId);
    await db.del('retry-' + action.actionId);
  }
})
