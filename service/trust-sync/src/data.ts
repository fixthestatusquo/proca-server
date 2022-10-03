
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
  petition_id: string;
  aktion: string | undefined;
}

export interface Signature {
  "petition_signature": TrustAction;
}

export const formatAction = (queueAction: ActionMessageV2) => {
  const postData = queueAction;

  let action: TrustAction = {
    first_name: postData.contact.firstName,
    last_name: postData.contact.lastName,
    address: postData.contact.adress,
    zip_code: postData.contact.postcode,
    location: postData.contact.city
      || postData.contact.area
      || postData.contact.locality
      || postData.contact.region,
    email: postData.contact.email,
    phone: postData.contact.phone,
    country: postData.contact.country,
    message: postData.contact.comment,
    subscribe_newsletter: postData.privacy.emailStatus === 'double_opt_in',
    data_handling_consent: true,
    move_code: postData.actionPage.name,
    origin: postData.tracking?.location,
    petition_id: postData.actionPage.name,
    aktion: "AKT" + postData.campaign.externalId
  }

  const signature: Signature = { "petition_signature": _.omitBy(action, _.isNil) };

  return signature;
  }
