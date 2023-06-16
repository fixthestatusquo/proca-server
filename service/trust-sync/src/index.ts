import { syncQueue, ActionMessageV2, EventMessageV2 } from '@proca/queue';
import { formatAction, handleConsent } from "./data";
import { postAction, verification, rabbit } from "./client";
var argv = require('minimist')(process.argv.slice(2),{boolean:['queue']});

const dotenv = require('dotenv');
dotenv.config();

const args = argv._

const syncer = async () => {
    const { user, pass, queueDeliver = "" } = rabbit();
    syncQueue(`amqps://${user}:${pass}@api.proca.app/proca_live`, queueDeliver, async (action: ActionMessageV2 | EventMessageV2) => {
      if (action.schema === 'proca:action:2') {
        const actionPayload = formatAction(action)
        const verificationPayload = { "petition_signature": { "subscribe_newsletter": actionPayload.petition_signature.subscribe_newsletter, "data_handling_consent": handleConsent(action) } };
        const data = await postAction(actionPayload);
        if (data.petition_signature?.verification_token) {
          const verified = await verification(data.petition_signature.verification_token, verificationPayload)
        } else {
 console.log("unhandled data2", data);
return false;
        }
console.log("we shouldn't be here");
return false;
      } else {
        console.log("unknown message");
        return false;
      }
    })
}
if (require.main === module) {
  if (argv.queue) {
    syncer();
  }
} else {
  module.exports = {syncer};
}
