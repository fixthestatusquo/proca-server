export * from './apiTypes'
import * as types from './apiTypes'


// The types exported from GraphQL have relations included.
// The *Record types contain only record fields, not relations
export type ActionPageRecord = Omit<types.ActionPage, 'org' | 'campaign'>;
export type CampaignRecord = Omit<types.Campaign, 'org' | 'stats' | 'actions' | 'partnerships'>;
// campaign record with owning org relation, useful because campaigns are visible to all orgs
export type CampaignOrg = Omit<types.Campaign, 'stats' | 'actions' | 'partnerships'>;
export type OrgRecord = Omit<types.Org, 'services' | 'key' | 'keys' | 'campaign' | 'campaigns' | 'actionPages' | 'actionPage' | 'users'>;

export type PartnershipRecord = {
  org: types.PublicOrg;
  actionPages: Array<ActionPageRecord>;
  launchRequests: Array<types.Confirm>;
};

