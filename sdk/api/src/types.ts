export * from './apiTypes'
import * as types from './apiTypes'


// The types exported from GraphQL have relations included.
// The *Record types contain only record fields, not relations
export type ActionPageRecord = Omit<types.ActionPage, 'org' | 'campaign'>;
export type CampaignRecord = Omit<types.Campaign, 'org' | 'stats' | 'actions' | 'partnerships'>;
// campaign record with owning org relation, useful because campaigns are visible to all orgs
export type CampaignOrg = Omit<types.Campaign, 'stats' | 'actions' | 'partnerships'>;
export type OrgRecord = Omit<types.Org, 'services' | 'key' | 'keys' | 'campaign' | 'campaigns' | 'actionPages' | 'actionPage' | 'users'>;

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

export type PartnershipRecord = {
  org: types.PublicOrg;
  actionPages: Array<ActionPageRecord>;
  launchRequests: Array<types.Confirm>;
};

