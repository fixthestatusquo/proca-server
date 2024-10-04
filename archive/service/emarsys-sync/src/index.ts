import {initialize, updateContact, addContact, findContactList, createContactList} from './client';
import {eventToContact, actionToContact} from './contact';
import {syncQueue, ActionMessageV2, EventMessageV2} from '@proca/queue';
import parseArg from 'minimist';
import debug from 'debug';


const log = debug('sync');


export const main = async () => {
  await initialize();
  const opts = parseArg(process.argv.slice(2));
  const url = process.env.QUEUE_URL;

  if (!url) throw new Error(`Export QUEUE_URL`);

  if (opts.q) {
    console.log(`Syncing queue ${opts.q}`);
    syncQueue(url, opts.q, async (msg : ActionMessageV2 | EventMessageV2) => {
      if (msg.schema === 'proca:action:2') {
        const c = actionToContact(msg);
        // Client wants a list name 'Proca ECI FUR' which has nothing to do with name or title.
        const listName = msg.campaign.name === 'fur_free_europe' ? 'Proca ECI FUR' : msg.campaign.name;
        let list = await findContactList(listName);
        if (!list) {
          list = await createContactList(listName);
        }
        const r = await addContact(c, list);
        log("added %o to list %s", r, list);

      } else if (msg.schema === 'proca:event:2') {
        log("event %o", msg);
        const c = eventToContact(msg);
        if (c) {
          const r = await updateContact(c, true);
          log("updated %o: %o", c, r);
        }
      }
    }, {prefetch: 1});
  }
}

if (require.main === module) {
  main()
}
