import { syncQueue, ActionMessageV2, EventMessageV2 } from '@proca/queue';
import { changeDate } from "./helpers"
const amqplib = require('amqplib');
const { Level } = require("level");
const schedule = require('node-schedule');
const parseArg = require('minimist');

const args = parseArg(process.argv.slice(2));
//const nodeSchedule = require("@types/node-schedule")
const db = new Level(process.env.DB_PATH || args.db || "./reminder.db", { valueEncoding: 'json' })



const user = process.env.RABBIT_USER || args.user;
const pass = process.env.RABBIT_PASSWORD || args.password;
const queueConfirm = process.env.CONFIRM_QUEUE || args.qc || "";
const queueConfirmed = process.env.CONFIRMED_QUEUE || args.qd || "";
const emailQueue = process.env.EMAIL_QUEUE || args.qe || "";
const maxRetries = parseInt(process.env.MAX_RETIRES || args.r || "3");

const debugDayOffset = parseInt(process.env.ADD_DAYS || args.A || "0");


type LevelError = {
  code: string;
  notFound: boolean;
  status: number;
};

//TODO: run every 10 min

const job = schedule.scheduleJob('* * * * *', async () => {
  console.log('running every minute', maxRetries);
  for await (const [key, value] of db.iterator({ gt: 'retry-' })) {
    console.log("Job:", key, value);
    const actionId = key.split("-")[1];

   if (value.attempts > maxRetries) { // attempts counts also 1st normal confirm
     await db.put('done-' + actionId, { done: false });
     await db.del('action-' + actionId);
     await db.del('retry-' + actionId);
   } else {

    const today = new Date()
    today.setDate(today.getDate() + debugDayOffset);
    if ((new Date(value.retry)) > today && value.attempts < maxRetries) {

      const action = await db.get("action-" + actionId);
      let retry = await db.get("retry-" + actionId);
      retry = { retry: changeDate(value.retry, value.attempts+1), attempts: value.attempts + 1 };
      console.log("Retried", retry)
      await db.put('retry-' + actionId, retry);
    }
   }
  }
});

syncQueue(`amqps://${user}:${pass}@api.proca.app/proca_live`, queueConfirm, async (action: ActionMessageV2 | EventMessageV2) => {
  if (action.schema === 'proca:action:2' && action.contact.dupeRank === 0) {

    console.log(action.actionId);
    try {
      const payload =  await db.get('action-' + action.actionId);
    } catch (_error) {
      console.error('catch', _error);
      const error = _error as LevelError;

      if (error.notFound) {
        console.log('store payload');
        await db.put('action-' + action.actionId, action);
        console.log('saved:', await db.get('action-' + action.actionId))

        const retry = { retry: changeDate(action.action.createdAt, 1), attempts: 1 };
        await db.put('retry-' + action.actionId, retry);
        console.log('retry:', await db.get('retry-' + action.actionId));
      } else {
        console.error(`other error:`, error);
        throw error;
      }
    }
  }
})

syncQueue(`amqps://${user}:${pass}@api.proca.app/proca_live`, queueConfirmed, async (action: ActionMessageV2 | EventMessageV2) => {
  if (action.schema === 'proca:action:2') {
    console.log("Confirmed:", action.actionId);
    await db.put('done-' + action.actionId, { done: true });
    await db.del('action-' + action.actionId);
    await db.del('retry-' + action.actionId);
  }
})
