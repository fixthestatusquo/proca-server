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
  try {
    const email: string = action.contact.pii?.email || action.contact.email
    const optIn: boolean = action.privacy.communication
    const campaignTitle: string = action.campaign.title

    // check inputs
    if (!email) throw new Error("Action with no email")
    if (!campaignTitle) throw new Error("Action with missing campaign title")
    if (!process.env.ACTIONNETWORK_APIKEY) throw new Error("ACTIONNETWORK_APIKEY is unset")

    const c = client(process.env.ACTIONNETWORK_APIKEY)

    // fetch form for the campaign
    let form = CACHE.form[campaignTitle]
    if (!form) {
      form = await getForm(c, { title: campaignTitle });
      if (!form) throw new Error("Cannot find form for campaign tiled: " + campaignTitle)
      CACHE.form[campaignTitle] = form
    }


    let newPersonData = actionToPerson(action)
    customizePersonAttrs(newPersonData)
    let person = await getPerson(c, { email: email })
    let updatePerson = false;
    let personUri;

    if (person) { // person exists
      let personAttr = await person.get()
      const personEmailIdx = personAttr.data.email_addresses.findIndex((ea: any) => ea.address === email);
      const personEmail = personAttr.data.email_addresses[personEmailIdx]
      if (personEmail) {
        if (optIn && personEmail.status !== "subscribed") {
          // set the email status to subscribed!
          personAttr.data.email_addresses[personEmailIdx].status = "subscribed"
          updatePerson = true
        }
      } else {
        delete personAttr.data.email_addresses[personEmailIdx].status
        console.error("Weird, person record does not have email we've fetched it by", personAttr.data.email_addresses)
      }

      p(personAttr.data, "CURRENT DATA")
      if (patchPerson(personAttr, newPersonData)) 
        updatePerson = true;

      if (updatePerson) {  // Do the update now if it is necessary
        await person.put(personAttr);
      }
      personUri = personAttr.uri;
    } else {
      const people = await createPerson(c, newPersonData)
      personUri = people.links.get('self')?.href
    }

    const submission = await createSubmission(c, form, personUri, action);
    return submission.uri
  } catch (err) {
    if (err.response) { 
      console.error("Server responded:", await err.response.text())
      throw err
    }
  }
}


const customizePersonAttrs = (attrs : any) => {
  switch (process.env.ACTIONNETWORK_CUSTOMIZE) {
    case 'greensefa': {
      const lang = attrs.languages_spoken[0]
      if (lang) {
        attrs.custom_fields ||= {}
        attrs.custom_fields[`speaks_${lang}`] = "1"
      }

      break
    }
  }
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



// patch an existing contact record
const patchPerson = (personAttr: State<any>, newPersonData: any) => {
  if (personAttr.data.given_name !== newPersonData.given_name ||
     personAttr.data.family_name !== newPersonData.family_name ||
     personAttr.data.identifiers.indexOf(newPersonData.identifiers[0]) < 0 ||
     personAttr.data.postal_addresses.findIndex((pa: any) =>
      pa.country === newPersonData.postal_addresses[0].country &&
      pa.postal_code === newPersonData.postal_addresses[0].postal_code) < 0 ||
    personAttr.data.languages_spoken[0] !== newPersonData.languages_spoken[0]) {

    personAttr.data.given_name = newPersonData.given_name
    personAttr.data.family_name = newPersonData.family_name
    personAttr.data.identifiers = newPersonData.identifiers
    personAttr.data.postal_addresses = newPersonData.postal_addresses
    personAttr.data.languages_spoken = newPersonData.languages_spoken
    return true
  } else {
    return false
  }
}

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

  const r = await submission.post({data})
  } catch (e) {
    console.error(util.inspect(e))
    console.error(await e.response.text())
  }
}

const createSubmission = async(client : Client, form : Resource<any> | State<any>, personUri : string, action : ActionMessage) => {
  const submissionUrl = form.uri + '/submissions'

  const submission = client.go(submissionUrl);
  const data : any = {
    "_links" : {
      "osdi:person" : { "href" : personUri }
    }
  }
  
  if (action.tracking?.source) {
    const rd : any = {
      "source": action.tracking.source
    }
    if (action.tracking.source === "referrer") {
      rd['website'] = action.tracking.campaign
    }
    data["action_network:referrer_data"] = rd
  }
  return await submission.post({data})
};

const createPerson =  async(client : Client , data : any) : Promise<State<any>> => {
  const people = client.go(uri("people"))
  const payload = {data}
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

