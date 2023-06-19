import { lookup, start}  from "./http";
import { syncer }  from "./queue";
import minimist, { ParsedArgs } from 'minimist';
import dotenv from 'dotenv'

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

const argv: ParsedArgs = minimist(process.argv.slice(2), { 
  string: ["email"],
  unknown: (d?: string) => {
    const allowed = ["target"]; //merge with boolean and string?
    if (!d) return false;
    if (d[0] !== "-") return true;
    if (allowed.includes(d.split("=")[0].slice(2))) return true;
    console.error("unknown param", d);
    help(1);
    return false;
  },

boolean: ["queue", "email", "http", "help", "pause"] });

dotenv.config();


  argv.help && help(0);
  if (!(argv.queue || argv.http || argv.email)) {
    help(1);
  }
  if (argv.email) { //
    const r = lookup(argv.email);
console.log(r);
  }
  if (argv.queue) {
console.log("syncer");
    syncer(argv);
  }
  if (argv.http) {
    start();
  }
