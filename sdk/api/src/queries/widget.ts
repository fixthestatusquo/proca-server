import * as Types from '../apiTypes';

import { TypedDocumentNode as DocumentNode } from '@graphql-typed-document-node/core';
export const CampaignIds: DocumentNode<CampaignIds, unknown> = {"kind":"Document","definitions":[{"kind":"FragmentDefinition","name":{"kind":"Name","value":"campaignIds"},"typeCondition":{"kind":"NamedType","name":{"kind":"Name","value":"Campaign"}},"selectionSet":{"kind":"SelectionSet","selections":[{"kind":"Field","name":{"kind":"Name","value":"id"}},{"kind":"Field","name":{"kind":"Name","value":"externalId"}},{"kind":"Field","name":{"kind":"Name","value":"name"}},{"kind":"Field","name":{"kind":"Name","value":"title"}}]}}]};
export const CampaignExportIds: DocumentNode<CampaignExportIds, unknown> = {"kind":"Document","definitions":[{"kind":"FragmentDefinition","name":{"kind":"Name","value":"campaignExportIds"},"typeCondition":{"kind":"NamedType","name":{"kind":"Name","value":"Campaign"}},"selectionSet":{"kind":"SelectionSet","selections":[{"kind":"Field","name":{"kind":"Name","value":"name"}},{"kind":"Field","name":{"kind":"Name","value":"externalId"}}]}}]};
export const CampaignFields: DocumentNode<CampaignFields, unknown> = {"kind":"Document","definitions":[{"kind":"FragmentDefinition","name":{"kind":"Name","value":"campaignFields"},"typeCondition":{"kind":"NamedType","name":{"kind":"Name","value":"Campaign"}},"selectionSet":{"kind":"SelectionSet","selections":[{"kind":"Field","name":{"kind":"Name","value":"name"}},{"kind":"Field","name":{"kind":"Name","value":"title"}},{"kind":"Field","name":{"kind":"Name","value":"contactSchema"}},{"kind":"Field","name":{"kind":"Name","value":"config"}}]}}]};
export const CampaignPrivateFields: DocumentNode<CampaignPrivateFields, unknown> = {"kind":"Document","definitions":[{"kind":"FragmentDefinition","name":{"kind":"Name","value":"campaignPrivateFields"},"typeCondition":{"kind":"NamedType","name":{"kind":"Name","value":"PrivateCampaign"}},"selectionSet":{"kind":"SelectionSet","selections":[{"kind":"Field","name":{"kind":"Name","value":"id"}},{"kind":"Field","name":{"kind":"Name","value":"externalId"}},{"kind":"Field","name":{"kind":"Name","value":"forceDelivery"}}]}}]};
export const CampaignStats: DocumentNode<CampaignStats, unknown> = {"kind":"Document","definitions":[{"kind":"FragmentDefinition","name":{"kind":"Name","value":"campaignStats"},"typeCondition":{"kind":"NamedType","name":{"kind":"Name","value":"Campaign"}},"selectionSet":{"kind":"SelectionSet","selections":[{"kind":"Field","name":{"kind":"Name","value":"stats"},"selectionSet":{"kind":"SelectionSet","selections":[{"kind":"Field","name":{"kind":"Name","value":"supporterCount"}},{"kind":"Field","name":{"kind":"Name","value":"supporterCountByOrg"},"selectionSet":{"kind":"SelectionSet","selections":[{"kind":"Field","name":{"kind":"Name","value":"org"},"selectionSet":{"kind":"SelectionSet","selections":[{"kind":"Field","name":{"kind":"Name","value":"name"}},{"kind":"Field","name":{"kind":"Name","value":"title"}}]}},{"kind":"Field","name":{"kind":"Name","value":"count"}}]}},{"kind":"Field","name":{"kind":"Name","value":"actionCount"},"selectionSet":{"kind":"SelectionSet","selections":[{"kind":"Field","name":{"kind":"Name","value":"actionType"}},{"kind":"Field","name":{"kind":"Name","value":"count"}}]}}]}}]}}]};
export const OrgIds: DocumentNode<OrgIds, unknown> = {"kind":"Document","definitions":[{"kind":"FragmentDefinition","name":{"kind":"Name","value":"orgIds"},"typeCondition":{"kind":"NamedType","name":{"kind":"Name","value":"Org"}},"selectionSet":{"kind":"SelectionSet","selections":[{"kind":"Field","name":{"kind":"Name","value":"name"}},{"kind":"Field","name":{"kind":"Name","value":"title"}},{"kind":"InlineFragment","typeCondition":{"kind":"NamedType","name":{"kind":"Name","value":"PrivateOrg"}},"selectionSet":{"kind":"SelectionSet","selections":[{"kind":"Field","name":{"kind":"Name","value":"id"}}]}}]}}]};
export const ActionPageFields: DocumentNode<ActionPageFields, unknown> = {"kind":"Document","definitions":[{"kind":"FragmentDefinition","name":{"kind":"Name","value":"actionPageFields"},"typeCondition":{"kind":"NamedType","name":{"kind":"Name","value":"ActionPage"}},"selectionSet":{"kind":"SelectionSet","selections":[{"kind":"Field","name":{"kind":"Name","value":"id"}},{"kind":"Field","name":{"kind":"Name","value":"name"}},{"kind":"Field","name":{"kind":"Name","value":"locale"}},{"kind":"Field","name":{"kind":"Name","value":"config"}},{"kind":"Field","name":{"kind":"Name","value":"live"}},{"kind":"Field","name":{"kind":"Name","value":"journey"}},{"kind":"Field","name":{"kind":"Name","value":"thankYouTemplateRef"}}]}}]};
export const CampaignPartnerships: DocumentNode<CampaignPartnerships, unknown> = {"kind":"Document","definitions":[{"kind":"FragmentDefinition","name":{"kind":"Name","value":"campaignPartnerships"},"typeCondition":{"kind":"NamedType","name":{"kind":"Name","value":"PrivateCampaign"}},"selectionSet":{"kind":"SelectionSet","selections":[{"kind":"Field","name":{"kind":"Name","value":"partnerships"},"selectionSet":{"kind":"SelectionSet","selections":[{"kind":"Field","name":{"kind":"Name","value":"org"},"selectionSet":{"kind":"SelectionSet","selections":[{"kind":"FragmentSpread","name":{"kind":"Name","value":"orgIds"}}]}},{"kind":"Field","name":{"kind":"Name","value":"actionPages"},"selectionSet":{"kind":"SelectionSet","selections":[{"kind":"FragmentSpread","name":{"kind":"Name","value":"actionPageFields"}}]}},{"kind":"Field","name":{"kind":"Name","value":"launchRequests"},"selectionSet":{"kind":"SelectionSet","selections":[{"kind":"Field","name":{"kind":"Name","value":"code"}},{"kind":"Field","name":{"kind":"Name","value":"email"}},{"kind":"Field","name":{"kind":"Name","value":"objectId"}}]}}]}}]}},...OrgIds.definitions,...ActionPageFields.definitions]};
export const ActionPageIds: DocumentNode<ActionPageIds, unknown> = {"kind":"Document","definitions":[{"kind":"FragmentDefinition","name":{"kind":"Name","value":"actionPageIds"},"typeCondition":{"kind":"NamedType","name":{"kind":"Name","value":"ActionPage"}},"selectionSet":{"kind":"SelectionSet","selections":[{"kind":"Field","name":{"kind":"Name","value":"id"}},{"kind":"Field","name":{"kind":"Name","value":"name"}},{"kind":"Field","name":{"kind":"Name","value":"locale"}}]}}]};
export const ActionPagePrivateFields: DocumentNode<ActionPagePrivateFields, unknown> = {"kind":"Document","definitions":[{"kind":"FragmentDefinition","name":{"kind":"Name","value":"actionPagePrivateFields"},"typeCondition":{"kind":"NamedType","name":{"kind":"Name","value":"PrivateActionPage"}},"selectionSet":{"kind":"SelectionSet","selections":[{"kind":"Field","name":{"kind":"Name","value":"extraSupporters"}},{"kind":"Field","name":{"kind":"Name","value":"delivery"}}]}}]};
export const OrgFields: DocumentNode<OrgFields, unknown> = {"kind":"Document","definitions":[{"kind":"FragmentDefinition","name":{"kind":"Name","value":"orgFields"},"typeCondition":{"kind":"NamedType","name":{"kind":"Name","value":"Org"}},"selectionSet":{"kind":"SelectionSet","selections":[{"kind":"Field","name":{"kind":"Name","value":"name"}},{"kind":"Field","name":{"kind":"Name","value":"title"}}]}}]};
export const OrgPrivateFields: DocumentNode<OrgPrivateFields, unknown> = {"kind":"Document","definitions":[{"kind":"FragmentDefinition","name":{"kind":"Name","value":"orgPrivateFields"},"typeCondition":{"kind":"NamedType","name":{"kind":"Name","value":"PrivateOrg"}},"selectionSet":{"kind":"SelectionSet","selections":[{"kind":"Field","name":{"kind":"Name","value":"config"}},{"kind":"Field","name":{"kind":"Name","value":"personalData"},"selectionSet":{"kind":"SelectionSet","selections":[{"kind":"Field","name":{"kind":"Name","value":"contactSchema"}},{"kind":"Field","name":{"kind":"Name","value":"emailOptIn"}},{"kind":"Field","name":{"kind":"Name","value":"emailOptInTemplate"}}]}}]}}]};
export const KeyFields: DocumentNode<KeyFields, unknown> = {"kind":"Document","definitions":[{"kind":"FragmentDefinition","name":{"kind":"Name","value":"keyFields"},"typeCondition":{"kind":"NamedType","name":{"kind":"Name","value":"Key"}},"selectionSet":{"kind":"SelectionSet","selections":[{"kind":"Field","name":{"kind":"Name","value":"id"}},{"kind":"Field","name":{"kind":"Name","value":"name"}},{"kind":"Field","name":{"kind":"Name","value":"public"}},{"kind":"Field","name":{"kind":"Name","value":"active"}},{"kind":"Field","name":{"kind":"Name","value":"expired"}},{"kind":"Field","name":{"kind":"Name","value":"expiredAt"}}]}}]};
export const ServiceFields: DocumentNode<ServiceFields, unknown> = {"kind":"Document","definitions":[{"kind":"FragmentDefinition","name":{"kind":"Name","value":"serviceFields"},"typeCondition":{"kind":"NamedType","name":{"kind":"Name","value":"Service"}},"selectionSet":{"kind":"SelectionSet","selections":[{"kind":"Field","name":{"kind":"Name","value":"id"}},{"kind":"Field","name":{"kind":"Name","value":"name"}},{"kind":"Field","name":{"kind":"Name","value":"host"}},{"kind":"Field","name":{"kind":"Name","value":"user"}},{"kind":"Field","name":{"kind":"Name","value":"path"}}]}}]};
export const ContactExport: DocumentNode<ContactExport, unknown> = {"kind":"Document","definitions":[{"kind":"FragmentDefinition","name":{"kind":"Name","value":"contactExport"},"typeCondition":{"kind":"NamedType","name":{"kind":"Name","value":"Contact"}},"selectionSet":{"kind":"SelectionSet","selections":[{"kind":"Field","name":{"kind":"Name","value":"contactRef"}},{"kind":"Field","name":{"kind":"Name","value":"payload"}},{"kind":"Field","name":{"kind":"Name","value":"nonce"}},{"kind":"Field","name":{"kind":"Name","value":"publicKey"},"selectionSet":{"kind":"SelectionSet","selections":[{"kind":"Field","name":{"kind":"Name","value":"id"}},{"kind":"Field","name":{"kind":"Name","value":"public"}}]}},{"kind":"Field","name":{"kind":"Name","value":"signKey"},"selectionSet":{"kind":"SelectionSet","selections":[{"kind":"Field","name":{"kind":"Name","value":"id"}},{"kind":"Field","name":{"kind":"Name","value":"public"}}]}}]}}]};
export const ActionExport: DocumentNode<ActionExport, unknown> = {"kind":"Document","definitions":[{"kind":"FragmentDefinition","name":{"kind":"Name","value":"actionExport"},"typeCondition":{"kind":"NamedType","name":{"kind":"Name","value":"Action"}},"selectionSet":{"kind":"SelectionSet","selections":[{"kind":"Field","name":{"kind":"Name","value":"actionId"}},{"kind":"Field","name":{"kind":"Name","value":"actionType"}},{"kind":"Field","name":{"kind":"Name","value":"createdAt"}},{"kind":"Field","name":{"kind":"Name","value":"contact"},"selectionSet":{"kind":"SelectionSet","selections":[{"kind":"FragmentSpread","name":{"kind":"Name","value":"contactExport"}}]}},{"kind":"Field","name":{"kind":"Name","value":"fields"},"selectionSet":{"kind":"SelectionSet","selections":[{"kind":"Field","name":{"kind":"Name","value":"key"}},{"kind":"Field","name":{"kind":"Name","value":"value"}}]}},{"kind":"Field","name":{"kind":"Name","value":"tracking"},"selectionSet":{"kind":"SelectionSet","selections":[{"kind":"Field","name":{"kind":"Name","value":"source"}},{"kind":"Field","name":{"kind":"Name","value":"medium"}},{"kind":"Field","name":{"kind":"Name","value":"campaign"}},{"kind":"Field","name":{"kind":"Name","value":"content"}}]}},{"kind":"Field","name":{"kind":"Name","value":"privacy"},"selectionSet":{"kind":"SelectionSet","selections":[{"kind":"Field","name":{"kind":"Name","value":"optIn"}},{"kind":"Field","name":{"kind":"Name","value":"givenAt"}}]}}]}},...ContactExport.definitions]};
export const GetActionPageDocument: DocumentNode<GetActionPage, GetActionPageVariables> = {"kind":"Document","definitions":[{"kind":"OperationDefinition","operation":"query","name":{"kind":"Name","value":"GetActionPage"},"variableDefinitions":[{"kind":"VariableDefinition","variable":{"kind":"Variable","name":{"kind":"Name","value":"name"}},"type":{"kind":"NamedType","name":{"kind":"Name","value":"String"}}},{"kind":"VariableDefinition","variable":{"kind":"Variable","name":{"kind":"Name","value":"id"}},"type":{"kind":"NamedType","name":{"kind":"Name","value":"Int"}}}],"selectionSet":{"kind":"SelectionSet","selections":[{"kind":"Field","name":{"kind":"Name","value":"actionPage"},"arguments":[{"kind":"Argument","name":{"kind":"Name","value":"name"},"value":{"kind":"Variable","name":{"kind":"Name","value":"name"}}},{"kind":"Argument","name":{"kind":"Name","value":"id"},"value":{"kind":"Variable","name":{"kind":"Name","value":"id"}}}],"selectionSet":{"kind":"SelectionSet","selections":[{"kind":"FragmentSpread","name":{"kind":"Name","value":"actionPageFields"}},{"kind":"Field","name":{"kind":"Name","value":"org"},"selectionSet":{"kind":"SelectionSet","selections":[{"kind":"FragmentSpread","name":{"kind":"Name","value":"orgIds"}}]}},{"kind":"Field","name":{"kind":"Name","value":"campaign"},"selectionSet":{"kind":"SelectionSet","selections":[{"kind":"FragmentSpread","name":{"kind":"Name","value":"campaignFields"}},{"kind":"Field","name":{"kind":"Name","value":"id"}},{"kind":"Field","name":{"kind":"Name","value":"title"}},{"kind":"Field","name":{"kind":"Name","value":"name"}},{"kind":"Field","name":{"kind":"Name","value":"externalId"}},{"kind":"Field","name":{"kind":"Name","value":"stats"},"selectionSet":{"kind":"SelectionSet","selections":[{"kind":"Field","name":{"kind":"Name","value":"actionCount"},"selectionSet":{"kind":"SelectionSet","selections":[{"kind":"Field","name":{"kind":"Name","value":"actionType"}},{"kind":"Field","name":{"kind":"Name","value":"count"}}]}},{"kind":"Field","name":{"kind":"Name","value":"supporterCount"}}]}},{"kind":"Field","name":{"kind":"Name","value":"org"},"selectionSet":{"kind":"SelectionSet","selections":[{"kind":"Field","name":{"kind":"Name","value":"name"}},{"kind":"Field","name":{"kind":"Name","value":"title"}}]}}]}}]}}]}},...ActionPageFields.definitions,...OrgIds.definitions,...CampaignFields.definitions]};
export const GetStatsDocument: DocumentNode<GetStats, GetStatsVariables> = {"kind":"Document","definitions":[{"kind":"OperationDefinition","operation":"query","name":{"kind":"Name","value":"GetStats"},"variableDefinitions":[{"kind":"VariableDefinition","variable":{"kind":"Variable","name":{"kind":"Name","value":"name"}},"type":{"kind":"NamedType","name":{"kind":"Name","value":"String"}}},{"kind":"VariableDefinition","variable":{"kind":"Variable","name":{"kind":"Name","value":"id"}},"type":{"kind":"NamedType","name":{"kind":"Name","value":"Int"}}}],"selectionSet":{"kind":"SelectionSet","selections":[{"kind":"Field","name":{"kind":"Name","value":"actionPage"},"arguments":[{"kind":"Argument","name":{"kind":"Name","value":"id"},"value":{"kind":"Variable","name":{"kind":"Name","value":"id"}}},{"kind":"Argument","name":{"kind":"Name","value":"name"},"value":{"kind":"Variable","name":{"kind":"Name","value":"name"}}}],"selectionSet":{"kind":"SelectionSet","selections":[{"kind":"Field","name":{"kind":"Name","value":"campaign"},"selectionSet":{"kind":"SelectionSet","selections":[{"kind":"Field","name":{"kind":"Name","value":"stats"},"selectionSet":{"kind":"SelectionSet","selections":[{"kind":"Field","name":{"kind":"Name","value":"supporterCount"}},{"kind":"Field","name":{"kind":"Name","value":"actionCount"},"selectionSet":{"kind":"SelectionSet","selections":[{"kind":"Field","name":{"kind":"Name","value":"actionType"}},{"kind":"Field","name":{"kind":"Name","value":"count"}}]}}]}}]}}]}}]}}]};
export const GetPublicResultDocument: DocumentNode<GetPublicResult, GetPublicResultVariables> = {"kind":"Document","definitions":[{"kind":"OperationDefinition","operation":"query","name":{"kind":"Name","value":"GetPublicResult"},"variableDefinitions":[{"kind":"VariableDefinition","variable":{"kind":"Variable","name":{"kind":"Name","value":"name"}},"type":{"kind":"NamedType","name":{"kind":"Name","value":"String"}}},{"kind":"VariableDefinition","variable":{"kind":"Variable","name":{"kind":"Name","value":"id"}},"type":{"kind":"NamedType","name":{"kind":"Name","value":"Int"}}},{"kind":"VariableDefinition","variable":{"kind":"Variable","name":{"kind":"Name","value":"actionType"}},"type":{"kind":"NonNullType","type":{"kind":"NamedType","name":{"kind":"Name","value":"String"}}}},{"kind":"VariableDefinition","variable":{"kind":"Variable","name":{"kind":"Name","value":"limit"}},"type":{"kind":"NonNullType","type":{"kind":"NamedType","name":{"kind":"Name","value":"Int"}}}}],"selectionSet":{"kind":"SelectionSet","selections":[{"kind":"Field","name":{"kind":"Name","value":"actionPage"},"arguments":[{"kind":"Argument","name":{"kind":"Name","value":"name"},"value":{"kind":"Variable","name":{"kind":"Name","value":"name"}}},{"kind":"Argument","name":{"kind":"Name","value":"id"},"value":{"kind":"Variable","name":{"kind":"Name","value":"id"}}}],"selectionSet":{"kind":"SelectionSet","selections":[{"kind":"Field","name":{"kind":"Name","value":"config"}},{"kind":"Field","name":{"kind":"Name","value":"locale"}},{"kind":"Field","name":{"kind":"Name","value":"journey"}},{"kind":"Field","name":{"kind":"Name","value":"name"}},{"kind":"Field","name":{"kind":"Name","value":"campaign"},"selectionSet":{"kind":"SelectionSet","selections":[{"kind":"Field","name":{"kind":"Name","value":"title"}},{"kind":"Field","name":{"kind":"Name","value":"name"}},{"kind":"Field","name":{"kind":"Name","value":"externalId"}},{"kind":"Field","name":{"kind":"Name","value":"stats"},"selectionSet":{"kind":"SelectionSet","selections":[{"kind":"Field","name":{"kind":"Name","value":"actionCount"},"selectionSet":{"kind":"SelectionSet","selections":[{"kind":"Field","name":{"kind":"Name","value":"actionType"}},{"kind":"Field","name":{"kind":"Name","value":"count"}}]}},{"kind":"Field","name":{"kind":"Name","value":"supporterCount"}}]}},{"kind":"Field","name":{"kind":"Name","value":"actions"},"arguments":[{"kind":"Argument","name":{"kind":"Name","value":"actionType"},"value":{"kind":"Variable","name":{"kind":"Name","value":"actionType"}}},{"kind":"Argument","name":{"kind":"Name","value":"limit"},"value":{"kind":"Variable","name":{"kind":"Name","value":"limit"}}}],"selectionSet":{"kind":"SelectionSet","selections":[{"kind":"Field","name":{"kind":"Name","value":"fieldKeys"}},{"kind":"Field","name":{"kind":"Name","value":"list"},"selectionSet":{"kind":"SelectionSet","selections":[{"kind":"Field","name":{"kind":"Name","value":"actionType"}},{"kind":"Field","name":{"kind":"Name","value":"insertedAt"}},{"kind":"Field","name":{"kind":"Name","value":"fields"},"selectionSet":{"kind":"SelectionSet","selections":[{"kind":"Field","name":{"kind":"Name","value":"key"}},{"kind":"Field","name":{"kind":"Name","value":"value"}}]}}]}}]}},{"kind":"Field","name":{"kind":"Name","value":"org"},"selectionSet":{"kind":"SelectionSet","selections":[{"kind":"Field","name":{"kind":"Name","value":"title"}}]}}]}}]}}]}}]};
export const AddActionContactDocument: DocumentNode<AddActionContact, AddActionContactVariables> = {"kind":"Document","definitions":[{"kind":"OperationDefinition","operation":"mutation","name":{"kind":"Name","value":"AddActionContact"},"variableDefinitions":[{"kind":"VariableDefinition","variable":{"kind":"Variable","name":{"kind":"Name","value":"id"}},"type":{"kind":"NonNullType","type":{"kind":"NamedType","name":{"kind":"Name","value":"Int"}}}},{"kind":"VariableDefinition","variable":{"kind":"Variable","name":{"kind":"Name","value":"contact"}},"type":{"kind":"NonNullType","type":{"kind":"NamedType","name":{"kind":"Name","value":"ContactInput"}}}},{"kind":"VariableDefinition","variable":{"kind":"Variable","name":{"kind":"Name","value":"contactRef"}},"type":{"kind":"NamedType","name":{"kind":"Name","value":"ID"}}},{"kind":"VariableDefinition","variable":{"kind":"Variable","name":{"kind":"Name","value":"actionType"}},"type":{"kind":"NonNullType","type":{"kind":"NamedType","name":{"kind":"Name","value":"String"}}}},{"kind":"VariableDefinition","variable":{"kind":"Variable","name":{"kind":"Name","value":"fields"}},"type":{"kind":"ListType","type":{"kind":"NonNullType","type":{"kind":"NamedType","name":{"kind":"Name","value":"CustomFieldInput"}}}}},{"kind":"VariableDefinition","variable":{"kind":"Variable","name":{"kind":"Name","value":"privacy"}},"type":{"kind":"NonNullType","type":{"kind":"NamedType","name":{"kind":"Name","value":"ConsentInput"}}}},{"kind":"VariableDefinition","variable":{"kind":"Variable","name":{"kind":"Name","value":"tracking"}},"type":{"kind":"NamedType","name":{"kind":"Name","value":"TrackingInput"}}}],"selectionSet":{"kind":"SelectionSet","selections":[{"kind":"Field","name":{"kind":"Name","value":"addActionContact"},"arguments":[{"kind":"Argument","name":{"kind":"Name","value":"actionPageId"},"value":{"kind":"Variable","name":{"kind":"Name","value":"id"}}},{"kind":"Argument","name":{"kind":"Name","value":"contact"},"value":{"kind":"Variable","name":{"kind":"Name","value":"contact"}}},{"kind":"Argument","name":{"kind":"Name","value":"contactRef"},"value":{"kind":"Variable","name":{"kind":"Name","value":"contactRef"}}},{"kind":"Argument","name":{"kind":"Name","value":"action"},"value":{"kind":"ObjectValue","fields":[{"kind":"ObjectField","name":{"kind":"Name","value":"actionType"},"value":{"kind":"Variable","name":{"kind":"Name","value":"actionType"}}},{"kind":"ObjectField","name":{"kind":"Name","value":"fields"},"value":{"kind":"Variable","name":{"kind":"Name","value":"fields"}}}]}},{"kind":"Argument","name":{"kind":"Name","value":"privacy"},"value":{"kind":"Variable","name":{"kind":"Name","value":"privacy"}}},{"kind":"Argument","name":{"kind":"Name","value":"tracking"},"value":{"kind":"Variable","name":{"kind":"Name","value":"tracking"}}}],"selectionSet":{"kind":"SelectionSet","selections":[{"kind":"Field","name":{"kind":"Name","value":"contactRef"}},{"kind":"Field","name":{"kind":"Name","value":"firstName"}}]}}]}}]};
export const AddActionDocument: DocumentNode<AddAction, AddActionVariables> = {"kind":"Document","definitions":[{"kind":"OperationDefinition","operation":"mutation","name":{"kind":"Name","value":"AddAction"},"variableDefinitions":[{"kind":"VariableDefinition","variable":{"kind":"Variable","name":{"kind":"Name","value":"id"}},"type":{"kind":"NonNullType","type":{"kind":"NamedType","name":{"kind":"Name","value":"Int"}}}},{"kind":"VariableDefinition","variable":{"kind":"Variable","name":{"kind":"Name","value":"contactRef"}},"type":{"kind":"NonNullType","type":{"kind":"NamedType","name":{"kind":"Name","value":"ID"}}}},{"kind":"VariableDefinition","variable":{"kind":"Variable","name":{"kind":"Name","value":"actionType"}},"type":{"kind":"NonNullType","type":{"kind":"NamedType","name":{"kind":"Name","value":"String"}}}},{"kind":"VariableDefinition","variable":{"kind":"Variable","name":{"kind":"Name","value":"fields"}},"type":{"kind":"ListType","type":{"kind":"NonNullType","type":{"kind":"NamedType","name":{"kind":"Name","value":"CustomFieldInput"}}}}},{"kind":"VariableDefinition","variable":{"kind":"Variable","name":{"kind":"Name","value":"tracking"}},"type":{"kind":"NamedType","name":{"kind":"Name","value":"TrackingInput"}}}],"selectionSet":{"kind":"SelectionSet","selections":[{"kind":"Field","name":{"kind":"Name","value":"addAction"},"arguments":[{"kind":"Argument","name":{"kind":"Name","value":"actionPageId"},"value":{"kind":"Variable","name":{"kind":"Name","value":"id"}}},{"kind":"Argument","name":{"kind":"Name","value":"contactRef"},"value":{"kind":"Variable","name":{"kind":"Name","value":"contactRef"}}},{"kind":"Argument","name":{"kind":"Name","value":"action"},"value":{"kind":"ObjectValue","fields":[{"kind":"ObjectField","name":{"kind":"Name","value":"actionType"},"value":{"kind":"Variable","name":{"kind":"Name","value":"actionType"}}},{"kind":"ObjectField","name":{"kind":"Name","value":"fields"},"value":{"kind":"Variable","name":{"kind":"Name","value":"fields"}}}]}},{"kind":"Argument","name":{"kind":"Name","value":"tracking"},"value":{"kind":"Variable","name":{"kind":"Name","value":"tracking"}}}],"selectionSet":{"kind":"SelectionSet","selections":[{"kind":"Field","name":{"kind":"Name","value":"contactRef"}},{"kind":"Field","name":{"kind":"Name","value":"firstName"}}]}}]}}]};
type OrgIds_PublicOrg_ = Pick<Types.PublicOrg, 'name' | 'title'>;

type OrgIds_PrivateOrg_ = Pick<Types.PrivateOrg, 'id' | 'name' | 'title'>;

export type OrgIds = OrgIds_PublicOrg_ | OrgIds_PrivateOrg_;

type CampaignIds_PublicCampaign_ = Pick<Types.PublicCampaign, 'id' | 'externalId' | 'name' | 'title'>;

type CampaignIds_PrivateCampaign_ = Pick<Types.PrivateCampaign, 'id' | 'externalId' | 'name' | 'title'>;

export type CampaignIds = CampaignIds_PublicCampaign_ | CampaignIds_PrivateCampaign_;

type CampaignExportIds_PublicCampaign_ = Pick<Types.PublicCampaign, 'name' | 'externalId'>;

type CampaignExportIds_PrivateCampaign_ = Pick<Types.PrivateCampaign, 'name' | 'externalId'>;

export type CampaignExportIds = CampaignExportIds_PublicCampaign_ | CampaignExportIds_PrivateCampaign_;

type CampaignFields_PublicCampaign_ = Pick<Types.PublicCampaign, 'name' | 'title' | 'contactSchema' | 'config'>;

type CampaignFields_PrivateCampaign_ = Pick<Types.PrivateCampaign, 'name' | 'title' | 'contactSchema' | 'config'>;

export type CampaignFields = CampaignFields_PublicCampaign_ | CampaignFields_PrivateCampaign_;

export type CampaignPrivateFields = Pick<Types.PrivateCampaign, 'id' | 'externalId' | 'forceDelivery'>;

type CampaignStats_PublicCampaign_ = { stats: (
    Pick<Types.CampaignStats, 'supporterCount'>
    & { supporterCountByOrg: Array<(
      Pick<Types.OrgCount, 'count'>
      & { org: Pick<Types.PublicOrg, 'name' | 'title'> | Pick<Types.PrivateOrg, 'name' | 'title'> }
    )>, actionCount: Array<Pick<Types.ActionTypeCount, 'actionType' | 'count'>> }
  ) };

type CampaignStats_PrivateCampaign_ = { stats: (
    Pick<Types.CampaignStats, 'supporterCount'>
    & { supporterCountByOrg: Array<(
      Pick<Types.OrgCount, 'count'>
      & { org: Pick<Types.PublicOrg, 'name' | 'title'> | Pick<Types.PrivateOrg, 'name' | 'title'> }
    )>, actionCount: Array<Pick<Types.ActionTypeCount, 'actionType' | 'count'>> }
  ) };

export type CampaignStats = CampaignStats_PublicCampaign_ | CampaignStats_PrivateCampaign_;

export type CampaignPartnerships = { partnerships: Types.Maybe<Array<{ org: OrgIds_PublicOrg_ | OrgIds_PrivateOrg_, actionPages: Array<ActionPageFields_PrivateActionPage_ | ActionPageFields_PublicActionPage_>, launchRequests: Array<Pick<Types.Confirm, 'code' | 'email' | 'objectId'>> }>> };

type ActionPageIds_PrivateActionPage_ = Pick<Types.PrivateActionPage, 'id' | 'name' | 'locale'>;

type ActionPageIds_PublicActionPage_ = Pick<Types.PublicActionPage, 'id' | 'name' | 'locale'>;

export type ActionPageIds = ActionPageIds_PrivateActionPage_ | ActionPageIds_PublicActionPage_;

type ActionPageFields_PrivateActionPage_ = Pick<Types.PrivateActionPage, 'id' | 'name' | 'locale' | 'config' | 'live' | 'journey' | 'thankYouTemplateRef'>;

type ActionPageFields_PublicActionPage_ = Pick<Types.PublicActionPage, 'id' | 'name' | 'locale' | 'config' | 'live' | 'journey' | 'thankYouTemplateRef'>;

export type ActionPageFields = ActionPageFields_PrivateActionPage_ | ActionPageFields_PublicActionPage_;

export type ActionPagePrivateFields = Pick<Types.PrivateActionPage, 'extraSupporters' | 'delivery'>;

type OrgFields_PublicOrg_ = Pick<Types.PublicOrg, 'name' | 'title'>;

type OrgFields_PrivateOrg_ = Pick<Types.PrivateOrg, 'name' | 'title'>;

export type OrgFields = OrgFields_PublicOrg_ | OrgFields_PrivateOrg_;

export type OrgPrivateFields = (
  Pick<Types.PrivateOrg, 'config'>
  & { personalData: Pick<Types.PersonalData, 'contactSchema' | 'emailOptIn' | 'emailOptInTemplate'> }
);

export type KeyFields = Pick<Types.Key, 'id' | 'name' | 'public' | 'active' | 'expired' | 'expiredAt'>;

export type ServiceFields = Pick<Types.Service, 'id' | 'name' | 'host' | 'user' | 'path'>;

export type ContactExport = (
  Pick<Types.Contact, 'contactRef' | 'payload' | 'nonce'>
  & { publicKey: Types.Maybe<Pick<Types.KeyIds, 'id' | 'public'>>, signKey: Types.Maybe<Pick<Types.KeyIds, 'id' | 'public'>> }
);

export type ActionExport = (
  Pick<Types.Action, 'actionId' | 'actionType' | 'createdAt'>
  & { contact: ContactExport, fields: Array<Pick<Types.CustomField, 'key' | 'value'>>, tracking: Types.Maybe<Pick<Types.Tracking, 'source' | 'medium' | 'campaign' | 'content'>>, privacy: Pick<Types.Consent, 'optIn' | 'givenAt'> }
);

export type GetActionPageVariables = Types.Exact<{
  name?: Types.Maybe<Types.Scalars['String']>;
  id?: Types.Maybe<Types.Scalars['Int']>;
}>;


export type GetActionPage = { actionPage: (
    { org: OrgIds_PublicOrg_ | OrgIds_PrivateOrg_, campaign: (
      Pick<Types.PublicCampaign, 'id' | 'title' | 'name' | 'externalId'>
      & { stats: (
        Pick<Types.CampaignStats, 'supporterCount'>
        & { actionCount: Array<Pick<Types.ActionTypeCount, 'actionType' | 'count'>> }
      ), org: Pick<Types.PublicOrg, 'name' | 'title'> | Pick<Types.PrivateOrg, 'name' | 'title'> }
      & CampaignFields_PublicCampaign_
    ) | (
      Pick<Types.PrivateCampaign, 'id' | 'title' | 'name' | 'externalId'>
      & { stats: (
        Pick<Types.CampaignStats, 'supporterCount'>
        & { actionCount: Array<Pick<Types.ActionTypeCount, 'actionType' | 'count'>> }
      ), org: Pick<Types.PublicOrg, 'name' | 'title'> | Pick<Types.PrivateOrg, 'name' | 'title'> }
      & CampaignFields_PrivateCampaign_
    ) }
    & ActionPageFields_PrivateActionPage_
  ) | (
    { org: OrgIds_PublicOrg_ | OrgIds_PrivateOrg_, campaign: (
      Pick<Types.PublicCampaign, 'id' | 'title' | 'name' | 'externalId'>
      & { stats: (
        Pick<Types.CampaignStats, 'supporterCount'>
        & { actionCount: Array<Pick<Types.ActionTypeCount, 'actionType' | 'count'>> }
      ), org: Pick<Types.PublicOrg, 'name' | 'title'> | Pick<Types.PrivateOrg, 'name' | 'title'> }
      & CampaignFields_PublicCampaign_
    ) | (
      Pick<Types.PrivateCampaign, 'id' | 'title' | 'name' | 'externalId'>
      & { stats: (
        Pick<Types.CampaignStats, 'supporterCount'>
        & { actionCount: Array<Pick<Types.ActionTypeCount, 'actionType' | 'count'>> }
      ), org: Pick<Types.PublicOrg, 'name' | 'title'> | Pick<Types.PrivateOrg, 'name' | 'title'> }
      & CampaignFields_PrivateCampaign_
    ) }
    & ActionPageFields_PublicActionPage_
  ) };

export type GetStatsVariables = Types.Exact<{
  name?: Types.Maybe<Types.Scalars['String']>;
  id?: Types.Maybe<Types.Scalars['Int']>;
}>;


export type GetStats = { actionPage: { campaign: { stats: (
        Pick<Types.CampaignStats, 'supporterCount'>
        & { actionCount: Array<Pick<Types.ActionTypeCount, 'actionType' | 'count'>> }
      ) } | { stats: (
        Pick<Types.CampaignStats, 'supporterCount'>
        & { actionCount: Array<Pick<Types.ActionTypeCount, 'actionType' | 'count'>> }
      ) } } | { campaign: { stats: (
        Pick<Types.CampaignStats, 'supporterCount'>
        & { actionCount: Array<Pick<Types.ActionTypeCount, 'actionType' | 'count'>> }
      ) } | { stats: (
        Pick<Types.CampaignStats, 'supporterCount'>
        & { actionCount: Array<Pick<Types.ActionTypeCount, 'actionType' | 'count'>> }
      ) } } };

export type GetPublicResultVariables = Types.Exact<{
  name?: Types.Maybe<Types.Scalars['String']>;
  id?: Types.Maybe<Types.Scalars['Int']>;
  actionType: Types.Scalars['String'];
  limit: Types.Scalars['Int'];
}>;


export type GetPublicResult = { actionPage: (
    Pick<Types.PrivateActionPage, 'config' | 'locale' | 'journey' | 'name'>
    & { campaign: (
      Pick<Types.PublicCampaign, 'title' | 'name' | 'externalId'>
      & { stats: (
        Pick<Types.CampaignStats, 'supporterCount'>
        & { actionCount: Array<Pick<Types.ActionTypeCount, 'actionType' | 'count'>> }
      ), actions: (
        Pick<Types.PublicActionsResult, 'fieldKeys'>
        & { list: Types.Maybe<Array<Types.Maybe<(
          Pick<Types.ActionCustomFields, 'actionType' | 'insertedAt'>
          & { fields: Array<Pick<Types.CustomField, 'key' | 'value'>> }
        )>>> }
      ), org: Pick<Types.PublicOrg, 'title'> | Pick<Types.PrivateOrg, 'title'> }
    ) | (
      Pick<Types.PrivateCampaign, 'title' | 'name' | 'externalId'>
      & { stats: (
        Pick<Types.CampaignStats, 'supporterCount'>
        & { actionCount: Array<Pick<Types.ActionTypeCount, 'actionType' | 'count'>> }
      ), actions: (
        Pick<Types.PublicActionsResult, 'fieldKeys'>
        & { list: Types.Maybe<Array<Types.Maybe<(
          Pick<Types.ActionCustomFields, 'actionType' | 'insertedAt'>
          & { fields: Array<Pick<Types.CustomField, 'key' | 'value'>> }
        )>>> }
      ), org: Pick<Types.PublicOrg, 'title'> | Pick<Types.PrivateOrg, 'title'> }
    ) }
  ) | (
    Pick<Types.PublicActionPage, 'config' | 'locale' | 'journey' | 'name'>
    & { campaign: (
      Pick<Types.PublicCampaign, 'title' | 'name' | 'externalId'>
      & { stats: (
        Pick<Types.CampaignStats, 'supporterCount'>
        & { actionCount: Array<Pick<Types.ActionTypeCount, 'actionType' | 'count'>> }
      ), actions: (
        Pick<Types.PublicActionsResult, 'fieldKeys'>
        & { list: Types.Maybe<Array<Types.Maybe<(
          Pick<Types.ActionCustomFields, 'actionType' | 'insertedAt'>
          & { fields: Array<Pick<Types.CustomField, 'key' | 'value'>> }
        )>>> }
      ), org: Pick<Types.PublicOrg, 'title'> | Pick<Types.PrivateOrg, 'title'> }
    ) | (
      Pick<Types.PrivateCampaign, 'title' | 'name' | 'externalId'>
      & { stats: (
        Pick<Types.CampaignStats, 'supporterCount'>
        & { actionCount: Array<Pick<Types.ActionTypeCount, 'actionType' | 'count'>> }
      ), actions: (
        Pick<Types.PublicActionsResult, 'fieldKeys'>
        & { list: Types.Maybe<Array<Types.Maybe<(
          Pick<Types.ActionCustomFields, 'actionType' | 'insertedAt'>
          & { fields: Array<Pick<Types.CustomField, 'key' | 'value'>> }
        )>>> }
      ), org: Pick<Types.PublicOrg, 'title'> | Pick<Types.PrivateOrg, 'title'> }
    ) }
  ) };

export type AddActionContactVariables = Types.Exact<{
  id: Types.Scalars['Int'];
  contact: Types.ContactInput;
  contactRef?: Types.Maybe<Types.Scalars['ID']>;
  actionType: Types.Scalars['String'];
  fields?: Types.Maybe<Array<Types.CustomFieldInput>>;
  privacy: Types.ConsentInput;
  tracking?: Types.Maybe<Types.TrackingInput>;
}>;


export type AddActionContact = { addActionContact: Pick<Types.ContactReference, 'contactRef' | 'firstName'> };

export type AddActionVariables = Types.Exact<{
  id: Types.Scalars['Int'];
  contactRef: Types.Scalars['ID'];
  actionType: Types.Scalars['String'];
  fields?: Types.Maybe<Array<Types.CustomFieldInput>>;
  tracking?: Types.Maybe<Types.TrackingInput>;
}>;


export type AddAction = { addAction: Pick<Types.ContactReference, 'contactRef' | 'firstName'> };
