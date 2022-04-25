import {PersonalInfo} from '@proca/crypto'

export type ProcessStage = "confirm" | "deliver"

type ContactV1 = {
  email: string,
  firstName: string,
  ref: string,
  payload: string,
  signKey?: string,
  publicKey?: string,
  nonce?: string,
}

type ContactV2 = {
  email: string,
  firstName: string,
  contactRef: string
} & { [key: string]: any };

type Campaign = {
  title: string,
  name: string,
  externalId: number
}

type ActionPage = {
  locale: string,
  name: string,
  thankYouTemplateRef: string
}

type ActionV1 = {
  actionType: string,
  fields: {
    [key: string]: string
  },
  createdAt: string
}

type ActionV2 = {
  actionType: string,
  customFields: {
    [key: string]: string | number | string[] | number[]
  },
  createdAt: string
}

type Tracking = {
  source: string,
  medium: string,
  campaign: string,
  content: string
}

type PrivacyV1 = {
  communication: boolean,
  givenAt: string
}

type PrivacyV2 = {
  withConsent: boolean;
  optIn?: boolean;
  givenAt?: string;
  emailStatus: null | 'double_opt_in' | 'bounce' | 'blocked' | 'spam' | 'unsub';
  emailStatusChanged: null | string
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
  personalInfo: PersonalInfo | null,
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
      customFields: a1.action.fields
    },
    contact: {
      contactRef: a1.contact.ref,
      firstName:"",
      email: "",
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
