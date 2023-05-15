import {
  initialize,
  model,
  findContactList,
  createContactList,
  deleteContactList,
  recordToContact,
  createField,
  addContact,
  getContactByRef,
  getContactById,
  getContactByEmail,
  call,
  contactToRecord,
} from './client';
import {
  actionToContact,
  getCountry
} from './contact';

import {ActionMessageV2} from '@proca/queue';


import parseArg from 'minimist'


const ping = async () => {
  const d = await call("/settings");
  console.log(d)
}

const test = async () => {
  //await createContactList("testing2");


  const lists = await call('/contactlist')


  for (const l of lists.data) {
    console.log('lists', l);
    await deleteContactList(l.id)
  }
}



const testData = `{"action":{"actionType":"register","createdAt":"2022-12-19T15:17:29Z","customFields":{"emailProvider":"protonmail.ch","salutation":"m"},"testing":false},"actionId":2036184,"actionPage":{"locale":"de","name":"fur_free_europe/vier_pfoten_at/1","supporterConfirmTemplate":null,"thankYouTemplate":"thankyou1","thankYouTemplateRef":null},"actionPageId":2330,"campaign":{"contactSchema":"basic","externalId":null,"name":"fur_free_europe","title":"Fur Free Europe"},"campaignId":210,"contact":{"area":"PL","contactRef":"V2yJwoSj2UAgfDVern45yevtANktWkuaJg3aGk1g240","country":"PL","dupeRank":0,"email":"dump+10@cahoots.pl","firstName":"Mora","lastName":"Testing"},"org":{"name":"vier_pfoten_at","title":"VIER PFOTEN Österreich"},"orgId":527,"personalInfo":null,"privacy":{"emailStatus":null,"emailStatusChanged":null,"givenAt":"2022-12-19T15:17:29Z","optIn":true,"withConsent":true},"schema":"proca:action:2","stage":"deliver","tracking":{"campaign":"unknown","content":"","location":"https://furfreeeurope.vier-pfoten.at/","medium":"unknown","source":"unknown"}}`;


const test2 = async () => {
  await initialize();
  const msg = JSON.parse(testData);

  console.log('do i exist?', await getContactByRef(msg.contact.contactRef));


  // await call('/field', 'DELETE', {fieldId: 796});
  const list = await createContactList("test");
  const listid = list?.data?.id || await findContactList("test");

  const list2 = await createContactList("test2");
  const listid2 = list2?.data?.id || await findContactList("test2");


  const added = await addContact(msg, listid);
  const added2 = await addContact(msg, listid2);

  console.log('adding to ', added, added2);

  await deleteContactList(listid);
  await deleteContactList(listid2);


}


export const cli = async () => {
  await initialize();
  const opts = parseArg(process.argv.slice(2));

  const p = (x) => console.log(x);
  const pc = (x) => console.log(Array.isArray(x) ? x.map(recordToContact) : x);


  if (opts.L) {
    call('/contactlist').then(p);
  } else if (opts.A) {
    createContactList(opts.A).then(p);
  } else if (opts.l) {
    findContactList(opts.l).then(p);
  } else if (opts.e) {
    getContactByEmail(opts.e).then(pc);
  } else if (opts.i) {
    getContactById(opts.i).then(pc);
  } else if (opts.r) {
    getContactByRef(opts.r).then(pc);
  } else if (opts.D) {
    deleteContactList(opts.D).then(p);
  } else if (opts.C) {
    const msg : ActionMessageV2 = JSON.parse(testData);
    const l = await findContactList(opts.C);
    const c = actionToContact(msg);
    addContact(c, l).then(p);
  } else if (opts.s) {
    const all = await call(`/contact/query/?return=${model.keyId}`);
    for (const c of all.data.result) {
      p(JSON.stringify(recordToContact(c)));
    }
  } else if (opts.m) {
    p(model);
  } else if (opts.country) {
    const c = getCountry(opts.country);
    const n = model.choices.country[c];
    p([c,n]);
  } else if (opts.deleteField) {
    const id = model.fields[opts.deleteField];
    console.log(`will delete field id ${id}`);
    const r = await call(`/field/${id}`, 'DELETE');
    console.log(r);
  } else {
    p(`
${process.argv[0]} cli
  -L       - list contactlists
  -l name  - get contactlist by name
  -e email - get contact by email
  -i id    - get contact by id
  -r ref   - get contact by ref
  -D name  - delete contactlist by name
  -C name  - add sample contact to list name (always same contact data)
  -s       - list all contact ids (first page)
  -m       - print out contact fields model
`);

  }

}

// only if run directly
if (require.main === module) {
  cli();
}

/*
 * when contact exists
 *
 *{
  replyCode: 2009,
  replyText: 'Contact with the external id already exists: 794',
  data: ''
}

 *
 *
 */
