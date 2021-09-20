// Only import Types here
// Import code below using require( ) because ketting is just a peer/plug-in dependency
import { Client, LinkNotFound, State, Resource, FollowPromiseOne} from "ketting"
import {ActionMessage} from "../queueMessage"
import {CliConfig} from '../config'
import {ServiceOpts} from '.'

import util from 'util'

export const API_ENDPOINT = "https://actionnetwork.org/"
// api/v2

type Cache = {
  [key: string] : Record<string, Resource<any>>
}

const CACHE : Cache = {form: {}}

export async function syncAction(action : ActionMessage, _1 : ServiceOpts, _2 : CliConfig) {
  const email : string = action.contact.pii?.email || action.contact.email
  const optIn : boolean = action.privacy.communication
  const campaignTitle : string = action.campaign.title

  // check inputs
  if (!email) throw new Error("Action with no email")
  if (!campaignTitle) throw new Error("Action with missing campaign title")
  if (!process.env.ACTIONNETWORK_APIKEY) throw new Error("ACTIONNETWORK_APIKEY is unset")

  const c = client(process.env.ACTIONNETWORK_APIKEY)

  // fetch form for the campaign
  let form = CACHE.form[campaignTitle]
  if (!form) {
    form = await getForm(c, {title: campaignTitle});
    if (!form) throw new Error("Cannot find form for campaign tiled: " + campaignTitle)
    CACHE.form[campaignTitle] = form
  }

  let newPersonData = actionToPerson(action)
  let person = await getPerson(c, {email: email})
  let updatePerson = false;
  let personAttr;

  if (person) { // person exists
    personAttr = await person.get()
    const personEmailIdx = personAttr.data.email_addresses.find((ea : any) => ea.address === email);
    const personEmail = personAttr.data.email_addresses[personEmailIdx];
    if (personEmail) { 
      if (optIn && personEmail.status !== "subscribed") {
        // set the email status to subscribed!
        personAttr.data.email_addresses[personEmailIdx].status = "subscribed"
        updatePerson = true
      }
    } else {
      console.error("Weird, person record does not have email we've fetched it by", personAttr.data.email_addresses)
    }

    if (updatePerson)  {  // Do the update now if it is necessary
      await person.put(personAttr);
    }
  } else {
    personAttr = await createPerson(c, {data: newPersonData})
  }

  const submission = await createSubmission(c, form, personAttr);
  p(submission.uri, "Created submission:")
  return submission.uri
}

const p = (x : any, label = ">>>") => console.log(label, util.inspect(x, false, null, true))

type FetchMiddleware =
  (request: Request, next: (request: Request) => Promise<Response>) => Promise<Response>;

type Filter = Record<string, string>;

export const AUTH_HEADERS = (token: string) : FetchMiddleware => {
  return (request, next) => {
    request.headers.set('OSDI-API-token', token);
    request.headers.set('Content-Type', 'application/json');
    return next(request);
  };
}

export const client = (token : string) => {
  let ketting
  try { 
    ketting = require("ketting");
  } catch (e) {
    console.error("Install ketting package")
    throw e
  }

  const client = new ketting.Client(API_ENDPOINT)
  client.use(AUTH_HEADERS(token));
  return client;
};

function uri (path: string, filter  : Record<string,string> = {}) : string {
  let u = `/api/v2/${path}`;
  const fk = Object.keys(filter)
  if (fk.length > 0) { 
    const fe = fk.map((field) => `${field} eq '${filter[field]}'`).join(' and ')
    u += '?filter=' + encodeURIComponent(fe);
  }
  
  console.log('url', u)
  return u;
}



/* 
    Before adding a contact, we first lookup if a contact already exist with the same email. 

    1. If the contact doesn't exist (meaning, new contact), we set the status to subscribed/unsubscribed depending on the choice from the person. In our case, it's a checkbox in a form (opt in).
    2. If the contact previously exist, and they have checked the opt in for this submit, we set it to "subscribed". 
    3. If the contact previously exist, and they haven't checked the opt in (thus, not consenting), we do not set status at all, and rely on any previous consent. 

    create(subscribed == optIn)

    update(subscribed = subscribed || optIn)

    note: 
    email statuses can be one of:
     ["subscribed", "unsubscribed", "bouncing", "previous bounce", "spam complaint", or "previous spam complaint"]
    phone statuses can be one of:
     ["subscribed", "unsubscribed", "bouncing", or "previous bounce"]. 
    For existing person, we want to change to "subscribed" only the "unsubsribed", not the "bouncing" and so on.


 */

 const actionToPerson = (action : ActionMessage) : any => {
   if (Object.keys(action.contact.pii).length === 0) 
    return undefined;

  const pii = action.contact.pii;

  const dEmail = (email : string) => ({
    primary: true, 
    address: email, 
    status: action.privacy.communication ? "subscribed" : "unsubscribed"
  });

  const dPhone = (num : string) => ({
    primary: true, 
    number: num,
    number_type: "mobile",
    status: action.privacy.communication ? "subscribed" : "unsubscribed"
  });

  const dAddress = () => ({
    primary: true,
    postal_code: pii.postcode,
    country: pii.country 
  });

  const d : any = {
    given_name: pii.firstName,
    family_name: pii.lastName,
    identifiers: [
      "proca:" + action.contact.ref
    ],
    languages_spoken: [action.actionPage.locale.split("_")[0]],
    email_addresses: [dEmail(pii.email)],
    postal_addresses: [dAddress()]
  }

  if (pii.phone) {
    d['phone_numbers'] = [dPhone(pii.phone)]
  }

  return d;
 };

const putAction = async (client : Client, action: ActionMessage) => {
  const campaignTitle = action.campaign.title

  const forms = client.go(uri("forms", {"title": campaignTitle}))

  let form

  try {
    form = await forms.follow('osdi:forms') //.follow("osdi:record_submissions_helper")
  } catch (e) {
    throw Error("Cannot find campaign with title " + campaignTitle + "; " + (e.response ? await e.response.text() : "."))
  }

  let formState = await form.get()
  const submissionUrl = formState.follow('osdi:submissions').uri

  let submission = client.go(submissionUrl);

  try {
    const person = actionToPerson(action)
    person.tags = ['pizza'];
    const data = { 
      identifiers: [`proca:${action.actionId}`],
      originating_system: "Proca.org",
      person: person
    };
    p(data);

  const r = await submission.post({data})
  } catch (e) {
    console.error(util.inspect(e))
    console.error(await e.response.text())
  }
}

const createSubmission = async(client : Client, form : Resource<any> | State<any>, person : Resource<any> | State<any>) => {
  const submissionUrl = form.uri + '/submissions'

  const submission = client.go(submissionUrl);
  const data = {
    "_links" : {
      "osdi:person" : { "href" : person.uri }
    }
  }
  return await submission.post({data})
};

const createPerson =  async(client : Client , data : any) : Promise<State<any>> => {
  const people = client.go(uri("people"))
  return await people.post({data})
};

const getPerson = async (client : Client, filter: Filter) : Promise<Resource<any>> => {
  const people = client.go(uri("people", filter))
  const person = await maybeNotFound(people.follow("osdi:people"))
  return person
}

const getForm = async (client : Client, filter: Filter) : Promise<Resource<any>> => {
  const forms = client.go(uri("forms", filter))
  const form = await maybeNotFound(forms.follow('osdi:forms'))
  return form
}

const maybeNotFound = async <X>(promise : FollowPromiseOne<X>) : Promise<Resource<X>> => {
  try { 
    return await promise;
  } catch (e) { 
    if (e instanceof LinkNotFound) {
      return undefined
    } 
    throw e;
  }
}

function getAll<T>(promiseList : Resource<T>[]) : Promise<State<T>[]> {
  return Promise.all(promiseList.map(x => x.get()))
}


const testAction: ActionMessage = {
  actionId: 13,
  schema: "proca:action:1",
  tracking: null,
  stage: "deliver",
  action: {
    actionType: "register",
    fields: {},
    createdAt: "2021-09-20T10:00:00Z"
  },
  campaign: { title: "Another Form", name: "foo", externalId: null },
  actionPage: { name: "test/en", locale: "en", thankYouTemplateRef: null},
  actionPageId: 123,
  contact: {
    firstName: "", email: "", payload: "{}", ref: "THOM1239436860",
    pii: {
      firstName: "Tester",
      lastName: "Marcin", 
      email: "tester@gmail.com",
      country: "DE", postcode: "12345"
    },
    nonce: null, signKey: null, publicKey: null,
  },
  privacy: {
    communication: false, givenAt: "2021-09-20T10:00:00Z"
  }
}

export const toy = async (client : any) => {
  const pj = (x:any) => console.log(JSON.stringify(x, null, 2))

  const form = await getForm(client, {title: "Another Form"})

  p(form, "FORM")
  p(form.uri, "FORM uri")
/*
  const darth  = await getPerson(client , {email: "darth@gmail.com"})

  p(darth, "DARTH")

  const darthData = await darth.get()
  darthData.data.email_addresses[0].status = 'subscribed'
  const z = await darth.put(darthData)

  p(z, 'update result')
*/
  /*await create(client, personData());

  const res = await get(client, {email_address: 'dump+1@cahoots.pl'})
  const resData = await res.get();
  pj(resData?.data)
  */

/*
  pj(exists.data)
  
  try {
  const ppl = await res.follow('osdi:people')
  p(ppl)

  const member = await ppl.get()
  pj(member.data)

  const toggle = (x :any) => {
    if (x.status === "subscribed") {
      x.status = "unsubscribed"
    } else { 
      x.status = "subscribed"
    }
  }

  toggle(member.data.email_addresses[0])
  const ures = await ppl.put(member)
  p(ures)
  } catch (e) {
    console.error('not found' ,e)
    console.log(e instanceof LinkNotFound);
  }

  // const p1 = await Promise.all(ppl.map((x:any) => x.get()))
  //pj(p1.map((x:any) => x.data))
 */
  
}

// toy(client(process.env.ACTIONNETWORK_APIKEY))
