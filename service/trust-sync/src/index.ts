import { syncQueue, ActionMessageV2, EventMessageV2 } from '@proca/queue';
import { formatAction } from "./data";
import { postAction, verification, lookup, rabbit } from "./client";
var argv = require('minimist')(process.argv.slice(2));

const dotenv = require('dotenv');
dotenv.config();

const args = argv._

export const trust = async () => {
  if (args[0] === 'trust-sync') {
    const { user, pass, queueDeliver = "" } = rabbit();
    syncQueue(`amqps://${user}:${pass}@api.proca.app/proca_live`, queueDeliver, async (action: ActionMessageV2 | EventMessageV2) => {
      if (action.schema === 'proca:action:2') {


        // TO DO: REMOVE WHEN CUSTOM FIELD AWAILABLE
        const isSubscribe = { action: { customFields: { subscribeNewsletter: true } } }

        const data = await postAction(formatAction(action, isSubscribe));
        if (data.petition_signature?.verification_token) {
          await verification(data.petition_signature.verification_token)
        }
      }
    })
  } else if (args[0] === "trust-lookup" && args.length === 2) {
      const isSubscribe = { action: { customFields: { subscribeNewsletter: true } } }
      const status = await lookup(args[1]);
          if (status.success) {
            isSubscribe.action.customFields.subscribeNewsletter = false
          }
      return isSubscribe;
  } else {
    console.log("Wrong request! Enter trust-sync or tryst-lookup <email>")
  }
}

trust()
