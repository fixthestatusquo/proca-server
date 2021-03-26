export * from './apiTypes'
import * as types from './apiTypes'


// The types exported from GraphQL have relations included.
// The *Record types contain only record fields, not relations
export type ActionPageRecord = Omit<types.ActionPage, 'org' | 'campaign' | "config"> & {config: any};
export type CampaignRecord = Omit<types.Campaign, 'org' | 'stats' | 'actions' | "config"> & {config: any};
export type OrgRecord = Omit<types.Org, 'key' | 'keys' | 'campaign' | 'campaigns' | 'actionPages' | 'actionPage' | 'config'> & { config: any};
export type CampaignIds = types.ActionCampaign;


