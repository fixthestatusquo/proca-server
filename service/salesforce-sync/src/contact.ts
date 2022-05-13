

import {ActionMessageV2, EventMessageV2} from '@proca/queue'

import countries from 'i18n-iso-countries'
import enCountries from 'i18n-iso-countries/langs/en.json'

countries.registerLocale(enCountries)

//                                              allow custom fields vvv
export interface ContactAttributes extends Record<string, string | boolean | undefined> {
  Email : string;
  FirstName: string;
  LastName?: string;
  Phone?: string;
  MailingCountry?: string;
  MailingPostalCode?: string;
  EmailBouncedReason?: string;
  EmailBouncedDate?: string;
}


export interface LeadAttributes extends Record<string,string | boolean | undefined> {
  Email : string;
  FirstName: string;
  LastName?: string;
  Phone?: string;
  Country?: string;
  PostalCode?: string;
  Company: string;
  EmailBouncedReason?: string;
  EmailBouncedDate?: string;
}

export const isActionSyncable = (action : ActionMessageV2) => {
  return (action.privacy.withConsent && action.privacy.optIn)
}

export type RecordOpts = {
  language?: string;
  doubleOptIn?: boolean;
  optInField?: string;
  defaultLastName?: string;
}

export const countryName = (code : string | undefined) => {
  if (code) {
    return countries.getName(code.toUpperCase(), "en")
  }
  return code
}

export const actionToContactRecord = (action : ActionMessageV2, opts : RecordOpts) : ContactAttributes => {
  const c : ContactAttributes = {
    FirstName: action.contact.firstName,
    LastName: action.contact.lastName || opts.defaultLastName,
    Email: action.contact.email,
    Phone: action.contact.phone,
    MailingCountry: countryName(action.contact.country),
    MailingPostalCode: action.contact.postcode
  }

  determineOptIn(c, action.privacy, opts)

  if (opts.language) {
    c[opts.language] = action.actionPage.locale
  }

  return c
}

export const actionToLeadRecord = (action : ActionMessageV2, opts : RecordOpts) : LeadAttributes => {
  const c : LeadAttributes = {
    FirstName: action.contact.firstName,
    LastName: action.contact.lastName || opts.defaultLastName,
    Email: action.contact.email,
    Phone: action.contact.phone,
    Country: countryName(action.contact.country),
    PostalCode: action.contact.postcode,
    Company: '[not provided]',
    LeadSource: action.campaign.title
  }

  determineOptIn(c, action.privacy, opts)

  if (opts.language) {
    c[opts.language] = action.actionPage.locale
  }

  return c
}

export const determineOptIn = (r : LeadAttributes | ContactAttributes, privacy : ActionMessageV2['privacy'], opts : RecordOpts) => {
  // consents
  // explicit DOI = must be subscribe
  let optIn = false
  if (privacy.emailStatus === "double_opt_in") {
    optIn = true
  // bouncing - cleaned / banned
  } else if (privacy.emailStatus !== null) {
    optIn = false
    r.EmailBouncedReason = privacy.emailStatus
    if (privacy.emailStatusChanged) r.EmailBouncedDate = privacy.emailStatusChanged
  } else {
    // else, lets infer:
    if (privacy.optIn) {
      // we have some opt in
      if (opts.doubleOptIn) {
        // id DOI, wait
        optIn = false
      } else {
        // otherwise it's ok
        optIn = true
      }
    } else {
      optIn = false
    }
  }

  if (opts.optInField) {
    r[opts.optInField] = optIn
  }
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
