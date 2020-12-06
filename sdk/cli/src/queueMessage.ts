import {ProcessSage} from './queue'

type Contact = {
  email: string,
  firstName: string,
  ref: string,
  payload: string,
  signKey: string,
  publicKey: string,
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
  campaignId: number,
  orgId: number,
  action: Action,
  contact: Contact,
  campaign: Campaign,
  actionPage: ActionPage,
  tracking: Tracking,
  privacy: Privacy,
  schema: "proca:action:1",
  stage: ProcessStage

}
