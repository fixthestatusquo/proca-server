import { syncQueue, ActionMessageV2, EventMessageV2 } from '@proca/queue';
import { formatAction } from "./data";
import { postAction, verification, lookup } from "./client";
const dotenv = require('dotenv');
dotenv.config();

const user = process.env.RABBIT_USER;
const pass = process.env.RABBIT_PASSWORD;
const queueDeliver = "cus.172.deliver";

syncQueue(`amqps://${user}:${pass}@api.proca.app/proca_live`, queueDeliver, async (action: ActionMessageV2 | EventMessageV2) => {
  if (action.schema === 'proca:action:2') {
    const data = await postAction(formatAction(action));
    if (data.petition_signature?.verification_token) {
      await verification(data.petition_signature.verification_token)
    }
    lookup(formatAction(action).petition_signature.email);
  }
}, {}
)
