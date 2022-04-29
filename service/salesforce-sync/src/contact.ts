

import {ActionMessageV2, EventMessageV2} from '@proca/queue'


//                                              allow custom fields vvv
export interface ContactAttributes extends Record<string, string | boolean | undefined> {
  Email : string;
  FirstName: string;
  LastName?: string;
  Phone?: string;
  MailingCountry?: string;
  MailingPostalCode?: string;
}


export interface LeadAttributes extends Record<string,string | boolean | undefined> {
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
  doubleOptIn?: boolean
  optInField?: string
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

  if (opts.optInField) {
    if (opts.doubleOptIn) {
    // we ignore the optIn and wait for double opt in
      c[opts.optInField] = false
    } else {
      c[opts.optInField] = action.privacy.optIn
    }
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
    Company: '[not provided]',
    LeadSource: action.campaign.title
  }

  if (opts.optInField) {
    if (opts.doubleOptIn) {
    // we ignore the optIn and wait for double opt in
      c[opts.optInField] = false
    } else {
      c[opts.optInField] = action.privacy.optIn
    }
  }

  if (opts.language) {
    c[opts.language] = action.actionPage.locale
  }

  return c
}

export interface EmailStatusAttributes {
  Email: string;
  EmailBouncedReason?: string
  EmailBouncedDate?: string
}

export const emailChangedToContactRecord = (event : EventMessageV2, optInField:string) : EmailStatusAttributes & Record<string, string| boolean> | null => {
  const emailStatus = event.supporter.privacy.emailStatus
  const emailStatusChanged = event.supporter.privacy.emailStatusChanged
  if (emailStatus === 'double_opt_in' && emailStatusChanged) {
    const r : EmailStatusAttributes & Record<string,string|boolean> = {
      Email: event.supporter.contact.email
    }
    r[optInField] = true
    return r

  } else if (emailStatusChanged && (emailStatus === 'bounce' || emailStatus === 'blocked' || emailStatus === 'unsub' || emailStatus === 'spam')) {
    const r = {
      Email: event.supporter.contact.email,
      EmailBouncedReason: emailStatus,
      EmailBouncedDate: emailStatusChanged
    }
    return r
  }

  return null
}
