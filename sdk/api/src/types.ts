import * as types from './apiTypes'


export function isPublicActionPage(ap: types.PrivateActionPage | types.PublicActionPage):  ap is types.PublicActionPage {
  return (ap as types.PrivateActionPage).extraSupporters === undefined
}

export function isPrivateActionPage(ap: types.ActionPage): ap is types.PrivateActionPage {
  return (ap as types.PrivateActionPage).extraSupporters !== undefined
}

export function isPrivateCampaign(c : types.Campaign): c is types.PrivateCampaign {
  return (c as types.PrivateCampaign).id !== undefined
}

export function isPublicCampaign(c : types.Campaign): c is types.PublicCampaign {
  return (c as types.PublicCampaign).id === undefined
}


