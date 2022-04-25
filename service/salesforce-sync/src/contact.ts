

import {ActionMessageV2} from '@proca/queue'


//                                              allow custom fields vvv
export interface ContactAttributes extends Record<string, string | undefined> {
  Email : string;
  FirstName: string;
  LastName?: string;
  Phone?: string;
  MailingCountry?: string;
  MailingPostalCode?: string;
}


export interface LeadAttributes extends Record<string,string | undefined> {
  Email : string;
  FirstName: string;
  LastName?: string;
  Phone?: string;
  Country?: string;
  PostalCode?: string;
  Company: string;
}

export const isActionSyncable = (action : ActionMessageV2) => {
  return (action.privacy.withConsent && action.privacy.optIn)
}

export type RecordOpts = {
  language?: string;
}

export const actionToContactRecord = (action : ActionMessageV2, opts : RecordOpts) : ContactAttributes => {
  const c : ContactAttributes = {
    FirstName: action.contact.firstName,
    LastName: action.contact.lastName,
    Email: action.contact.email,
    Phone: action.contact.phone,
    MailingCountry: action.contact.country,
    MailingPostalCode: action.contact.postcode
  }

  if (opts.language) {
    c[opts.language] = action.actionPage.locale
  }

  return c
}

export const actionToLeadRecord = (action : ActionMessageV2, opts : RecordOpts) : LeadAttributes => {
  const c : LeadAttributes = {
    FirstName: action.contact.firstName,
    LastName: action.contact.lastName,
    Email: action.contact.email,
    Phone: action.contact.phone,
    Country: action.contact.country,
    PostalCode: action.contact.postcode,
    Company: 'Proca',
    LeadSource: action.campaign.title
  }

  if (opts.language) {
    c[opts.language] = action.actionPage.locale
  }

  return c
}
