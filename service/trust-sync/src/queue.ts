import {
  pause,
  syncQueue,
  ActionMessageV2,
  EventMessageV2,
} from "@proca/queue";
import { formatAction, handleConsent } from "./data";
import { postAction, verification, rabbit } from "./client";

export const syncer = async (argv: any) => {
  const { user, pass, queueDeliver = ''} = rabbit();

  syncQueue(
    `amqps://${user}:${pass}@api.proca.app/proca_live`,
    queueDeliver,
    async (action: ActionMessageV2 | EventMessageV2) => {
console.log("processing message"); 
      if (action.schema === "proca:action:2") {
        const actionPayload = formatAction(action);
        const verificationPayload = {
          petition_signature: {
            subscribe_newsletter:
              actionPayload.petition_signature.subscribe_newsletter,
            data_handling_consent: handleConsent(action),
          },
        };
        const data = await postAction(actionPayload);
        if (argv.pause) {
          await pause();
        }
        if (data.petition_signature?.verification_token) {
          const verified = await verification(
            data.petition_signature.verification_token,
            verificationPayload
          );
          return false; //true
        } else {
          throw new Error ("token not verified");
        }
      } else {
        if (argv.pause) {
          await pause();
        }
console.log("non fatal error");
return false;
        throw new Error ("don't know how to process if !proca:action:2");
      }
    }
  );
};
