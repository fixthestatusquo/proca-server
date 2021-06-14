import * as admin from './proca'
import {ActionWithPII} from './crypto'

export type ProcessStage = "confirm" | "deliver"

type Contact = {
  email: string,
  firstName: string,
  ref: string,
  payload: string,
  signKey: string,
  publicKey: string,
  nonce: string,
  pii?: any
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

type Action = {
  actionType: string,
  fields: {
    [key: string]: string
  },
  createdAt: string
}

type Tracking = {
  source: string,
  medium: string,
  campaign: string,
  content: string
}

type Privacy = {
  communication: boolean,
  givenAt: string
}

export type ActionMessage = {
  actionId: number,
  actionPageId: number,
  // campaignId: number,
  // orgId: number,
  action: Action,
  contact: Contact,
  campaign: Campaign,
  actionPage: ActionPage,
  tracking: Tracking,
  privacy: Privacy,
  schema: "proca:action:1",
  stage: ProcessStage

}

export const actionToActionMessage = (action : admin.Action & ActionWithPII) : ActionMessage => {
  const msg : ActionMessage = {
    schema: "proca:action:1",
    actionId: action.actionId,
    actionPageId: action.actionPage.id,
    action: {
      actionType: action.actionType,
      fields: action.fields.reduce((acc, f) => { acc[f.key] = f.value; return acc; }, {} as Record<string, string>),
      createdAt: action.createdAt,
    },
    contact: {
      ...action.contact,
      ref: action.contact.contactRef,
      firstName: action.contact.pii.firstName, 
      email: action.contact.pii.email, 
      signKey: action.contact.signKey?.public,
      publicKey: action.contact.publicKey?.public
    },
    campaign: {...action.campaign, title: null}, // XXX fix this!!! campaign titles not in API export
    actionPage: {...action.actionPage, thankYouTemplateRef: null},
    tracking: action.tracking,
    privacy: {
      communication: action.privacy.optIn,
      givenAt: action.privacy.givenAt 
    },
    stage: "deliver"
  } 
  return msg;
}
