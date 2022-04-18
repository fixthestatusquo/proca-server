

import {ActionMessageV2} from '@proca/queue'

export type ContactAttributes = {
  Email : string;
  FirstName: string;
  LastName?: string;
  Phone?: string;
  MailingCountry?: string;
  MailingPostalCode?: string;
  Languages__c?: string;
}


export const isActionSyncable = (action : ActionMessageV2) => {
  return (action.privacy.withConsent && action.privacy.optIn)
}

export const actionToContactRecord = (action : ActionMessageV2) : ContactAttributes => {
  const c : ContactAttributes = {
    FirstName: action.contact.firstName,
    LastName: action.contact.lastName,
    Email: action.contact.email,
    Phone: action.contact.phone,
    MailingCountry: action.contact.country,
    MailingPostalCode: action.contact.postcode
  }

  c.Languages__c = action.actionPage.locale

  return c
}
