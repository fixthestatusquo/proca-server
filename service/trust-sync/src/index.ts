import { syncQueue, ActionMessageV2, EventMessageV2 } from '@proca/queue';
import { Signature, formatAction } from "./data";
import { postAction } from "./client";
const dotenv = require('dotenv');
dotenv.config();



const user = process.env.RABBIT_USER;
const pass = process.env.RABBIT_PASSWORD;
const queueDeliver = "cus.172.deliver";

syncQueue(`amqps://${user}:${pass}@api.proca.app/proca_live`, queueDeliver, async (action: ActionMessageV2 | EventMessageV2) => {
  if (action.schema === 'proca:action:2') {
    console.log("ooooooo", formatAction(action))
    await postAction(formatAction(action));
  }
}, {}
)
