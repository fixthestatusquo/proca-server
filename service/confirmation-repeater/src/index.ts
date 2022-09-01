import { syncQueue, ActionMessageV2, EventMessageV2 } from '@proca/queue';
const { Level } = require("level");
const schedule = require('node-schedule');
//const nodeSchedule = require("@types/node-schedule")
const db = new Level(process.env.DB_PATH || "./db", { valueEncoding: 'json' })

const dotenv = require('dotenv');
dotenv.config();

const user = process.env.RABBIT_USER;
const pass = process.env.RABBIT_PASSWORD;
const queueConfirm = process.env.CONFIRM_QUEUE || "";

const job = schedule.scheduleJob('* * * * *', async () => {
  console.log('running every hour');
  for await (const [key, value] of db.iterator({ gt: 'retry-' })) {
    const date = new Date(value.retry)
    console.log(date) // 2
    if (date > Date.now()) {
      //reinsert to queue
    }
  }

});

syncQueue(`amqps://${user}:${pass}@api.proca.app/proca_live`, queueConfirm, async (action: ActionMessageV2 | EventMessageV2) => {
  if (action.schema === 'proca:action:2') {

    console.log(action.actionId);
    await db.get('action-' + action.actionId, async function (error: any, value: any) {
      if (error?.status === 404 || !value?.done) {

        await db.put('action-' + action.actionId, action, async function (error: any) {
          if (error) {
            throw error
          }
          db.get('action-' + action.actionId, function (error: any, value: any) {
            if (error) throw error;
            console.log("saved action:", value)

          })
        })

        const created = new Date(action.action.createdAt)
        const retry = { retry: (new Date(created.setDate(created.getDate() + 3))).toISOString(), attempts: 0 };

        await db.put('retry-' + action.actionId, retry, async function (error: any) {
          if (error) {
            throw error
          }
          db.get('retry-' + action.actionId, function (error: any, value: any) {
            if (error) throw error;
            console.log("saved retry:", value)

          })
        })
      }
    })

      }
})

// to do: finish when queue awailable

// syncQueue(`amqps://${user}:${pass}@api.proca.app/proca_live`, queueDeliveryRepeater, async (action: ActionMessageV2 | EventMessageV2) => {
//   if (action.schema === 'proca:action:2') {
//     console.log(action.actionId);
//     await db.put('done' + action.actionId, { done: true }, function (error: any) {
//       if (error) {
//         throw error
//       }
//     })
//     await db.del('action' + action.actionId, function (error: any) {
//       if (error) {
//         throw error
//       }
//     })
//     await db.del('retry' + action.actionId, function (error: any) {
//       if (error) {
//         throw error
//       }
//     })
//   }
// })


