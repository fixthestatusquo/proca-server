import { syncQueue, ActionMessageV2, EventMessageV2 } from '@proca/queue';
import { formatAction } from "./data";
import { postAction, verification, lookup, rabbit } from "./client";
var argv = require('minimist')(process.argv.slice(2));

const dotenv = require('dotenv');
dotenv.config();

const args = argv._

const syncer = async () => {
    const { user, pass, queueDeliver = "" } = rabbit();
    syncQueue(`amqps://${user}:${pass}@api.proca.app/proca_live`, queueDeliver, async (action: ActionMessageV2 | EventMessageV2) => {
      if (action.schema === 'proca:action:2') {

        const data = await postAction(formatAction(action));
        if (data.petition_signature?.verification_token) {
          await verification(data.petition_signature.verification_token)
        }
      }
    })
}

module.exports = {syncer};
