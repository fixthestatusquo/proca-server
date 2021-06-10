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
export const ListCampaignsDocument: DocumentNode<ListCampaigns, ListCampaignsVariables> = {"kind":"Document","definitions":[{"kind":"OperationDefinition","operation":"query","name":{"kind":"Name","value":"ListCampaigns"},"variableDefinitions":[{"kind":"VariableDefinition","variable":{"kind":"Variable","name":{"kind":"Name","value":"org"}},"type":{"kind":"NonNullType","type":{"kind":"NamedType","name":{"kind":"Name","value":"String"}}}}],"selectionSet":{"kind":"SelectionSet","selections":[{"kind":"Field","name":{"kind":"Name","value":"org"},"arguments":[{"kind":"Argument","name":{"kind":"Name","value":"name"},"value":{"kind":"Variable","name":{"kind":"Name","value":"org"}}}],"selectionSet":{"kind":"SelectionSet","selections":[{"kind":"Field","name":{"kind":"Name","value":"campaigns"},"selectionSet":{"kind":"SelectionSet","selections":[{"kind":"FragmentSpread","name":{"kind":"Name","value":"campaignFields"}},{"kind":"FragmentSpread","name":{"kind":"Name","value":"campaignPrivateFields"}},{"kind":"Field","name":{"kind":"Name","value":"org"},"selectionSet":{"kind":"SelectionSet","selections":[{"kind":"FragmentSpread","name":{"kind":"Name","value":"orgIds"}}]}}]}}]}}]}},...CampaignFields.definitions,...CampaignPrivateFields.definitions,...OrgIds.definitions]};
export const ListActionPagesDocument: DocumentNode<ListActionPages, ListActionPagesVariables> = {"kind":"Document","definitions":[{"kind":"OperationDefinition","operation":"query","name":{"kind":"Name","value":"ListActionPages"},"variableDefinitions":[{"kind":"VariableDefinition","variable":{"kind":"Variable","name":{"kind":"Name","value":"org"}},"type":{"kind":"NonNullType","type":{"kind":"NamedType","name":{"kind":"Name","value":"String"}}}}],"selectionSet":{"kind":"SelectionSet","selections":[{"kind":"Field","name":{"kind":"Name","value":"org"},"arguments":[{"kind":"Argument","name":{"kind":"Name","value":"name"},"value":{"kind":"Variable","name":{"kind":"Name","value":"org"}}}],"selectionSet":{"kind":"SelectionSet","selections":[{"kind":"Field","name":{"kind":"Name","value":"actionPages"},"selectionSet":{"kind":"SelectionSet","selections":[{"kind":"FragmentSpread","name":{"kind":"Name","value":"actionPageFields"}},{"kind":"FragmentSpread","name":{"kind":"Name","value":"actionPagePrivateFields"}},{"kind":"Field","name":{"kind":"Name","value":"campaign"},"selectionSet":{"kind":"SelectionSet","selections":[{"kind":"FragmentSpread","name":{"kind":"Name","value":"campaignIds"}}]}}]}}]}}]}},...ActionPageFields.definitions,...ActionPagePrivateFields.definitions,...CampaignIds.definitions]};
export const GetCampaignDocument: DocumentNode<GetCampaign, GetCampaignVariables> = {"kind":"Document","definitions":[{"kind":"OperationDefinition","operation":"query","name":{"kind":"Name","value":"GetCampaign"},"variableDefinitions":[{"kind":"VariableDefinition","variable":{"kind":"Variable","name":{"kind":"Name","value":"org"}},"type":{"kind":"NonNullType","type":{"kind":"NamedType","name":{"kind":"Name","value":"String"}}}},{"kind":"VariableDefinition","variable":{"kind":"Variable","name":{"kind":"Name","value":"id"}},"type":{"kind":"NonNullType","type":{"kind":"NamedType","name":{"kind":"Name","value":"Int"}}}}],"selectionSet":{"kind":"SelectionSet","selections":[{"kind":"Field","name":{"kind":"Name","value":"org"},"arguments":[{"kind":"Argument","name":{"kind":"Name","value":"name"},"value":{"kind":"Variable","name":{"kind":"Name","value":"org"}}}],"selectionSet":{"kind":"SelectionSet","selections":[{"kind":"Field","name":{"kind":"Name","value":"campaign"},"arguments":[{"kind":"Argument","name":{"kind":"Name","value":"id"},"value":{"kind":"Variable","name":{"kind":"Name","value":"id"}}}],"selectionSet":{"kind":"SelectionSet","selections":[{"kind":"FragmentSpread","name":{"kind":"Name","value":"campaignFields"}},{"kind":"FragmentSpread","name":{"kind":"Name","value":"campaignPrivateFields"}},{"kind":"FragmentSpread","name":{"kind":"Name","value":"campaignStats"}},{"kind":"Field","name":{"kind":"Name","value":"org"},"selectionSet":{"kind":"SelectionSet","selections":[{"kind":"FragmentSpread","name":{"kind":"Name","value":"orgIds"}}]}},{"kind":"FragmentSpread","name":{"kind":"Name","value":"campaignPartnerships"}}]}}]}}]}},...CampaignFields.definitions,...CampaignPrivateFields.definitions,...CampaignStats.definitions,...OrgIds.definitions,...CampaignPartnerships.definitions]};
export const FindPublicCampaignDocument: DocumentNode<FindPublicCampaign, FindPublicCampaignVariables> = {"kind":"Document","definitions":[{"kind":"OperationDefinition","operation":"query","name":{"kind":"Name","value":"FindPublicCampaign"},"variableDefinitions":[{"kind":"VariableDefinition","variable":{"kind":"Variable","name":{"kind":"Name","value":"name"}},"type":{"kind":"NamedType","name":{"kind":"Name","value":"String"}}},{"kind":"VariableDefinition","variable":{"kind":"Variable","name":{"kind":"Name","value":"title"}},"type":{"kind":"NamedType","name":{"kind":"Name","value":"String"}}}],"selectionSet":{"kind":"SelectionSet","selections":[{"kind":"Field","name":{"kind":"Name","value":"campaigns"},"arguments":[{"kind":"Argument","name":{"kind":"Name","value":"title"},"value":{"kind":"Variable","name":{"kind":"Name","value":"title"}}},{"kind":"Argument","name":{"kind":"Name","value":"name"},"value":{"kind":"Variable","name":{"kind":"Name","value":"name"}}}],"selectionSet":{"kind":"SelectionSet","selections":[{"kind":"FragmentSpread","name":{"kind":"Name","value":"campaignFields"}},{"kind":"Field","name":{"kind":"Name","value":"org"},"selectionSet":{"kind":"SelectionSet","selections":[{"kind":"FragmentSpread","name":{"kind":"Name","value":"orgIds"}}]}}]}}]}},...CampaignFields.definitions,...OrgIds.definitions]};
export const GetActionPageDocument: DocumentNode<GetActionPage, GetActionPageVariables> = {"kind":"Document","definitions":[{"kind":"OperationDefinition","operation":"query","name":{"kind":"Name","value":"GetActionPage"},"variableDefinitions":[{"kind":"VariableDefinition","variable":{"kind":"Variable","name":{"kind":"Name","value":"org"}},"type":{"kind":"NonNullType","type":{"kind":"NamedType","name":{"kind":"Name","value":"String"}}}},{"kind":"VariableDefinition","variable":{"kind":"Variable","name":{"kind":"Name","value":"id"}},"type":{"kind":"NamedType","name":{"kind":"Name","value":"Int"}}},{"kind":"VariableDefinition","variable":{"kind":"Variable","name":{"kind":"Name","value":"name"}},"type":{"kind":"NamedType","name":{"kind":"Name","value":"String"}}}],"selectionSet":{"kind":"SelectionSet","selections":[{"kind":"Field","name":{"kind":"Name","value":"org"},"arguments":[{"kind":"Argument","name":{"kind":"Name","value":"name"},"value":{"kind":"Variable","name":{"kind":"Name","value":"org"}}}],"selectionSet":{"kind":"SelectionSet","selections":[{"kind":"Field","name":{"kind":"Name","value":"name"}},{"kind":"Field","name":{"kind":"Name","value":"title"}},{"kind":"Field","name":{"kind":"Name","value":"actionPage"},"arguments":[{"kind":"Argument","name":{"kind":"Name","value":"id"},"value":{"kind":"Variable","name":{"kind":"Name","value":"id"}}},{"kind":"Argument","name":{"kind":"Name","value":"name"},"value":{"kind":"Variable","name":{"kind":"Name","value":"name"}}}],"selectionSet":{"kind":"SelectionSet","selections":[{"kind":"FragmentSpread","name":{"kind":"Name","value":"actionPageFields"}},{"kind":"FragmentSpread","name":{"kind":"Name","value":"actionPagePrivateFields"}},{"kind":"Field","name":{"kind":"Name","value":"campaign"},"selectionSet":{"kind":"SelectionSet","selections":[{"kind":"FragmentSpread","name":{"kind":"Name","value":"campaignFields"}},{"kind":"FragmentSpread","name":{"kind":"Name","value":"campaignPrivateFields"}}]}}]}}]}}]}},...ActionPageFields.definitions,...ActionPagePrivateFields.definitions,...CampaignFields.definitions,...CampaignPrivateFields.definitions]};
export const ListActionPagesByCampaignDocument: DocumentNode<ListActionPagesByCampaign, ListActionPagesByCampaignVariables> = {"kind":"Document","definitions":[{"kind":"OperationDefinition","operation":"query","name":{"kind":"Name","value":"ListActionPagesByCampaign"},"variableDefinitions":[{"kind":"VariableDefinition","variable":{"kind":"Variable","name":{"kind":"Name","value":"org"}},"type":{"kind":"NonNullType","type":{"kind":"NamedType","name":{"kind":"Name","value":"String"}}}},{"kind":"VariableDefinition","variable":{"kind":"Variable","name":{"kind":"Name","value":"campaignId"}},"type":{"kind":"NonNullType","type":{"kind":"NamedType","name":{"kind":"Name","value":"Int"}}}}],"selectionSet":{"kind":"SelectionSet","selections":[{"kind":"Field","name":{"kind":"Name","value":"org"},"arguments":[{"kind":"Argument","name":{"kind":"Name","value":"name"},"value":{"kind":"Variable","name":{"kind":"Name","value":"org"}}}],"selectionSet":{"kind":"SelectionSet","selections":[{"kind":"Field","name":{"kind":"Name","value":"name"}},{"kind":"Field","name":{"kind":"Name","value":"title"}},{"kind":"Field","name":{"kind":"Name","value":"actionPages"},"arguments":[{"kind":"Argument","name":{"kind":"Name","value":"select"},"value":{"kind":"ObjectValue","fields":[{"kind":"ObjectField","name":{"kind":"Name","value":"campaignId"},"value":{"kind":"Variable","name":{"kind":"Name","value":"campaignId"}}}]}}],"selectionSet":{"kind":"SelectionSet","selections":[{"kind":"FragmentSpread","name":{"kind":"Name","value":"actionPageFields"}},{"kind":"FragmentSpread","name":{"kind":"Name","value":"actionPagePrivateFields"}},{"kind":"Field","name":{"kind":"Name","value":"campaign"},"selectionSet":{"kind":"SelectionSet","selections":[{"kind":"FragmentSpread","name":{"kind":"Name","value":"campaignFields"}}]}}]}}]}}]}},...ActionPageFields.definitions,...ActionPagePrivateFields.definitions,...CampaignFields.definitions]};
export const ExportCampaignActionsDocument: DocumentNode<ExportCampaignActions, ExportCampaignActionsVariables> = {"kind":"Document","definitions":[{"kind":"OperationDefinition","operation":"query","name":{"kind":"Name","value":"ExportCampaignActions"},"variableDefinitions":[{"kind":"VariableDefinition","variable":{"kind":"Variable","name":{"kind":"Name","value":"org"}},"type":{"kind":"NonNullType","type":{"kind":"NamedType","name":{"kind":"Name","value":"String"}}}},{"kind":"VariableDefinition","variable":{"kind":"Variable","name":{"kind":"Name","value":"campaignId"}},"type":{"kind":"NamedType","name":{"kind":"Name","value":"Int"}}},{"kind":"VariableDefinition","variable":{"kind":"Variable","name":{"kind":"Name","value":"campaignName"}},"type":{"kind":"NamedType","name":{"kind":"Name","value":"String"}}},{"kind":"VariableDefinition","variable":{"kind":"Variable","name":{"kind":"Name","value":"start"}},"type":{"kind":"NamedType","name":{"kind":"Name","value":"Int"}}},{"kind":"VariableDefinition","variable":{"kind":"Variable","name":{"kind":"Name","value":"after"}},"type":{"kind":"NamedType","name":{"kind":"Name","value":"DateTime"}}},{"kind":"VariableDefinition","variable":{"kind":"Variable","name":{"kind":"Name","value":"limit"}},"type":{"kind":"NamedType","name":{"kind":"Name","value":"Int"}}},{"kind":"VariableDefinition","variable":{"kind":"Variable","name":{"kind":"Name","value":"onlyOptIn"}},"type":{"kind":"NamedType","name":{"kind":"Name","value":"Boolean"}}}],"selectionSet":{"kind":"SelectionSet","selections":[{"kind":"Field","name":{"kind":"Name","value":"exportActions"},"arguments":[{"kind":"Argument","name":{"kind":"Name","value":"orgName"},"value":{"kind":"Variable","name":{"kind":"Name","value":"org"}}},{"kind":"Argument","name":{"kind":"Name","value":"campaignId"},"value":{"kind":"Variable","name":{"kind":"Name","value":"campaignId"}}},{"kind":"Argument","name":{"kind":"Name","value":"campaignName"},"value":{"kind":"Variable","name":{"kind":"Name","value":"campaignName"}}},{"kind":"Argument","name":{"kind":"Name","value":"start"},"value":{"kind":"Variable","name":{"kind":"Name","value":"start"}}},{"kind":"Argument","name":{"kind":"Name","value":"after"},"value":{"kind":"Variable","name":{"kind":"Name","value":"after"}}},{"kind":"Argument","name":{"kind":"Name","value":"limit"},"value":{"kind":"Variable","name":{"kind":"Name","value":"limit"}}},{"kind":"Argument","name":{"kind":"Name","value":"onlyOptIn"},"value":{"kind":"Variable","name":{"kind":"Name","value":"onlyOptIn"}}}],"selectionSet":{"kind":"SelectionSet","selections":[{"kind":"FragmentSpread","name":{"kind":"Name","value":"actionExport"}},{"kind":"Field","name":{"kind":"Name","value":"actionPage"},"selectionSet":{"kind":"SelectionSet","selections":[{"kind":"FragmentSpread","name":{"kind":"Name","value":"actionPageIds"}}]}}]}}]}},...ActionExport.definitions,...ActionPageIds.definitions]};
export const ExportOrgActionsDocument: DocumentNode<ExportOrgActions, ExportOrgActionsVariables> = {"kind":"Document","definitions":[{"kind":"OperationDefinition","operation":"query","name":{"kind":"Name","value":"ExportOrgActions"},"variableDefinitions":[{"kind":"VariableDefinition","variable":{"kind":"Variable","name":{"kind":"Name","value":"org"}},"type":{"kind":"NonNullType","type":{"kind":"NamedType","name":{"kind":"Name","value":"String"}}}},{"kind":"VariableDefinition","variable":{"kind":"Variable","name":{"kind":"Name","value":"start"}},"type":{"kind":"NamedType","name":{"kind":"Name","value":"Int"}}},{"kind":"VariableDefinition","variable":{"kind":"Variable","name":{"kind":"Name","value":"after"}},"type":{"kind":"NamedType","name":{"kind":"Name","value":"DateTime"}}},{"kind":"VariableDefinition","variable":{"kind":"Variable","name":{"kind":"Name","value":"limit"}},"type":{"kind":"NamedType","name":{"kind":"Name","value":"Int"}}},{"kind":"VariableDefinition","variable":{"kind":"Variable","name":{"kind":"Name","value":"onlyOptIn"}},"type":{"kind":"NamedType","name":{"kind":"Name","value":"Boolean"}}}],"selectionSet":{"kind":"SelectionSet","selections":[{"kind":"Field","name":{"kind":"Name","value":"exportActions"},"arguments":[{"kind":"Argument","name":{"kind":"Name","value":"orgName"},"value":{"kind":"Variable","name":{"kind":"Name","value":"org"}}},{"kind":"Argument","name":{"kind":"Name","value":"start"},"value":{"kind":"Variable","name":{"kind":"Name","value":"start"}}},{"kind":"Argument","name":{"kind":"Name","value":"after"},"value":{"kind":"Variable","name":{"kind":"Name","value":"after"}}},{"kind":"Argument","name":{"kind":"Name","value":"limit"},"value":{"kind":"Variable","name":{"kind":"Name","value":"limit"}}},{"kind":"Argument","name":{"kind":"Name","value":"onlyOptIn"},"value":{"kind":"Variable","name":{"kind":"Name","value":"onlyOptIn"}}}],"selectionSet":{"kind":"SelectionSet","selections":[{"kind":"FragmentSpread","name":{"kind":"Name","value":"actionExport"}},{"kind":"Field","name":{"kind":"Name","value":"actionPage"},"selectionSet":{"kind":"SelectionSet","selections":[{"kind":"FragmentSpread","name":{"kind":"Name","value":"actionPageIds"}}]}},{"kind":"Field","name":{"kind":"Name","value":"campaign"},"selectionSet":{"kind":"SelectionSet","selections":[{"kind":"FragmentSpread","name":{"kind":"Name","value":"campaignExportIds"}}]}}]}}]}},...ActionExport.definitions,...ActionPageIds.definitions,...CampaignExportIds.definitions]};
export const UpdateActionPageDocument: DocumentNode<UpdateActionPage, UpdateActionPageVariables> = {"kind":"Document","definitions":[{"kind":"OperationDefinition","operation":"mutation","name":{"kind":"Name","value":"UpdateActionPage"},"variableDefinitions":[{"kind":"VariableDefinition","variable":{"kind":"Variable","name":{"kind":"Name","value":"id"}},"type":{"kind":"NonNullType","type":{"kind":"NamedType","name":{"kind":"Name","value":"Int"}}}},{"kind":"VariableDefinition","variable":{"kind":"Variable","name":{"kind":"Name","value":"actionPage"}},"type":{"kind":"NonNullType","type":{"kind":"NamedType","name":{"kind":"Name","value":"ActionPageInput"}}}}],"selectionSet":{"kind":"SelectionSet","selections":[{"kind":"Field","name":{"kind":"Name","value":"updateActionPage"},"arguments":[{"kind":"Argument","name":{"kind":"Name","value":"id"},"value":{"kind":"Variable","name":{"kind":"Name","value":"id"}}},{"kind":"Argument","name":{"kind":"Name","value":"input"},"value":{"kind":"Variable","name":{"kind":"Name","value":"actionPage"}}}],"selectionSet":{"kind":"SelectionSet","selections":[{"kind":"Field","name":{"kind":"Name","value":"id"}}]}}]}}]};
export const CopyActionPageDocument: DocumentNode<CopyActionPage, CopyActionPageVariables> = {"kind":"Document","definitions":[{"kind":"OperationDefinition","operation":"mutation","name":{"kind":"Name","value":"CopyActionPage"},"variableDefinitions":[{"kind":"VariableDefinition","variable":{"kind":"Variable","name":{"kind":"Name","value":"fromName"}},"type":{"kind":"NonNullType","type":{"kind":"NamedType","name":{"kind":"Name","value":"String"}}}},{"kind":"VariableDefinition","variable":{"kind":"Variable","name":{"kind":"Name","value":"toOrg"}},"type":{"kind":"NonNullType","type":{"kind":"NamedType","name":{"kind":"Name","value":"String"}}}},{"kind":"VariableDefinition","variable":{"kind":"Variable","name":{"kind":"Name","value":"toName"}},"type":{"kind":"NonNullType","type":{"kind":"NamedType","name":{"kind":"Name","value":"String"}}}}],"selectionSet":{"kind":"SelectionSet","selections":[{"kind":"Field","name":{"kind":"Name","value":"copyActionPage"},"arguments":[{"kind":"Argument","name":{"kind":"Name","value":"fromName"},"value":{"kind":"Variable","name":{"kind":"Name","value":"fromName"}}},{"kind":"Argument","name":{"kind":"Name","value":"name"},"value":{"kind":"Variable","name":{"kind":"Name","value":"toName"}}},{"kind":"Argument","name":{"kind":"Name","value":"orgName"},"value":{"kind":"Variable","name":{"kind":"Name","value":"toOrg"}}}],"selectionSet":{"kind":"SelectionSet","selections":[{"kind":"FragmentSpread","name":{"kind":"Name","value":"actionPageFields"}},{"kind":"FragmentSpread","name":{"kind":"Name","value":"actionPagePrivateFields"}},{"kind":"Field","name":{"kind":"Name","value":"campaign"},"selectionSet":{"kind":"SelectionSet","selections":[{"kind":"FragmentSpread","name":{"kind":"Name","value":"campaignFields"}}]}}]}}]}},...ActionPageFields.definitions,...ActionPagePrivateFields.definitions,...CampaignFields.definitions]};
export const CopyCampaignActionPageDocument: DocumentNode<CopyCampaignActionPage, CopyCampaignActionPageVariables> = {"kind":"Document","definitions":[{"kind":"OperationDefinition","operation":"mutation","name":{"kind":"Name","value":"CopyCampaignActionPage"},"variableDefinitions":[{"kind":"VariableDefinition","variable":{"kind":"Variable","name":{"kind":"Name","value":"fromCampaign"}},"type":{"kind":"NonNullType","type":{"kind":"NamedType","name":{"kind":"Name","value":"String"}}}},{"kind":"VariableDefinition","variable":{"kind":"Variable","name":{"kind":"Name","value":"toOrg"}},"type":{"kind":"NonNullType","type":{"kind":"NamedType","name":{"kind":"Name","value":"String"}}}},{"kind":"VariableDefinition","variable":{"kind":"Variable","name":{"kind":"Name","value":"toName"}},"type":{"kind":"NonNullType","type":{"kind":"NamedType","name":{"kind":"Name","value":"String"}}}}],"selectionSet":{"kind":"SelectionSet","selections":[{"kind":"Field","name":{"kind":"Name","value":"copyCampaignActionPage"},"arguments":[{"kind":"Argument","name":{"kind":"Name","value":"fromCampaignName"},"value":{"kind":"Variable","name":{"kind":"Name","value":"fromCampaign"}}},{"kind":"Argument","name":{"kind":"Name","value":"name"},"value":{"kind":"Variable","name":{"kind":"Name","value":"toName"}}},{"kind":"Argument","name":{"kind":"Name","value":"orgName"},"value":{"kind":"Variable","name":{"kind":"Name","value":"toOrg"}}}],"selectionSet":{"kind":"SelectionSet","selections":[{"kind":"FragmentSpread","name":{"kind":"Name","value":"actionPageFields"}},{"kind":"FragmentSpread","name":{"kind":"Name","value":"actionPagePrivateFields"}},{"kind":"Field","name":{"kind":"Name","value":"campaign"},"selectionSet":{"kind":"SelectionSet","selections":[{"kind":"Field","name":{"kind":"Name","value":"id"}},{"kind":"Field","name":{"kind":"Name","value":"name"}},{"kind":"Field","name":{"kind":"Name","value":"title"}},{"kind":"Field","name":{"kind":"Name","value":"externalId"}}]}}]}}]}},...ActionPageFields.definitions,...ActionPagePrivateFields.definitions]};
export const JoinOrgDocument: DocumentNode<JoinOrg, JoinOrgVariables> = {"kind":"Document","definitions":[{"kind":"OperationDefinition","operation":"mutation","name":{"kind":"Name","value":"JoinOrg"},"variableDefinitions":[{"kind":"VariableDefinition","variable":{"kind":"Variable","name":{"kind":"Name","value":"orgName"}},"type":{"kind":"NonNullType","type":{"kind":"NamedType","name":{"kind":"Name","value":"String"}}}}],"selectionSet":{"kind":"SelectionSet","selections":[{"kind":"Field","name":{"kind":"Name","value":"joinOrg"},"arguments":[{"kind":"Argument","name":{"kind":"Name","value":"name"},"value":{"kind":"Variable","name":{"kind":"Name","value":"orgName"}}}],"selectionSet":{"kind":"SelectionSet","selections":[{"kind":"Field","name":{"kind":"Name","value":"status"}}]}}]}}]};
export const UpsertCampaignDocument: DocumentNode<UpsertCampaign, UpsertCampaignVariables> = {"kind":"Document","definitions":[{"kind":"OperationDefinition","operation":"mutation","name":{"kind":"Name","value":"UpsertCampaign"},"variableDefinitions":[{"kind":"VariableDefinition","variable":{"kind":"Variable","name":{"kind":"Name","value":"org"}},"type":{"kind":"NonNullType","type":{"kind":"NamedType","name":{"kind":"Name","value":"String"}}}},{"kind":"VariableDefinition","variable":{"kind":"Variable","name":{"kind":"Name","value":"campaign"}},"type":{"kind":"NonNullType","type":{"kind":"NamedType","name":{"kind":"Name","value":"CampaignInput"}}}}],"selectionSet":{"kind":"SelectionSet","selections":[{"kind":"Field","name":{"kind":"Name","value":"upsertCampaign"},"arguments":[{"kind":"Argument","name":{"kind":"Name","value":"orgName"},"value":{"kind":"Variable","name":{"kind":"Name","value":"org"}}},{"kind":"Argument","name":{"kind":"Name","value":"input"},"value":{"kind":"Variable","name":{"kind":"Name","value":"campaign"}}}],"selectionSet":{"kind":"SelectionSet","selections":[{"kind":"Field","name":{"kind":"Name","value":"id"}}]}}]}}]};
export const ListKeysDocument: DocumentNode<ListKeys, ListKeysVariables> = {"kind":"Document","definitions":[{"kind":"OperationDefinition","operation":"query","name":{"kind":"Name","value":"ListKeys"},"variableDefinitions":[{"kind":"VariableDefinition","variable":{"kind":"Variable","name":{"kind":"Name","value":"org"}},"type":{"kind":"NonNullType","type":{"kind":"NamedType","name":{"kind":"Name","value":"String"}}}}],"selectionSet":{"kind":"SelectionSet","selections":[{"kind":"Field","name":{"kind":"Name","value":"org"},"arguments":[{"kind":"Argument","name":{"kind":"Name","value":"name"},"value":{"kind":"Variable","name":{"kind":"Name","value":"org"}}}],"selectionSet":{"kind":"SelectionSet","selections":[{"kind":"Field","name":{"kind":"Name","value":"keys"},"selectionSet":{"kind":"SelectionSet","selections":[{"kind":"FragmentSpread","name":{"kind":"Name","value":"keyFields"}}]}}]}}]}},...KeyFields.definitions]};
export const GenerateKeyDocument: DocumentNode<GenerateKey, GenerateKeyVariables> = {"kind":"Document","definitions":[{"kind":"OperationDefinition","operation":"mutation","name":{"kind":"Name","value":"GenerateKey"},"variableDefinitions":[{"kind":"VariableDefinition","variable":{"kind":"Variable","name":{"kind":"Name","value":"org"}},"type":{"kind":"NonNullType","type":{"kind":"NamedType","name":{"kind":"Name","value":"String"}}}},{"kind":"VariableDefinition","variable":{"kind":"Variable","name":{"kind":"Name","value":"input"}},"type":{"kind":"NonNullType","type":{"kind":"NamedType","name":{"kind":"Name","value":"GenKeyInput"}}}}],"selectionSet":{"kind":"SelectionSet","selections":[{"kind":"Field","name":{"kind":"Name","value":"generateKey"},"arguments":[{"kind":"Argument","name":{"kind":"Name","value":"orgName"},"value":{"kind":"Variable","name":{"kind":"Name","value":"org"}}},{"kind":"Argument","name":{"kind":"Name","value":"input"},"value":{"kind":"Variable","name":{"kind":"Name","value":"input"}}}],"selectionSet":{"kind":"SelectionSet","selections":[{"kind":"Field","name":{"kind":"Name","value":"id"}},{"kind":"Field","name":{"kind":"Name","value":"name"}},{"kind":"Field","name":{"kind":"Name","value":"public"}},{"kind":"Field","name":{"kind":"Name","value":"private"}},{"kind":"Field","name":{"kind":"Name","value":"active"}},{"kind":"Field","name":{"kind":"Name","value":"expired"}},{"kind":"Field","name":{"kind":"Name","value":"expiredAt"}}]}}]}}]};
export const AddKeyDocument: DocumentNode<AddKey, AddKeyVariables> = {"kind":"Document","definitions":[{"kind":"OperationDefinition","operation":"mutation","name":{"kind":"Name","value":"AddKey"},"variableDefinitions":[{"kind":"VariableDefinition","variable":{"kind":"Variable","name":{"kind":"Name","value":"org"}},"type":{"kind":"NonNullType","type":{"kind":"NamedType","name":{"kind":"Name","value":"String"}}}},{"kind":"VariableDefinition","variable":{"kind":"Variable","name":{"kind":"Name","value":"input"}},"type":{"kind":"NonNullType","type":{"kind":"NamedType","name":{"kind":"Name","value":"AddKeyInput"}}}}],"selectionSet":{"kind":"SelectionSet","selections":[{"kind":"Field","name":{"kind":"Name","value":"addKey"},"arguments":[{"kind":"Argument","name":{"kind":"Name","value":"orgName"},"value":{"kind":"Variable","name":{"kind":"Name","value":"org"}}},{"kind":"Argument","name":{"kind":"Name","value":"input"},"value":{"kind":"Variable","name":{"kind":"Name","value":"input"}}}],"selectionSet":{"kind":"SelectionSet","selections":[{"kind":"Field","name":{"kind":"Name","value":"id"}},{"kind":"Field","name":{"kind":"Name","value":"name"}},{"kind":"Field","name":{"kind":"Name","value":"public"}},{"kind":"Field","name":{"kind":"Name","value":"active"}},{"kind":"Field","name":{"kind":"Name","value":"expired"}},{"kind":"Field","name":{"kind":"Name","value":"expiredAt"}}]}}]}}]};
export const ActivateKeyDocument: DocumentNode<ActivateKey, ActivateKeyVariables> = {"kind":"Document","definitions":[{"kind":"OperationDefinition","operation":"mutation","name":{"kind":"Name","value":"ActivateKey"},"variableDefinitions":[{"kind":"VariableDefinition","variable":{"kind":"Variable","name":{"kind":"Name","value":"org"}},"type":{"kind":"NonNullType","type":{"kind":"NamedType","name":{"kind":"Name","value":"String"}}}},{"kind":"VariableDefinition","variable":{"kind":"Variable","name":{"kind":"Name","value":"id"}},"type":{"kind":"NonNullType","type":{"kind":"NamedType","name":{"kind":"Name","value":"Int"}}}}],"selectionSet":{"kind":"SelectionSet","selections":[{"kind":"Field","name":{"kind":"Name","value":"activateKey"},"arguments":[{"kind":"Argument","name":{"kind":"Name","value":"orgName"},"value":{"kind":"Variable","name":{"kind":"Name","value":"org"}}},{"kind":"Argument","name":{"kind":"Name","value":"id"},"value":{"kind":"Variable","name":{"kind":"Name","value":"id"}}}],"selectionSet":{"kind":"SelectionSet","selections":[{"kind":"Field","name":{"kind":"Name","value":"status"}}]}}]}}]};
export const AddOrgDocument: DocumentNode<AddOrg, AddOrgVariables> = {"kind":"Document","definitions":[{"kind":"OperationDefinition","operation":"mutation","name":{"kind":"Name","value":"AddOrg"},"variableDefinitions":[{"kind":"VariableDefinition","variable":{"kind":"Variable","name":{"kind":"Name","value":"org"}},"type":{"kind":"NonNullType","type":{"kind":"NamedType","name":{"kind":"Name","value":"OrgInput"}}}}],"selectionSet":{"kind":"SelectionSet","selections":[{"kind":"Field","name":{"kind":"Name","value":"addOrg"},"arguments":[{"kind":"Argument","name":{"kind":"Name","value":"input"},"value":{"kind":"Variable","name":{"kind":"Name","value":"org"}}}],"selectionSet":{"kind":"SelectionSet","selections":[{"kind":"FragmentSpread","name":{"kind":"Name","value":"orgIds"}}]}}]}},...OrgIds.definitions]};
export const UpdateOrgDocument: DocumentNode<UpdateOrg, UpdateOrgVariables> = {"kind":"Document","definitions":[{"kind":"OperationDefinition","operation":"mutation","name":{"kind":"Name","value":"UpdateOrg"},"variableDefinitions":[{"kind":"VariableDefinition","variable":{"kind":"Variable","name":{"kind":"Name","value":"orgName"}},"type":{"kind":"NonNullType","type":{"kind":"NamedType","name":{"kind":"Name","value":"String"}}}},{"kind":"VariableDefinition","variable":{"kind":"Variable","name":{"kind":"Name","value":"org"}},"type":{"kind":"NonNullType","type":{"kind":"NamedType","name":{"kind":"Name","value":"OrgInput"}}}}],"selectionSet":{"kind":"SelectionSet","selections":[{"kind":"Field","name":{"kind":"Name","value":"updateOrg"},"arguments":[{"kind":"Argument","name":{"kind":"Name","value":"name"},"value":{"kind":"Variable","name":{"kind":"Name","value":"orgName"}}},{"kind":"Argument","name":{"kind":"Name","value":"input"},"value":{"kind":"Variable","name":{"kind":"Name","value":"org"}}}],"selectionSet":{"kind":"SelectionSet","selections":[{"kind":"FragmentSpread","name":{"kind":"Name","value":"orgFields"}},{"kind":"FragmentSpread","name":{"kind":"Name","value":"orgPrivateFields"}}]}}]}},...OrgFields.definitions,...OrgPrivateFields.definitions]};
export const ActionPageUpsertedDocument: DocumentNode<ActionPageUpserted, ActionPageUpsertedVariables> = {"kind":"Document","definitions":[{"kind":"OperationDefinition","operation":"subscription","name":{"kind":"Name","value":"ActionPageUpserted"},"variableDefinitions":[{"kind":"VariableDefinition","variable":{"kind":"Variable","name":{"kind":"Name","value":"org"}},"type":{"kind":"NamedType","name":{"kind":"Name","value":"String"}}}],"selectionSet":{"kind":"SelectionSet","selections":[{"kind":"Field","name":{"kind":"Name","value":"actionPageUpserted"},"arguments":[{"kind":"Argument","name":{"kind":"Name","value":"orgName"},"value":{"kind":"Variable","name":{"kind":"Name","value":"org"}}}],"selectionSet":{"kind":"SelectionSet","selections":[{"kind":"FragmentSpread","name":{"kind":"Name","value":"actionPageFields"}},{"kind":"FragmentSpread","name":{"kind":"Name","value":"actionPagePrivateFields"}},{"kind":"Field","name":{"kind":"Name","value":"campaign"},"selectionSet":{"kind":"SelectionSet","selections":[{"kind":"FragmentSpread","name":{"kind":"Name","value":"campaignIds"}}]}},{"kind":"Field","name":{"kind":"Name","value":"org"},"selectionSet":{"kind":"SelectionSet","selections":[{"kind":"FragmentSpread","name":{"kind":"Name","value":"orgIds"}}]}}]}}]}},...ActionPageFields.definitions,...ActionPagePrivateFields.definitions,...CampaignIds.definitions,...OrgIds.definitions]};
export const CurrentUserOrgsDocument: DocumentNode<CurrentUserOrgs, CurrentUserOrgsVariables> = {"kind":"Document","definitions":[{"kind":"OperationDefinition","operation":"query","name":{"kind":"Name","value":"CurrentUserOrgs"},"selectionSet":{"kind":"SelectionSet","selections":[{"kind":"Field","name":{"kind":"Name","value":"currentUser"},"selectionSet":{"kind":"SelectionSet","selections":[{"kind":"Field","name":{"kind":"Name","value":"id"}},{"kind":"Field","name":{"kind":"Name","value":"email"}},{"kind":"Field","name":{"kind":"Name","value":"roles"},"selectionSet":{"kind":"SelectionSet","selections":[{"kind":"Field","name":{"kind":"Name","value":"role"}},{"kind":"Field","name":{"kind":"Name","value":"org"},"selectionSet":{"kind":"SelectionSet","selections":[{"kind":"FragmentSpread","name":{"kind":"Name","value":"orgIds"}}]}}]}}]}}]}},...OrgIds.definitions]};
export const DashOrgOverviewDocument: DocumentNode<DashOrgOverview, DashOrgOverviewVariables> = {"kind":"Document","definitions":[{"kind":"OperationDefinition","operation":"query","name":{"kind":"Name","value":"DashOrgOverview"},"variableDefinitions":[{"kind":"VariableDefinition","variable":{"kind":"Variable","name":{"kind":"Name","value":"org"}},"type":{"kind":"NonNullType","type":{"kind":"NamedType","name":{"kind":"Name","value":"String"}}}}],"selectionSet":{"kind":"SelectionSet","selections":[{"kind":"Field","name":{"kind":"Name","value":"org"},"arguments":[{"kind":"Argument","name":{"kind":"Name","value":"name"},"value":{"kind":"Variable","name":{"kind":"Name","value":"org"}}}],"selectionSet":{"kind":"SelectionSet","selections":[{"kind":"Field","name":{"kind":"Name","value":"name"}},{"kind":"Field","name":{"kind":"Name","value":"title"}},{"kind":"FragmentSpread","name":{"kind":"Name","value":"orgPrivateFields"}},{"kind":"InlineFragment","typeCondition":{"kind":"NamedType","name":{"kind":"Name","value":"PrivateOrg"}},"selectionSet":{"kind":"SelectionSet","selections":[{"kind":"Field","name":{"kind":"Name","value":"campaigns"},"selectionSet":{"kind":"SelectionSet","selections":[{"kind":"FragmentSpread","name":{"kind":"Name","value":"campaignFields"}},{"kind":"FragmentSpread","name":{"kind":"Name","value":"campaignStats"}},{"kind":"Field","name":{"kind":"Name","value":"org"},"selectionSet":{"kind":"SelectionSet","selections":[{"kind":"FragmentSpread","name":{"kind":"Name","value":"orgIds"}}]}}]}}]}}]}}]}},...OrgPrivateFields.definitions,...CampaignFields.definitions,...CampaignStats.definitions,...OrgIds.definitions]};
export const GetOrgDocument: DocumentNode<GetOrg, GetOrgVariables> = {"kind":"Document","definitions":[{"kind":"OperationDefinition","operation":"query","name":{"kind":"Name","value":"GetOrg"},"variableDefinitions":[{"kind":"VariableDefinition","variable":{"kind":"Variable","name":{"kind":"Name","value":"org"}},"type":{"kind":"NonNullType","type":{"kind":"NamedType","name":{"kind":"Name","value":"String"}}}}],"selectionSet":{"kind":"SelectionSet","selections":[{"kind":"Field","name":{"kind":"Name","value":"org"},"arguments":[{"kind":"Argument","name":{"kind":"Name","value":"name"},"value":{"kind":"Variable","name":{"kind":"Name","value":"org"}}}],"selectionSet":{"kind":"SelectionSet","selections":[{"kind":"FragmentSpread","name":{"kind":"Name","value":"orgFields"}},{"kind":"FragmentSpread","name":{"kind":"Name","value":"orgPrivateFields"}},{"kind":"Field","name":{"kind":"Name","value":"keys"},"arguments":[{"kind":"Argument","name":{"kind":"Name","value":"select"},"value":{"kind":"ObjectValue","fields":[{"kind":"ObjectField","name":{"kind":"Name","value":"active"},"value":{"kind":"BooleanValue","value":true}}]}}],"selectionSet":{"kind":"SelectionSet","selections":[{"kind":"FragmentSpread","name":{"kind":"Name","value":"keyFields"}}]}},{"kind":"Field","name":{"kind":"Name","value":"services"},"selectionSet":{"kind":"SelectionSet","selections":[{"kind":"FragmentSpread","name":{"kind":"Name","value":"serviceFields"}}]}}]}}]}},...OrgFields.definitions,...OrgPrivateFields.definitions,...KeyFields.definitions,...ServiceFields.definitions]};
export const GetOrgAttrsDocument: DocumentNode<GetOrgAttrs, GetOrgAttrsVariables> = {"kind":"Document","definitions":[{"kind":"OperationDefinition","operation":"query","name":{"kind":"Name","value":"GetOrgAttrs"},"variableDefinitions":[{"kind":"VariableDefinition","variable":{"kind":"Variable","name":{"kind":"Name","value":"org"}},"type":{"kind":"NonNullType","type":{"kind":"NamedType","name":{"kind":"Name","value":"String"}}}}],"selectionSet":{"kind":"SelectionSet","selections":[{"kind":"Field","name":{"kind":"Name","value":"org"},"arguments":[{"kind":"Argument","name":{"kind":"Name","value":"name"},"value":{"kind":"Variable","name":{"kind":"Name","value":"org"}}}],"selectionSet":{"kind":"SelectionSet","selections":[{"kind":"FragmentSpread","name":{"kind":"Name","value":"orgFields"}},{"kind":"FragmentSpread","name":{"kind":"Name","value":"orgPrivateFields"}}]}}]}},...OrgFields.definitions,...OrgPrivateFields.definitions]};
export type ListCampaignsVariables = Types.Exact<{
  org: Types.Scalars['String'];
}>;


export type ListCampaigns = { org: { campaigns: Array<(
      { org: OrgIds_PublicOrg_ | OrgIds_PrivateOrg_ }
      & CampaignFields_PublicCampaign_
    ) | (
      { org: OrgIds_PublicOrg_ | OrgIds_PrivateOrg_ }
      & CampaignFields_PrivateCampaign_
      & CampaignPrivateFields
    )> } };

export type ListActionPagesVariables = Types.Exact<{
  org: Types.Scalars['String'];
}>;


export type ListActionPages = { org: { actionPages: Array<(
      { campaign: CampaignIds_PublicCampaign_ | CampaignIds_PrivateCampaign_ }
      & ActionPageFields_PrivateActionPage_
      & ActionPagePrivateFields
    ) | (
      { campaign: CampaignIds_PublicCampaign_ | CampaignIds_PrivateCampaign_ }
      & ActionPageFields_PublicActionPage_
    )> } };

export type GetCampaignVariables = Types.Exact<{
  org: Types.Scalars['String'];
  id: Types.Scalars['Int'];
}>;


export type GetCampaign = { org: { campaign: (
      { org: OrgIds_PublicOrg_ | OrgIds_PrivateOrg_ }
      & CampaignFields_PublicCampaign_
      & CampaignStats_PublicCampaign_
    ) | (
      { org: OrgIds_PublicOrg_ | OrgIds_PrivateOrg_ }
      & CampaignFields_PrivateCampaign_
      & CampaignPrivateFields
      & CampaignStats_PrivateCampaign_
      & CampaignPartnerships
    ) } };

export type FindPublicCampaignVariables = Types.Exact<{
  name?: Types.Maybe<Types.Scalars['String']>;
  title?: Types.Maybe<Types.Scalars['String']>;
}>;


export type FindPublicCampaign = { campaigns: Array<(
    { org: OrgIds_PublicOrg_ | OrgIds_PrivateOrg_ }
    & CampaignFields_PublicCampaign_
  ) | (
    { org: OrgIds_PublicOrg_ | OrgIds_PrivateOrg_ }
    & CampaignFields_PrivateCampaign_
  )> };

export type GetActionPageVariables = Types.Exact<{
  org: Types.Scalars['String'];
  id?: Types.Maybe<Types.Scalars['Int']>;
  name?: Types.Maybe<Types.Scalars['String']>;
}>;


export type GetActionPage = { org: (
    Pick<Types.PrivateOrg, 'name' | 'title'>
    & { actionPage: (
      { campaign: CampaignFields_PublicCampaign_ | (
        CampaignFields_PrivateCampaign_
        & CampaignPrivateFields
      ) }
      & ActionPageFields_PrivateActionPage_
      & ActionPagePrivateFields
    ) | (
      { campaign: CampaignFields_PublicCampaign_ | (
        CampaignFields_PrivateCampaign_
        & CampaignPrivateFields
      ) }
      & ActionPageFields_PublicActionPage_
    ) }
  ) };

export type ListActionPagesByCampaignVariables = Types.Exact<{
  org: Types.Scalars['String'];
  campaignId: Types.Scalars['Int'];
}>;


export type ListActionPagesByCampaign = { org: (
    Pick<Types.PrivateOrg, 'name' | 'title'>
    & { actionPages: Array<(
      { campaign: CampaignFields_PublicCampaign_ | CampaignFields_PrivateCampaign_ }
      & ActionPageFields_PrivateActionPage_
      & ActionPagePrivateFields
    ) | (
      { campaign: CampaignFields_PublicCampaign_ | CampaignFields_PrivateCampaign_ }
      & ActionPageFields_PublicActionPage_
    )> }
  ) };

export type ExportCampaignActionsVariables = Types.Exact<{
  org: Types.Scalars['String'];
  campaignId?: Types.Maybe<Types.Scalars['Int']>;
  campaignName?: Types.Maybe<Types.Scalars['String']>;
  start?: Types.Maybe<Types.Scalars['Int']>;
  after?: Types.Maybe<Types.Scalars['DateTime']>;
  limit?: Types.Maybe<Types.Scalars['Int']>;
  onlyOptIn?: Types.Maybe<Types.Scalars['Boolean']>;
}>;


export type ExportCampaignActions = { exportActions: Array<Types.Maybe<(
    { actionPage: ActionPageIds_PrivateActionPage_ | ActionPageIds_PublicActionPage_ }
    & ActionExport
  )>> };

export type ExportOrgActionsVariables = Types.Exact<{
  org: Types.Scalars['String'];
  start?: Types.Maybe<Types.Scalars['Int']>;
  after?: Types.Maybe<Types.Scalars['DateTime']>;
  limit?: Types.Maybe<Types.Scalars['Int']>;
  onlyOptIn?: Types.Maybe<Types.Scalars['Boolean']>;
}>;


export type ExportOrgActions = { exportActions: Array<Types.Maybe<(
    { actionPage: ActionPageIds_PrivateActionPage_ | ActionPageIds_PublicActionPage_, campaign: CampaignExportIds_PublicCampaign_ | CampaignExportIds_PrivateCampaign_ }
    & ActionExport
  )>> };

export type UpdateActionPageVariables = Types.Exact<{
  id: Types.Scalars['Int'];
  actionPage: Types.ActionPageInput;
}>;


export type UpdateActionPage = { updateActionPage: Pick<Types.PrivateActionPage, 'id'> | Pick<Types.PublicActionPage, 'id'> };

export type CopyActionPageVariables = Types.Exact<{
  fromName: Types.Scalars['String'];
  toOrg: Types.Scalars['String'];
  toName: Types.Scalars['String'];
}>;


export type CopyActionPage = { copyActionPage: (
    { campaign: CampaignFields_PublicCampaign_ | CampaignFields_PrivateCampaign_ }
    & ActionPageFields_PrivateActionPage_
    & ActionPagePrivateFields
  ) | (
    { campaign: CampaignFields_PublicCampaign_ | CampaignFields_PrivateCampaign_ }
    & ActionPageFields_PublicActionPage_
  ) };

export type CopyCampaignActionPageVariables = Types.Exact<{
  fromCampaign: Types.Scalars['String'];
  toOrg: Types.Scalars['String'];
  toName: Types.Scalars['String'];
}>;


export type CopyCampaignActionPage = { copyCampaignActionPage: (
    { campaign: Pick<Types.PublicCampaign, 'id' | 'name' | 'title' | 'externalId'> | Pick<Types.PrivateCampaign, 'id' | 'name' | 'title' | 'externalId'> }
    & ActionPageFields_PrivateActionPage_
    & ActionPagePrivateFields
  ) | (
    { campaign: Pick<Types.PublicCampaign, 'id' | 'name' | 'title' | 'externalId'> | Pick<Types.PrivateCampaign, 'id' | 'name' | 'title' | 'externalId'> }
    & ActionPageFields_PublicActionPage_
  ) };

export type JoinOrgVariables = Types.Exact<{
  orgName: Types.Scalars['String'];
}>;


export type JoinOrg = { joinOrg: Pick<Types.JoinOrgResult, 'status'> };

export type UpsertCampaignVariables = Types.Exact<{
  org: Types.Scalars['String'];
  campaign: Types.CampaignInput;
}>;


export type UpsertCampaign = { upsertCampaign: Pick<Types.PublicCampaign, 'id'> | Pick<Types.PrivateCampaign, 'id'> };

export type ListKeysVariables = Types.Exact<{
  org: Types.Scalars['String'];
}>;


export type ListKeys = { org: { keys: Array<KeyFields> } };

export type GenerateKeyVariables = Types.Exact<{
  org: Types.Scalars['String'];
  input: Types.GenKeyInput;
}>;


export type GenerateKey = { generateKey: Pick<Types.KeyWithPrivate, 'id' | 'name' | 'public' | 'private' | 'active' | 'expired' | 'expiredAt'> };

export type AddKeyVariables = Types.Exact<{
  org: Types.Scalars['String'];
  input: Types.AddKeyInput;
}>;


export type AddKey = { addKey: Pick<Types.Key, 'id' | 'name' | 'public' | 'active' | 'expired' | 'expiredAt'> };

export type ActivateKeyVariables = Types.Exact<{
  org: Types.Scalars['String'];
  id: Types.Scalars['Int'];
}>;


export type ActivateKey = { activateKey: Pick<Types.ActivateKeyResult, 'status'> };

export type AddOrgVariables = Types.Exact<{
  org: Types.OrgInput;
}>;


export type AddOrg = { addOrg: OrgIds_PublicOrg_ | OrgIds_PrivateOrg_ };

export type UpdateOrgVariables = Types.Exact<{
  orgName: Types.Scalars['String'];
  org: Types.OrgInput;
}>;


export type UpdateOrg = { updateOrg: OrgFields_PublicOrg_ | (
    OrgFields_PrivateOrg_
    & OrgPrivateFields
  ) };

export type ActionPageUpsertedVariables = Types.Exact<{
  org?: Types.Maybe<Types.Scalars['String']>;
}>;


export type ActionPageUpserted = { actionPageUpserted: (
    { campaign: CampaignIds_PublicCampaign_ | CampaignIds_PrivateCampaign_, org: OrgIds_PublicOrg_ | OrgIds_PrivateOrg_ }
    & ActionPageFields_PrivateActionPage_
    & ActionPagePrivateFields
  ) | (
    { campaign: CampaignIds_PublicCampaign_ | CampaignIds_PrivateCampaign_, org: OrgIds_PublicOrg_ | OrgIds_PrivateOrg_ }
    & ActionPageFields_PublicActionPage_
  ) };

export type CurrentUserOrgsVariables = Types.Exact<{ [key: string]: never; }>;


export type CurrentUserOrgs = { currentUser: (
    Pick<Types.User, 'id' | 'email'>
    & { roles: Array<(
      Pick<Types.UserRole, 'role'>
      & { org: OrgIds_PublicOrg_ | OrgIds_PrivateOrg_ }
    )> }
  ) };

export type DashOrgOverviewVariables = Types.Exact<{
  org: Types.Scalars['String'];
}>;


export type DashOrgOverview = { org: (
    Pick<Types.PrivateOrg, 'name' | 'title'>
    & { campaigns: Array<(
      { org: OrgIds_PublicOrg_ | OrgIds_PrivateOrg_ }
      & CampaignFields_PublicCampaign_
      & CampaignStats_PublicCampaign_
    ) | (
      { org: OrgIds_PublicOrg_ | OrgIds_PrivateOrg_ }
      & CampaignFields_PrivateCampaign_
      & CampaignStats_PrivateCampaign_
    )> }
    & OrgPrivateFields
  ) };

export type GetOrgVariables = Types.Exact<{
  org: Types.Scalars['String'];
}>;


export type GetOrg = { org: (
    { keys: Array<KeyFields>, services: Array<Types.Maybe<ServiceFields>> }
    & OrgFields_PrivateOrg_
    & OrgPrivateFields
  ) };

export type GetOrgAttrsVariables = Types.Exact<{
  org: Types.Scalars['String'];
}>;


export type GetOrgAttrs = { org: (
    OrgFields_PrivateOrg_
    & OrgPrivateFields
  ) };

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
