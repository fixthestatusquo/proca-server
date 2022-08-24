
import type { ActionMessageV2, EventMessageV2 } from '@proca/queue'
const _ = require("lodash");

export interface TrustAction {
  first_name: string;
  last_name?: string | null;
  address?: string | null;
  zip_code?: string | null;
  location?: string | null;
  email: string;
  phone?: string | null;
  country?: string | null;
  message?: string | null;
  subscribe_newsletter: boolean | undefined;
  data_handling_consent: boolean;
  move_code: string;
  origin: string | null;
}

export interface Signature {
  "petition_signature": TrustAction;
}

export const formatAction = (queueAction: ActionMessageV2) => {
  let action: TrustAction = {
    first_name: queueAction.contact.firstName,
    last_name: queueAction.contact.lastName,
    address: queueAction.contact.adress,
    zip_code: queueAction.contact.postcode,
    location: queueAction.contact.city
      || queueAction.contact.area
      || queueAction.contact.locality
      || queueAction.contact.region,
    email: queueAction.contact.email,
    phone: queueAction.contact.phone,
    country: queueAction.contact.country,
    message: queueAction.contact.comment,
    subscribe_newsletter: queueAction.privacy.optIn,
    data_handling_consent: true,
    move_code: queueAction.actionPage.name,
    origin: queueAction.tracking?.location
  }

  const signature: Signature = { "petition_signature": _.omitBy(action, _.isNil) };

  return signature;
  }
