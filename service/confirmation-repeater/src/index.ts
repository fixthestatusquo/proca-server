import { syncQueue, ActionMessageV2, EventMessageV2 } from '@proca/queue';
import { changeDate } from "./helpers"
const amqplib = require('amqplib');
const { Level } = require("level");
const schedule = require('node-schedule');
//const nodeSchedule = require("@types/node-schedule")
const db = new Level(process.env.DB_PATH || "./db", { valueEncoding: 'json' })

const dotenv = require('dotenv');
dotenv.config();

const user = process.env.RABBIT_USER;
const pass = process.env.RABBIT_PASSWORD;
const queueConfirm = process.env.CONFIRM_QUEUE || "";
const queueConfirmed = process.env.CONFIRMED_QUEUE || "";
const maxRetries = process.env.MAX_RETIRES || "3";


//TODO: run every 10 min

const job = schedule.scheduleJob('* * * * *', async () => {
  console.log('running every minute', maxRetries);
  for await (const [key, value] of db.iterator({ gt: 'retry-' })) {
    console.log("Job:", key, value);
    const actionId = key.split("-")[1];


   if (value.attempts >= +maxRetries) {
    await db.put('done-' + actionId, { done: false }, function (error: any) {
      if (error) {
        console.log("Put done:", error);
      }
    })
    await db.del('action-' + actionId, function (error: any) {
      if (error) {
        console.log("Del action in job:", error);
      }
    })
    await db.del('retry-' + actionId, function (error: any) {
      if (error) {
        console.log("DEl retry in error:", error);
      }
    })
   }

    //TODO: UNCOMMENT
  // if (Date(value.retry) > Date.now() && value.attempts < maxRetries) {


// TO DO: DELETE LINE!!!!
    if (value.attempts < maxRetries) {

    db.get("action-" + actionId, async function (error: any, value: any) {
      if (error) console.log("Get action in job:", error)
      //   todo: reinsert action to the queue
      // amqplib.publish(
      //   // exchange: ""
      //   //   routing key:  "wrk.${org.id}.email.supporter"
    })
     db.get("retry-" + actionId, async function (error: any, value: any) {
       if (error) {

         console.log("Get retry in job:", error);
       } else {

         const retry = { retry: changeDate(value.retry, value.attempts+1), attempts: value.attempts + 1 };
         console.log("Retried", retry)
         await db.put('retry-' + actionId, retry, async function (error: any) {
           if (error) {
             throw error
           }
         })
       }
     })
     }
  }
});

syncQueue(`amqps://${user}:${pass}@api.proca.app/proca_live`, queueConfirm, async (action: ActionMessageV2 | EventMessageV2) => {
  if (action.schema === 'proca:action:2') {

    console.log(action.actionId);
    await db.get('action-' + action.actionId, async function (error: any, value: any) {
      if (error?.status === 404) {
        await db.put('action-' + action.actionId, action, async function (error: any) {
          if (error) {
            throw error
          }
          db.get('action-' + action.actionId, function (error: any, value: any) {
            if (error) throw error;
            console.log("saved action:", value)

          })
        })

        const retry = { retry: changeDate(action.action.createdAt, 1), attempts: 1 };
        await db.put('retry-' + action.actionId, retry, async function (error: any) {
          if (error) throw error
          db.get('retry-' + action.actionId, function (error: any, value: any) {
            if (error) throw error;
            console.log("saved retry:", value)

          })
        })
      }
    })

      }
})

syncQueue(`amqps://${user}:${pass}@api.proca.app/proca_live`, queueConfirmed, async (action: ActionMessageV2 | EventMessageV2) => {
  if (action.schema === 'proca:action:2') {
    console.log("Confirmed:", action.actionId);
    await db.put('done-' + action.actionId, { done: true }, function (error: any) {
      if (error) {
        throw error
      }
    })
    await db.del('action-' + action.actionId, function (error: any) {
      if (error) {
        console.log("Del action in confirmed queue", error);
      }
    })
    await db.del('retry-' + action.actionId, function (error: any) {
      if (error) {
        console.log("Del retry in confirmed queue", error);
      }
    })
  }
})
