import {
  pause,
  syncQueue,
  ActionMessageV2,
  EventMessageV2,
} from "@proca/queue";
import { formatAction, handleConsent } from "./data";
import { postAction, verification, rabbit } from "./client";
const { lookup, start} = require("./http");

const help = (status = 0) => {
  console.log(
    [
      "--help (this command)",
      "--http start the server lookup",
      "--queue process the queue",
      "--dry-run",
      "--verbose",
      "--pause|no-pause (for debug purpose: wait on queue processing)",
      "--email ? not sure how it works",
    ].join("\n")
  );
  process.exit(status);
};

const argv = require("minimist")(process.argv.slice(2), { 
  string: ["email"],
  unknown: (d: String) => {
    const allowed = ["target"]; //merge with boolean and string?
    if (d[0] !== "-") return true;
    if (allowed.includes(d.split("=")[0].slice(2))) return true;
    console.error("unknown param", d);
    help(1);
  },

boolean: ["queue", "email", "http", "help", "pause"] });

const dotenv = require("dotenv");
dotenv.config();

const syncer = async () => {
  const { user, pass, queueDeliver = ''} = rabbit();
  syncQueue(
    `amqps://${user}:${pass}@api.proca.app/proca_live`,
    queueDeliver,
    async (action: ActionMessageV2 | EventMessageV2) => {
if (argv.pause) {
console.log(pause);
console.log(action);
  await pause();
}
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
          console.log("unhandled data2", data);
          return false;
        }
        console.log("we shouldn't be here");
        return false;
      } else {
        console.log("unknown message");
        return false;
      }
    }
  );
};


if (require.main === module) {
  argv.help && help(0);
  if (!(argv.queue || argv.http || argv.email)) {
    help(1);
  }
  if (argv.email) { //
    const r = lookup(argv.email);
  }
  if (argv.queue) {
    syncer();
  }
  if (argv.http) {
    start();
  }
  module.exports = { syncer };
}
