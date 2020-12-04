type contact = {
  email: string,
  firstName: string,
  ref: string,
  payload: string
}

type campaign = {
  title: string,
  name: string,
  externalId: number
}

type actionPage = {
  locale: string,
  name: string,
  thankYouTemplateRef: string
}

type action = {
  actionType: string,
  fields: {
    [key: string]: string
    // createdAt ? 
  }
}

type tracking = {
  source: string,
  medium: string,
  campaign: string,
  content: string
}

export type actionMessage = {
  actionId: number,
  actionPageId: number,
  campaignId: number,
  orgId: number,
  action: action,
  contact: contact,
  campaign: campaign,
  actionPage: actionPage,
  tracking: tracking
}
