import {ActionExport, CampaignIds} from './proca'
import {PublicKey} from './crypto'
import {decryptPersonalInfo} from '@proca/crypto'
import {loadKeys} from './keys'
import {DecryptOpts} from './cli'
import {CliConfig} from './config'

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

type PersonalInfo = {
  payload: string,
  nonce: string, 
  encryptKey: PublicKey,
  signKey: PublicKey 
}

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
  optIn: boolean,
  givenAt: string
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
  let personalInfo : PersonalInfo;

  if (a1.contact.nonce) {
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
      firstName: null,
      email: null,
      ...pii
    },
    personalInfo: personalInfo,
    tracking: a1.tracking,
    privacy: a1.privacy && {
      optIn: a1.privacy.communication,
      givenAt: a1.privacy.givenAt
    }
  }
  return a2
};

export const actionToActionMessage = (
  action : ActionExport,
  actionPage: ActionPage & {id: number},
  campaign: CampaignIds) : ActionMessageV2 => {
  let pii = {}
  let personalInfo : PersonalInfo;

  if (action.contact.nonce) {
    personalInfo = {
      payload: action.contact.payload,
      nonce: action.contact.nonce,
      encryptKey: action.contact.publicKey,
      signKey: action.contact.signKey
    }
  } else {
    pii = JSON.parse(action.contact.payload)
  }


  const msg : ActionMessage = {
    schema: "proca:action:2",
    actionId: action.actionId,
    actionPageId: actionPage.id,
    actionPage: actionPage,
    campaignId: campaign.id,
    action: {
      actionType: action.actionType,
      customFields: action.customFields,
      createdAt: action.createdAt,
    },
    contact: {
      contactRef: action.contact.contactRef,
      firstName: null, // XXX exportActions does not return the supporter stored names
      email: null,
      ...pii,
    },
    personalInfo: personalInfo,
    campaign: campaign,
    tracking: action.tracking,
    privacy: action.privacy && {
      optIn: action.privacy.optIn,
      givenAt: action.privacy.givenAt 
    },
    stage: "deliver"
  } 
  return msg;
}


export function decryptActionMessage(action : ActionMessageV2, argv : DecryptOpts, config : CliConfig) {
  if (argv.decrypt && action.personalInfo) {
    const ks = loadKeys(config)
    const pii = decryptPersonalInfo(action.personalInfo, ks)
    if (pii === null) {
      // missing key
      if (!argv.ignore) throw new Error(`No key to decrypt action id ${action.actionId}`)
    } else {
      action.contact = {...action.contact, ...pii}
    }
  }
}
