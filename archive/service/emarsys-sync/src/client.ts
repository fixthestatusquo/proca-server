// they lack default export
import * as crypto from 'crypto';
import * as minimist from 'minimist';

import {ActionMessageV2} from '@proca/queue';

import debug from 'debug';

const log = debug('sync.client');


export const REPLY_CODE = {
  CONTACT_EXISTS: 2009,
  LIST_EXISTS: 3005
};

export const REF_FIELD = "identifier";

/** GENERAL INFO
 *

Introduction to the Emarsys API:

https://help.emarsys.com/hc/en-us/articles/115004745889-introduction-to-the-emarsys-api

Contact data fields – Overview:

https://help.emarsys.com/hc/en-us/articles/115004637605-overview-contact-data-fields-overview

Data exchange resources (from our point of view, only the part regarding the API is interesting there):

https://help.emarsys.com/hc/en-us/articles/213705529-data-exchange-resources

The Dev
Hub (https://dev.emarsys.com/docs/emarsys-api/ZG9jOjI0ODk5Njk2-what-s-new)
should speak for itself. Create, Update, and Delete
Contacts (https://dev.emarsys.com/docs/emarsys-api/ZG9jOjI0ODk5NzE5-create-update-and-delete-contacts)
are probably the most important endpoints for you. Also note the articles on the
concept of the Emarsys API, as well as the very useful pages about the response
codes at the bottom of the page menu.

 *
 */

/*
 * AUTH
 * https://dev.emarsys.com/docs/emarsys-api/10827827b819d-3-configure-authentication
 *
 * */

function getWsseHeader(user, password) {
  let nonce = crypto.randomBytes(16).toString('hex');
  let timestamp = new Date().toISOString();

  let digest = base64Sha1(nonce + timestamp + password);

  return `UsernameToken Username="${user}", PasswordDigest="${digest}", Nonce="${nonce}", Created="${timestamp}"`
};

function base64Sha1(str) {
  let hexDigest = crypto.createHash('sha1')
    .update(str)
    .digest('hex');

  return new Buffer(hexDigest).toString('base64');
};


export const lastRequestIds : Record<string, string> = {};

export const call = async (path:string, method = 'GET', data:Record<string,any> = undefined) : Promise<any> => {
  const user = process.env.EMARSYS_USER;
  const password = process.env.EMARSYS_PASSWORD;

  if (path[0] !== '/') throw new Error('call(path): path must begin with /');

  const opts : RequestInit = {
    method,
    headers: {
      'Content-Type': 'application/json',
      'X-WSSE': getWsseHeader(user, password)
    }
  };

  if (data) {
    opts.body = JSON.stringify(data);
  }

  // console.debug(opts);

  const url = process.env.EMARSYS_URL || 'https://api.emarsys.net/api/v2';

  const r = await fetch(url + path, opts);
  const body = await r.text();
  lastRequestIds[path] = r.headers.get('x-emarsys-request-id');

  try {
    if (r.status === 200 || r.status === 400) {
      return JSON.parse(body);
    } else {
      throw Error(body);
    }
  } catch (e) {
    throw Error(`API error ${e}, ${r.status}: ${r.statusText} (request ${r.headers['x-emarsys-request-id']})`);
  }
}


/*
 *
    If no timezone is provided, the timezone of our server is assumed, which is GMT+1. Under these circumstances, the timestamp 2014-01-01T01:01:01 is translated as 2014-01-01T01:01:01+01:00.

    Note: During daylight saving time, our server's timezone is GMT+2.

    The Created timestamp must be within five minutes of the Emarsys server's time. If it is not within the specified time frame, the request is rejected.

 *
 */


/**
 * Endpoints
 *
 * Contacts: A contact is an end customer, such as a potential recipient of
 * marketing campaigns. Contacts can be grouped into either contact lists or
 * segments. While contact lists are static, segments include contacts
 * dynamically if they meet a certain filtering criteria.
 *
 * Fields: A field stores contact-related data as key-value pair properties.
 *
 * Contact lists: A contact list is static group of contacts. Once you define a
 * contact list, it does not change based on contextual critera, as segments do.
 * You can modify existing contact lists in the application or via the API.
 *
 * Email campaign lifecycle: Campaign launch endpoints allow you to manage an
 * existing email campaign.
 *
 * Segments: A segment is a group of contacts generated dynamically based on
 * custom-defined criteria, called a filter. Each time a segment is used, the
 * filter runs and the group of contacts in the segment is updated. You can save
 * segments as contact lists to make them static.
 *
 * Contact sources: A contact source is used to import contacts into the Emarsys
 * database as well as to track the origin of contact data changes. Updating
 * existing contact sources is not supported currently.
 *
 * Forms: A form is useful to collect data from contacts, such as registration
 * form on a web page. Creating, updating, and deleting existing forms is not supported at the moment.
 *
 * */

type Model = {
  fields: Record<string,number>;
  choices: Record<string, Record<string, string>>;
  keyId: number;
}

export const model : Model = {
  fields: {},
  choices: {},
  keyId: 0
}


// https://dev.emarsys.com/docs/emarsys-api/a81cf8d07d15c-create-a-contact-list
export const createContactList = async (name : string, description = "Proca Campaign") => {
  const c = await call('/contactlist', 'POST', {
    key_id: model.keyId,
    name,
    description
  });
  if (c.data?.id) {
    return c.data.id;
  }
  return c;
}



export const deleteContactList = async (id:number) => {
  const c = await call(`/contactlist/${id}/deletelist`, 'POST');
  return c;
}

export const findContactList = async (name:string) => {
  const lists = await call('/contactlist');
  for (const l of lists.data) {
    if (l.name === name) {
      return l.id;
    }
  }
}

export const createField = async (name:string) => {
  const c = await call('/field', 'POST', {name, application_type: 'shorttext'});
  return c;
}



export const initialize = async () => {
  await createField(REF_FIELD);
  const fields = await call('/field');

  for (const f of fields.data) {
    model.fields[f.string_id] = f.id;
    if (f.application_type === 'singlechoice') {

      const ch = await call(`/field/${f.id}/choice/translate/en`);
    //  console.log(`choices ${f.string_id}`, ch);
      model.choices[f.string_id] = ch.data.reduce((agg, {id, choice}) => { agg[choice] = id; return agg}, {});
    }
  }

  model.keyId = model.fields[REF_FIELD];



}

export const contactToRecord = (contact : Record<string, any>, only?:string[]) => {
  const record : Record<string, any> = {key_id: model.keyId};

  for (const f in contact) {
    // if we only want certain fields in record (for example for updated)
    if (only && f !== REF_FIELD && only.indexOf(f) < 0) continue;

    const v = contact[f];
    if (typeof v === 'undefined') continue;

    const idx = model.fields[f];

    if (f in model.choices) {
      // choice
      const choice_id = model.choices[f][v];
      /// console.log(`Choice: ${v} => ${choice_id}`)
      if (choice_id) {
        record[`${idx}`] = choice_id;
      } else {
        log('Field %s: choice value %s not found', f, v);
      }
    } else {
      record[`${idx}`] = v;
    }
  }
  return record;
}


export const recordToContact = (record : Record<string, any>) : Record<string,any> => {
  const idxToField = Object.entries(model.fields).reduce((acc, [k,v]) => { acc[v] = k; return acc; }, {});

  return Object.entries(record).reduce((agg, [k,v]) => {
    if (v === null) return agg;

    const kid = parseInt(k);

    if (!isNaN(kid)) {
      agg[idxToField[k]] = v;
    } else {
      agg[k] = v;
    }
    return agg;
  }, {});

}

export const addToList = async (listId, contactId) => {
  const r = await call(`/contactlist/${listId}/add`, 'POST', {key_id: model.keyId, external_ids: [contactId]});
  return r;
}

export const addContact = async (contact : Record<string, any>, listId? : string) => {
  const record = contactToRecord(contact);

  console.debug('Adding contact', recordToContact(record));

  // console.debug(payload);
  if (listId) {
    record.contact_list_id = listId
  }

  const r = await call('/contact', 'POST', record);

  if (r.replyCode === REPLY_CODE.CONTACT_EXISTS) {
    // lets patch the record
    const r1 = await updateContact(contact);
    const r2 = await addToList(listId, record[REF_FIELD]);
    return r1;
  } else {
    return r;
  }
}

export const updateContact = async (contact : Record<string, any>, unsubscribe = false) => {
  const existing = await getContactByRef(contact[REF_FIELD]);

  if (!existing)
    throw new Error(`Cannot add nor fetch contact by ref ${contact[REF_FIELD]} ${JSON.stringify(contact, null, 2)} (GET contact id: ${lastRequestIds['/contact/getdata']}, POST contact id: ${lastRequestIds['/contact']})`);

  const fields : string[] = [
    'first_name', 'last_name', 'salutation', 'phone', 'address', 'city',
    'state', 'zip_code', 'country', 'registration_date'];

  // only if existing record has empty key1
  if (existing[0][model.fields.key1] === null) {
    fields.push('key1');
  }

  if (unsubscribe) {
    fields.push('optin');
  }


  if (fields.length > 0) {
    const update = contactToRecord(contact, fields);

    console.log(`data to update (unsub=${unsubscribe})`, update);
    const r = await call('/contact/', 'PUT', update);
    return r;
  }
  return {replyCode: 0, replyText: 'OK'};
}

export const getContactByRef = async (ref:string) : Promise<Record<string,any>> => {
  const c = await call('/contact/getdata', 'POST', {keyId: model.keyId, keyValues: [ref]});
  //console.log(c);
  return c.data.result
}

export const getContactById = async (id:string) : Promise<Record<string,any>> => {
  const c = await call('/contact/getdata', 'POST', {keyId: 'id', keyValues: [id]});
  return c.data.result
}

export const getContactByEmail = async (email:string) : Promise<Record<string,any>> => {
  const c = await call('/contact/getdata', 'POST', {keyId: model.fields.email, keyValues: [email]});
  //console.log(c);
  return c.data.result
}
