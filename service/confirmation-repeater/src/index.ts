import { syncQueue, ActionMessageV2, EventMessageV2 } from '@proca/queue';
const { Level } = require("level");

const db = new Level(process.env.DB_PATH || "./db", { valueEncoding: 'json' })
const dotenv = require('dotenv');
dotenv.config();

const user = process.env.RABBIT_USER;
const pass = process.env.RABBIT_PASSWORD;
const queueConfirm = process.env.RABBIT_QUEUE || "";

syncQueue(`amqps://${user}:${pass}@api.proca.app/proca_live`, queueConfirm, async (action: ActionMessageV2 | EventMessageV2) => {
  if (action.schema === 'proca:action:2') {
    console.log("action", action);
  }
    })