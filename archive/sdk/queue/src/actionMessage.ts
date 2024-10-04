import {PersonalInfo} from '@proca/crypto'

/**
 * The format of action + contact data stored as JSON in the processing queue.
 * Current format is: V2 - see MessageV2 below
 * (V1 is only used by older users) - see MessageV1
 *
 * */

// confirm only if we are confirming the email
// deliver means action is ready for delivery (to CRM, etc)
export type ProcessStage = "confirm" | "deliver"

export type ContactV1 = {
  email: string,
  firstName: string,
  ref: string,
  payload: string, // JSON of other PII data, or base64url of encrypted JSON of PII
  signKey?: string, // signinig key id, not given when no encryption
  publicKey?: string, // encryption key id
  nonce?: string, // nonce, base64url
  area: string | null,
}

export type ContactV2 = {
  email: string,
  firstName: string,
  contactRef: string,
  area: string | null
} & { [key: string]: any }; // other keys, usually:
                            // lastName, phone, country, postcode, area,
                            // address: {region, locality, street, streetNumber}
                            // but it can differ for different PII schema

type Campaign = {
  title: string,    // long name
  name: string,     // technical name
  externalId: number  // can be set by owner of campaign
}

type ActionPage = {
  locale: string,              // language or full locale eg: pl, de_AT
  name: string,                // technical name
  thankYouTemplate: string     // name of thank you template
  thankYouTemplateRef: string  // backwards compatibility - id of tempalte resolved from Mailjet etc
}

type ActionV1 = {
  actionType: string,
  fields: {
    [key: string]: string
  },
  createdAt: string,
  testing: boolean
}

type ActionV2 = {
  actionType: string,
  customFields: {
    [key: string]: string | number | boolean | string[] | number[]
  }, // map of keys to values, or lists of values, not nested
  createdAt: string,
  testing: boolean // is this a test action? (to be discarded)
}

type Tracking = {
  source: string,   // utm_*
  medium: string,
  campaign: string,
  content: string,
  location: string  // what url was the form on?
}
export type PrivacyV1 = {
  communication: boolean, // consent for communication (newsletter etc) was given on form
  givenAt: string
}

export type PrivacyV2 = {
  withConsent: boolean;  // this action had a consent under form (visible or implicit)
  optIn?: boolean;       // consent for communication
  givenAt?: string;
  emailStatus: null | 'double_opt_in' | 'bounce' | 'blocked' | 'spam' | 'unsub';
  // email Status describes reliability of email:
  // - null - no knowledge
  // - double_opt_in - confirmed that newsletter is wanted
  // - bounce, blocked - declared by email service that is not deliverable
  // - unsub, spam - declared by email service that user does not want to be contacted
  emailStatusChanged: null | string  // JSON date-time format
}

export type ActionMessage = ActionMessageV1 | ActionMessageV2;

export type ActionMessageV1 = {
  actionId: number,
  actionPageId: number,
  campaignId: number,
  // orgId: number,
  action: ActionV1,
  contact: ContactV1,
  campaign: Campaign,
  actionPage: ActionPage,
  tracking: Tracking,
  privacy: PrivacyV1,
  schema: "proca:action:1",
  stage: ProcessStage
}

export type ActionMessageV2 = {
  actionId: number,
  actionPageId: number,
  campaignId: number,
  // orgId: number,
  action: ActionV2,
  contact: ContactV2,
  personalInfo: PersonalInfo | null, // null if no encryption
  campaign: Campaign,
  actionPage: ActionPage,
  tracking: Tracking,
  privacy: PrivacyV2,
  schema: "proca:action:2",
  stage: ProcessStage
}

export const actionMessageV1to2 = (a1 : ActionMessageV1) : ActionMessageV2 => {
  let pii = {}
  let personalInfo : PersonalInfo | null = null;

  if (a1.contact.nonce && a1.contact.publicKey && a1.contact.signKey) {
    personalInfo = {
      payload: a1.contact.payload,
      nonce: a1.contact.nonce,
      encryptKey: {
        id: 0, // XXX no id info here!
        public: a1.contact.publicKey
      },
      signKey: {
        id: 0, // XXX no id info here!
        public: a1.contact.signKey
      }
    }
  } else {
    pii = JSON.parse(a1.contact.payload)
  }

  const a2 : ActionMessageV2 = {
    schema: "proca:action:2",
    stage: a1.stage,
    actionId: a1.actionId,
    actionPage: a1.actionPage,
    actionPageId: a1.actionPageId,
    campaign: a1.campaign,
    campaignId: a1.campaignId,
    action: {
      actionType: a1.action.actionType,
      createdAt: a1.action.createdAt,
      customFields: a1.action.fields,
      testing: false
    },
    contact: {
      contactRef: a1.contact.ref,
      firstName:"",
      email: "",
      area: a1.contact.area,
      ...pii
    },
    personalInfo: personalInfo,
    tracking: a1.tracking,
    privacy: a1.privacy && {
      withConsent: true,
      optIn: a1.privacy.communication,
      givenAt: a1.privacy.givenAt,
      emailStatus: null,
      emailStatusChanged: null
    }
  }
  return a2
};
