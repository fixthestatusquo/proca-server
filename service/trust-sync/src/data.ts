
import type { ActionMessageV2 } from '@proca/queue'
const _ = require("lodash");

interface AditionalAttributes {
  name: string;
  value: string;
}

export interface TrustAction {
  first_name: string;
  last_name?: string | null;
  address1?: any;
  zip_code?: string | null;
  location?: any;
  email: string;
  phone?: string | null;
  country?: string | null;
  message?: string | null;
  subscribe_newsletter: boolean;
  data_handling_consent: boolean;
  move_code: string;
  origin: string | null;
  additional_attributes_attributes: AditionalAttributes[];
}

export interface Signature {
  "petition_signature": TrustAction;
}

export interface Verification {
  "petition_signature": VerificationParams;
}

interface VerificationParams {
  "subscribe_newsletter": boolean;
  "data_handling_consent": boolean;
}

export const handleConsent = (action: ActionMessageV2) => {
  return action.privacy.emailStatus !== 'double_opt_in' && !action.action.customFields.isSubscribed ? false : true
}

export const formatAction = (queueAction: ActionMessageV2) => {
  const postData = queueAction;

  let action: TrustAction = {
    first_name: postData.contact.firstName,
    last_name: postData.contact.lastName,
    zip_code: postData.contact.postcode,
    email: postData.contact.email,
    phone: postData.contact.phone,
    country: postData.contact.country,
    message: postData.contact.comment,
    subscribe_newsletter: postData.privacy.emailStatus === 'double_opt_in',
    data_handling_consent: handleConsent(queueAction),
    move_code: "AKT" + postData.campaign.externalId,
    origin: postData.tracking?.location,
    additional_attributes_attributes: [
      {name: "petition_id", value: postData.actionPage.name},
      {name: "Aktion",  value: "AKT" + postData.campaign.externalId}
    ]
  }

  if (postData.contact.address?.street) action.address1 = postData.contact.address?.street;
  if (postData.contact.address?.locality) action.location = postData.contact.address?.locality;

  const signature: Signature = { "petition_signature": _.omitBy(action, _.isNil) };

  return signature;
  }
