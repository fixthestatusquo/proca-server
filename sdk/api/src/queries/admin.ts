import * as Types from '../types';

import { TypedDocumentNode as DocumentNode } from '@graphql-typed-document-node/core';

export const ListCampaignsDocument: DocumentNode<ListCampaigns, ListCampaignsVariables> = {"kind":"Document","definitions":[{"kind":"OperationDefinition","operation":"query","name":{"kind":"Name","value":"ListCampaigns"},"variableDefinitions":[{"kind":"VariableDefinition","variable":{"kind":"Variable","name":{"kind":"Name","value":"org"}},"type":{"kind":"NonNullType","type":{"kind":"NamedType","name":{"kind":"Name","value":"String"}}}}],"selectionSet":{"kind":"SelectionSet","selections":[{"kind":"Field","name":{"kind":"Name","value":"org"},"arguments":[{"kind":"Argument","name":{"kind":"Name","value":"name"},"value":{"kind":"Variable","name":{"kind":"Name","value":"org"}}}],"selectionSet":{"kind":"SelectionSet","selections":[{"kind":"Field","name":{"kind":"Name","value":"campaigns"},"selectionSet":{"kind":"SelectionSet","selections":[{"kind":"Field","name":{"kind":"Name","value":"id"}},{"kind":"Field","name":{"kind":"Name","value":"externalId"}},{"kind":"Field","name":{"kind":"Name","value":"name"}},{"kind":"Field","name":{"kind":"Name","value":"title"}},{"kind":"Field","name":{"kind":"Name","value":"org"},"selectionSet":{"kind":"SelectionSet","selections":[{"kind":"Field","name":{"kind":"Name","value":"name"}},{"kind":"Field","name":{"kind":"Name","value":"title"}}]}}]}}]}}]}}]};
export const GetCampaignDocument: DocumentNode<GetCampaign, GetCampaignVariables> = {"kind":"Document","definitions":[{"kind":"OperationDefinition","operation":"query","name":{"kind":"Name","value":"GetCampaign"},"variableDefinitions":[{"kind":"VariableDefinition","variable":{"kind":"Variable","name":{"kind":"Name","value":"org"}},"type":{"kind":"NonNullType","type":{"kind":"NamedType","name":{"kind":"Name","value":"String"}}}},{"kind":"VariableDefinition","variable":{"kind":"Variable","name":{"kind":"Name","value":"id"}},"type":{"kind":"NonNullType","type":{"kind":"NamedType","name":{"kind":"Name","value":"Int"}}}}],"selectionSet":{"kind":"SelectionSet","selections":[{"kind":"Field","name":{"kind":"Name","value":"org"},"arguments":[{"kind":"Argument","name":{"kind":"Name","value":"name"},"value":{"kind":"Variable","name":{"kind":"Name","value":"org"}}}],"selectionSet":{"kind":"SelectionSet","selections":[{"kind":"Field","name":{"kind":"Name","value":"campaign"},"arguments":[{"kind":"Argument","name":{"kind":"Name","value":"id"},"value":{"kind":"Variable","name":{"kind":"Name","value":"id"}}}],"selectionSet":{"kind":"SelectionSet","selections":[{"kind":"Field","name":{"kind":"Name","value":"id"}},{"kind":"Field","name":{"kind":"Name","value":"externalId"}},{"kind":"Field","name":{"kind":"Name","value":"name"}},{"kind":"Field","name":{"kind":"Name","value":"title"}},{"kind":"Field","name":{"kind":"Name","value":"stats"},"selectionSet":{"kind":"SelectionSet","selections":[{"kind":"Field","name":{"kind":"Name","value":"supporterCount"}},{"kind":"Field","name":{"kind":"Name","value":"actionCount"},"selectionSet":{"kind":"SelectionSet","selections":[{"kind":"Field","name":{"kind":"Name","value":"actionType"}},{"kind":"Field","name":{"kind":"Name","value":"count"}}]}}]}}]}}]}}]}}]};
export const GetActionPageDocument: DocumentNode<GetActionPage, GetActionPageVariables> = {"kind":"Document","definitions":[{"kind":"OperationDefinition","operation":"query","name":{"kind":"Name","value":"GetActionPage"},"variableDefinitions":[{"kind":"VariableDefinition","variable":{"kind":"Variable","name":{"kind":"Name","value":"org"}},"type":{"kind":"NonNullType","type":{"kind":"NamedType","name":{"kind":"Name","value":"String"}}}},{"kind":"VariableDefinition","variable":{"kind":"Variable","name":{"kind":"Name","value":"id"}},"type":{"kind":"NamedType","name":{"kind":"Name","value":"Int"}}},{"kind":"VariableDefinition","variable":{"kind":"Variable","name":{"kind":"Name","value":"name"}},"type":{"kind":"NamedType","name":{"kind":"Name","value":"String"}}}],"selectionSet":{"kind":"SelectionSet","selections":[{"kind":"Field","name":{"kind":"Name","value":"org"},"arguments":[{"kind":"Argument","name":{"kind":"Name","value":"name"},"value":{"kind":"Variable","name":{"kind":"Name","value":"org"}}}],"selectionSet":{"kind":"SelectionSet","selections":[{"kind":"Field","name":{"kind":"Name","value":"name"}},{"kind":"Field","name":{"kind":"Name","value":"title"}},{"kind":"Field","name":{"kind":"Name","value":"actionPage"},"arguments":[{"kind":"Argument","name":{"kind":"Name","value":"id"},"value":{"kind":"Variable","name":{"kind":"Name","value":"id"}}},{"kind":"Argument","name":{"kind":"Name","value":"name"},"value":{"kind":"Variable","name":{"kind":"Name","value":"name"}}}],"selectionSet":{"kind":"SelectionSet","selections":[{"kind":"Field","name":{"kind":"Name","value":"id"}},{"kind":"Field","name":{"kind":"Name","value":"name"}},{"kind":"Field","name":{"kind":"Name","value":"locale"}},{"kind":"Field","name":{"kind":"Name","value":"extraSupporters"}},{"kind":"Field","name":{"kind":"Name","value":"thankYouTemplateRef"}},{"kind":"Field","name":{"kind":"Name","value":"journey"}},{"kind":"Field","name":{"kind":"Name","value":"config"}},{"kind":"Field","name":{"kind":"Name","value":"campaign"},"selectionSet":{"kind":"SelectionSet","selections":[{"kind":"Field","name":{"kind":"Name","value":"id"}},{"kind":"Field","name":{"kind":"Name","value":"name"}},{"kind":"Field","name":{"kind":"Name","value":"title"}},{"kind":"Field","name":{"kind":"Name","value":"externalId"}}]}}]}}]}}]}}]};
export const ListActionPagesDocument: DocumentNode<ListActionPages, ListActionPagesVariables> = {"kind":"Document","definitions":[{"kind":"OperationDefinition","operation":"query","name":{"kind":"Name","value":"ListActionPages"},"variableDefinitions":[{"kind":"VariableDefinition","variable":{"kind":"Variable","name":{"kind":"Name","value":"org"}},"type":{"kind":"NonNullType","type":{"kind":"NamedType","name":{"kind":"Name","value":"String"}}}}],"selectionSet":{"kind":"SelectionSet","selections":[{"kind":"Field","name":{"kind":"Name","value":"org"},"arguments":[{"kind":"Argument","name":{"kind":"Name","value":"name"},"value":{"kind":"Variable","name":{"kind":"Name","value":"org"}}}],"selectionSet":{"kind":"SelectionSet","selections":[{"kind":"Field","name":{"kind":"Name","value":"name"}},{"kind":"Field","name":{"kind":"Name","value":"title"}},{"kind":"Field","name":{"kind":"Name","value":"actionPages"},"selectionSet":{"kind":"SelectionSet","selections":[{"kind":"Field","name":{"kind":"Name","value":"id"}},{"kind":"Field","name":{"kind":"Name","value":"name"}},{"kind":"Field","name":{"kind":"Name","value":"locale"}},{"kind":"Field","name":{"kind":"Name","value":"extraSupporters"}},{"kind":"Field","name":{"kind":"Name","value":"campaign"},"selectionSet":{"kind":"SelectionSet","selections":[{"kind":"Field","name":{"kind":"Name","value":"name"}},{"kind":"Field","name":{"kind":"Name","value":"id"}},{"kind":"Field","name":{"kind":"Name","value":"externalId"}}]}}]}}]}}]}}]};
export const ListActionPagesByCampaignDocument: DocumentNode<ListActionPagesByCampaign, ListActionPagesByCampaignVariables> = {"kind":"Document","definitions":[{"kind":"OperationDefinition","operation":"query","name":{"kind":"Name","value":"ListActionPagesByCampaign"},"variableDefinitions":[{"kind":"VariableDefinition","variable":{"kind":"Variable","name":{"kind":"Name","value":"org"}},"type":{"kind":"NonNullType","type":{"kind":"NamedType","name":{"kind":"Name","value":"String"}}}},{"kind":"VariableDefinition","variable":{"kind":"Variable","name":{"kind":"Name","value":"campaignId"}},"type":{"kind":"NonNullType","type":{"kind":"NamedType","name":{"kind":"Name","value":"Int"}}}}],"selectionSet":{"kind":"SelectionSet","selections":[{"kind":"Field","name":{"kind":"Name","value":"org"},"arguments":[{"kind":"Argument","name":{"kind":"Name","value":"name"},"value":{"kind":"Variable","name":{"kind":"Name","value":"org"}}}],"selectionSet":{"kind":"SelectionSet","selections":[{"kind":"Field","name":{"kind":"Name","value":"name"}},{"kind":"Field","name":{"kind":"Name","value":"title"}},{"kind":"Field","name":{"kind":"Name","value":"actionPages"},"arguments":[{"kind":"Argument","name":{"kind":"Name","value":"select"},"value":{"kind":"ObjectValue","fields":[{"kind":"ObjectField","name":{"kind":"Name","value":"campaignId"},"value":{"kind":"Variable","name":{"kind":"Name","value":"campaignId"}}}]}}],"selectionSet":{"kind":"SelectionSet","selections":[{"kind":"Field","name":{"kind":"Name","value":"id"}},{"kind":"Field","name":{"kind":"Name","value":"name"}},{"kind":"Field","name":{"kind":"Name","value":"locale"}},{"kind":"Field","name":{"kind":"Name","value":"extraSupporters"}},{"kind":"Field","name":{"kind":"Name","value":"campaign"},"selectionSet":{"kind":"SelectionSet","selections":[{"kind":"Field","name":{"kind":"Name","value":"name"}},{"kind":"Field","name":{"kind":"Name","value":"id"}},{"kind":"Field","name":{"kind":"Name","value":"externalId"}}]}}]}}]}}]}}]};
export const ExportCampaignActionsDocument: DocumentNode<ExportCampaignActions, ExportCampaignActionsVariables> = {"kind":"Document","definitions":[{"kind":"OperationDefinition","operation":"query","name":{"kind":"Name","value":"ExportCampaignActions"},"variableDefinitions":[{"kind":"VariableDefinition","variable":{"kind":"Variable","name":{"kind":"Name","value":"org"}},"type":{"kind":"NonNullType","type":{"kind":"NamedType","name":{"kind":"Name","value":"String"}}}},{"kind":"VariableDefinition","variable":{"kind":"Variable","name":{"kind":"Name","value":"campaignId"}},"type":{"kind":"NamedType","name":{"kind":"Name","value":"Int"}}},{"kind":"VariableDefinition","variable":{"kind":"Variable","name":{"kind":"Name","value":"campaignName"}},"type":{"kind":"NamedType","name":{"kind":"Name","value":"String"}}},{"kind":"VariableDefinition","variable":{"kind":"Variable","name":{"kind":"Name","value":"start"}},"type":{"kind":"NamedType","name":{"kind":"Name","value":"Int"}}},{"kind":"VariableDefinition","variable":{"kind":"Variable","name":{"kind":"Name","value":"after"}},"type":{"kind":"NamedType","name":{"kind":"Name","value":"DateTime"}}},{"kind":"VariableDefinition","variable":{"kind":"Variable","name":{"kind":"Name","value":"limit"}},"type":{"kind":"NamedType","name":{"kind":"Name","value":"Int"}}},{"kind":"VariableDefinition","variable":{"kind":"Variable","name":{"kind":"Name","value":"onlyOptIn"}},"type":{"kind":"NamedType","name":{"kind":"Name","value":"Boolean"}}}],"selectionSet":{"kind":"SelectionSet","selections":[{"kind":"Field","name":{"kind":"Name","value":"exportActions"},"arguments":[{"kind":"Argument","name":{"kind":"Name","value":"orgName"},"value":{"kind":"Variable","name":{"kind":"Name","value":"org"}}},{"kind":"Argument","name":{"kind":"Name","value":"campaignId"},"value":{"kind":"Variable","name":{"kind":"Name","value":"campaignId"}}},{"kind":"Argument","name":{"kind":"Name","value":"campaignName"},"value":{"kind":"Variable","name":{"kind":"Name","value":"campaignName"}}},{"kind":"Argument","name":{"kind":"Name","value":"start"},"value":{"kind":"Variable","name":{"kind":"Name","value":"start"}}},{"kind":"Argument","name":{"kind":"Name","value":"after"},"value":{"kind":"Variable","name":{"kind":"Name","value":"after"}}},{"kind":"Argument","name":{"kind":"Name","value":"limit"},"value":{"kind":"Variable","name":{"kind":"Name","value":"limit"}}},{"kind":"Argument","name":{"kind":"Name","value":"onlyOptIn"},"value":{"kind":"Variable","name":{"kind":"Name","value":"onlyOptIn"}}}],"selectionSet":{"kind":"SelectionSet","selections":[{"kind":"Field","name":{"kind":"Name","value":"actionId"}},{"kind":"Field","name":{"kind":"Name","value":"actionType"}},{"kind":"Field","name":{"kind":"Name","value":"createdAt"}},{"kind":"Field","name":{"kind":"Name","value":"contact"},"selectionSet":{"kind":"SelectionSet","selections":[{"kind":"Field","name":{"kind":"Name","value":"contactRef"}},{"kind":"Field","name":{"kind":"Name","value":"payload"}},{"kind":"Field","name":{"kind":"Name","value":"nonce"}},{"kind":"Field","name":{"kind":"Name","value":"publicKey"},"selectionSet":{"kind":"SelectionSet","selections":[{"kind":"Field","name":{"kind":"Name","value":"id"}},{"kind":"Field","name":{"kind":"Name","value":"public"}}]}},{"kind":"Field","name":{"kind":"Name","value":"signKey"},"selectionSet":{"kind":"SelectionSet","selections":[{"kind":"Field","name":{"kind":"Name","value":"id"}},{"kind":"Field","name":{"kind":"Name","value":"public"}}]}}]}},{"kind":"Field","name":{"kind":"Name","value":"fields"},"selectionSet":{"kind":"SelectionSet","selections":[{"kind":"Field","name":{"kind":"Name","value":"key"}},{"kind":"Field","name":{"kind":"Name","value":"value"}}]}},{"kind":"Field","name":{"kind":"Name","value":"tracking"},"selectionSet":{"kind":"SelectionSet","selections":[{"kind":"Field","name":{"kind":"Name","value":"source"}},{"kind":"Field","name":{"kind":"Name","value":"medium"}},{"kind":"Field","name":{"kind":"Name","value":"campaign"}},{"kind":"Field","name":{"kind":"Name","value":"content"}}]}},{"kind":"Field","name":{"kind":"Name","value":"actionPage"},"selectionSet":{"kind":"SelectionSet","selections":[{"kind":"Field","name":{"kind":"Name","value":"id"}},{"kind":"Field","name":{"kind":"Name","value":"name"}}]}},{"kind":"Field","name":{"kind":"Name","value":"privacy"},"selectionSet":{"kind":"SelectionSet","selections":[{"kind":"Field","name":{"kind":"Name","value":"optIn"}}]}}]}}]}}]};
export const ExportOrgActionsDocument: DocumentNode<ExportOrgActions, ExportOrgActionsVariables> = {"kind":"Document","definitions":[{"kind":"OperationDefinition","operation":"query","name":{"kind":"Name","value":"ExportOrgActions"},"variableDefinitions":[{"kind":"VariableDefinition","variable":{"kind":"Variable","name":{"kind":"Name","value":"org"}},"type":{"kind":"NonNullType","type":{"kind":"NamedType","name":{"kind":"Name","value":"String"}}}},{"kind":"VariableDefinition","variable":{"kind":"Variable","name":{"kind":"Name","value":"start"}},"type":{"kind":"NamedType","name":{"kind":"Name","value":"Int"}}},{"kind":"VariableDefinition","variable":{"kind":"Variable","name":{"kind":"Name","value":"after"}},"type":{"kind":"NamedType","name":{"kind":"Name","value":"DateTime"}}},{"kind":"VariableDefinition","variable":{"kind":"Variable","name":{"kind":"Name","value":"limit"}},"type":{"kind":"NamedType","name":{"kind":"Name","value":"Int"}}},{"kind":"VariableDefinition","variable":{"kind":"Variable","name":{"kind":"Name","value":"onlyOptIn"}},"type":{"kind":"NamedType","name":{"kind":"Name","value":"Boolean"}}}],"selectionSet":{"kind":"SelectionSet","selections":[{"kind":"Field","name":{"kind":"Name","value":"exportActions"},"arguments":[{"kind":"Argument","name":{"kind":"Name","value":"orgName"},"value":{"kind":"Variable","name":{"kind":"Name","value":"org"}}},{"kind":"Argument","name":{"kind":"Name","value":"start"},"value":{"kind":"Variable","name":{"kind":"Name","value":"start"}}},{"kind":"Argument","name":{"kind":"Name","value":"after"},"value":{"kind":"Variable","name":{"kind":"Name","value":"after"}}},{"kind":"Argument","name":{"kind":"Name","value":"limit"},"value":{"kind":"Variable","name":{"kind":"Name","value":"limit"}}},{"kind":"Argument","name":{"kind":"Name","value":"onlyOptIn"},"value":{"kind":"Variable","name":{"kind":"Name","value":"onlyOptIn"}}}],"selectionSet":{"kind":"SelectionSet","selections":[{"kind":"Field","name":{"kind":"Name","value":"actionId"}},{"kind":"Field","name":{"kind":"Name","value":"actionType"}},{"kind":"Field","name":{"kind":"Name","value":"createdAt"}},{"kind":"Field","name":{"kind":"Name","value":"contact"},"selectionSet":{"kind":"SelectionSet","selections":[{"kind":"Field","name":{"kind":"Name","value":"contactRef"}},{"kind":"Field","name":{"kind":"Name","value":"payload"}},{"kind":"Field","name":{"kind":"Name","value":"nonce"}},{"kind":"Field","name":{"kind":"Name","value":"publicKey"},"selectionSet":{"kind":"SelectionSet","selections":[{"kind":"Field","name":{"kind":"Name","value":"id"}},{"kind":"Field","name":{"kind":"Name","value":"public"}}]}},{"kind":"Field","name":{"kind":"Name","value":"signKey"},"selectionSet":{"kind":"SelectionSet","selections":[{"kind":"Field","name":{"kind":"Name","value":"id"}},{"kind":"Field","name":{"kind":"Name","value":"public"}}]}}]}},{"kind":"Field","name":{"kind":"Name","value":"fields"},"selectionSet":{"kind":"SelectionSet","selections":[{"kind":"Field","name":{"kind":"Name","value":"key"}},{"kind":"Field","name":{"kind":"Name","value":"value"}}]}},{"kind":"Field","name":{"kind":"Name","value":"tracking"},"selectionSet":{"kind":"SelectionSet","selections":[{"kind":"Field","name":{"kind":"Name","value":"source"}},{"kind":"Field","name":{"kind":"Name","value":"medium"}},{"kind":"Field","name":{"kind":"Name","value":"campaign"}},{"kind":"Field","name":{"kind":"Name","value":"content"}}]}},{"kind":"Field","name":{"kind":"Name","value":"actionPage"},"selectionSet":{"kind":"SelectionSet","selections":[{"kind":"Field","name":{"kind":"Name","value":"id"}},{"kind":"Field","name":{"kind":"Name","value":"name"}}]}},{"kind":"Field","name":{"kind":"Name","value":"campaign"},"selectionSet":{"kind":"SelectionSet","selections":[{"kind":"Field","name":{"kind":"Name","value":"name"}},{"kind":"Field","name":{"kind":"Name","value":"externalId"}}]}},{"kind":"Field","name":{"kind":"Name","value":"privacy"},"selectionSet":{"kind":"SelectionSet","selections":[{"kind":"Field","name":{"kind":"Name","value":"optIn"}}]}}]}}]}}]};
export const UpdateActionPageDocument: DocumentNode<UpdateActionPage, UpdateActionPageVariables> = {"kind":"Document","definitions":[{"kind":"OperationDefinition","operation":"mutation","name":{"kind":"Name","value":"UpdateActionPage"},"variableDefinitions":[{"kind":"VariableDefinition","variable":{"kind":"Variable","name":{"kind":"Name","value":"id"}},"type":{"kind":"NonNullType","type":{"kind":"NamedType","name":{"kind":"Name","value":"Int"}}}},{"kind":"VariableDefinition","variable":{"kind":"Variable","name":{"kind":"Name","value":"actionPage"}},"type":{"kind":"NonNullType","type":{"kind":"NamedType","name":{"kind":"Name","value":"ActionPageInput"}}}}],"selectionSet":{"kind":"SelectionSet","selections":[{"kind":"Field","name":{"kind":"Name","value":"updateActionPage"},"arguments":[{"kind":"Argument","name":{"kind":"Name","value":"id"},"value":{"kind":"Variable","name":{"kind":"Name","value":"id"}}},{"kind":"Argument","name":{"kind":"Name","value":"input"},"value":{"kind":"Variable","name":{"kind":"Name","value":"actionPage"}}}],"selectionSet":{"kind":"SelectionSet","selections":[{"kind":"Field","name":{"kind":"Name","value":"id"}}]}}]}}]};
export const UpsertCampaignDocument: DocumentNode<UpsertCampaign, UpsertCampaignVariables> = {"kind":"Document","definitions":[{"kind":"OperationDefinition","operation":"mutation","name":{"kind":"Name","value":"UpsertCampaign"},"variableDefinitions":[{"kind":"VariableDefinition","variable":{"kind":"Variable","name":{"kind":"Name","value":"org"}},"type":{"kind":"NonNullType","type":{"kind":"NamedType","name":{"kind":"Name","value":"String"}}}},{"kind":"VariableDefinition","variable":{"kind":"Variable","name":{"kind":"Name","value":"campaign"}},"type":{"kind":"NonNullType","type":{"kind":"NamedType","name":{"kind":"Name","value":"CampaignInput"}}}}],"selectionSet":{"kind":"SelectionSet","selections":[{"kind":"Field","name":{"kind":"Name","value":"upsertCampaign"},"arguments":[{"kind":"Argument","name":{"kind":"Name","value":"orgName"},"value":{"kind":"Variable","name":{"kind":"Name","value":"org"}}},{"kind":"Argument","name":{"kind":"Name","value":"input"},"value":{"kind":"Variable","name":{"kind":"Name","value":"campaign"}}}],"selectionSet":{"kind":"SelectionSet","selections":[{"kind":"Field","name":{"kind":"Name","value":"id"}}]}}]}}]};
export const ListKeysDocument: DocumentNode<ListKeys, ListKeysVariables> = {"kind":"Document","definitions":[{"kind":"OperationDefinition","operation":"query","name":{"kind":"Name","value":"ListKeys"},"variableDefinitions":[{"kind":"VariableDefinition","variable":{"kind":"Variable","name":{"kind":"Name","value":"org"}},"type":{"kind":"NonNullType","type":{"kind":"NamedType","name":{"kind":"Name","value":"String"}}}}],"selectionSet":{"kind":"SelectionSet","selections":[{"kind":"Field","name":{"kind":"Name","value":"org"},"arguments":[{"kind":"Argument","name":{"kind":"Name","value":"name"},"value":{"kind":"Variable","name":{"kind":"Name","value":"org"}}}],"selectionSet":{"kind":"SelectionSet","selections":[{"kind":"Field","name":{"kind":"Name","value":"keys"},"selectionSet":{"kind":"SelectionSet","selections":[{"kind":"Field","name":{"kind":"Name","value":"id"}},{"kind":"Field","name":{"kind":"Name","value":"name"}},{"kind":"Field","name":{"kind":"Name","value":"public"}},{"kind":"Field","name":{"kind":"Name","value":"active"}},{"kind":"Field","name":{"kind":"Name","value":"expired"}},{"kind":"Field","name":{"kind":"Name","value":"expiredAt"}}]}}]}}]}}]};
export const GenerateKeyDocument: DocumentNode<GenerateKey, GenerateKeyVariables> = {"kind":"Document","definitions":[{"kind":"OperationDefinition","operation":"mutation","name":{"kind":"Name","value":"GenerateKey"},"variableDefinitions":[{"kind":"VariableDefinition","variable":{"kind":"Variable","name":{"kind":"Name","value":"org"}},"type":{"kind":"NonNullType","type":{"kind":"NamedType","name":{"kind":"Name","value":"String"}}}},{"kind":"VariableDefinition","variable":{"kind":"Variable","name":{"kind":"Name","value":"input"}},"type":{"kind":"NonNullType","type":{"kind":"NamedType","name":{"kind":"Name","value":"GenKeyInput"}}}}],"selectionSet":{"kind":"SelectionSet","selections":[{"kind":"Field","name":{"kind":"Name","value":"generateKey"},"arguments":[{"kind":"Argument","name":{"kind":"Name","value":"orgName"},"value":{"kind":"Variable","name":{"kind":"Name","value":"org"}}},{"kind":"Argument","name":{"kind":"Name","value":"input"},"value":{"kind":"Variable","name":{"kind":"Name","value":"input"}}}],"selectionSet":{"kind":"SelectionSet","selections":[{"kind":"Field","name":{"kind":"Name","value":"id"}},{"kind":"Field","name":{"kind":"Name","value":"name"}},{"kind":"Field","name":{"kind":"Name","value":"public"}},{"kind":"Field","name":{"kind":"Name","value":"private"}},{"kind":"Field","name":{"kind":"Name","value":"active"}},{"kind":"Field","name":{"kind":"Name","value":"expired"}},{"kind":"Field","name":{"kind":"Name","value":"expiredAt"}}]}}]}}]};
export const ActivateKeyDocument: DocumentNode<ActivateKey, ActivateKeyVariables> = {"kind":"Document","definitions":[{"kind":"OperationDefinition","operation":"mutation","name":{"kind":"Name","value":"ActivateKey"},"variableDefinitions":[{"kind":"VariableDefinition","variable":{"kind":"Variable","name":{"kind":"Name","value":"org"}},"type":{"kind":"NonNullType","type":{"kind":"NamedType","name":{"kind":"Name","value":"String"}}}},{"kind":"VariableDefinition","variable":{"kind":"Variable","name":{"kind":"Name","value":"id"}},"type":{"kind":"NonNullType","type":{"kind":"NamedType","name":{"kind":"Name","value":"Int"}}}}],"selectionSet":{"kind":"SelectionSet","selections":[{"kind":"Field","name":{"kind":"Name","value":"activateKey"},"arguments":[{"kind":"Argument","name":{"kind":"Name","value":"orgName"},"value":{"kind":"Variable","name":{"kind":"Name","value":"org"}}},{"kind":"Argument","name":{"kind":"Name","value":"id"},"value":{"kind":"Variable","name":{"kind":"Name","value":"id"}}}],"selectionSet":{"kind":"SelectionSet","selections":[{"kind":"Field","name":{"kind":"Name","value":"status"}}]}}]}}]};
export const AddOrgDocument: DocumentNode<AddOrg, AddOrgVariables> = {"kind":"Document","definitions":[{"kind":"OperationDefinition","operation":"mutation","name":{"kind":"Name","value":"AddOrg"},"variableDefinitions":[{"kind":"VariableDefinition","variable":{"kind":"Variable","name":{"kind":"Name","value":"org"}},"type":{"kind":"NonNullType","type":{"kind":"NamedType","name":{"kind":"Name","value":"OrgInput"}}}}],"selectionSet":{"kind":"SelectionSet","selections":[{"kind":"Field","name":{"kind":"Name","value":"addOrg"},"arguments":[{"kind":"Argument","name":{"kind":"Name","value":"input"},"value":{"kind":"Variable","name":{"kind":"Name","value":"org"}}}],"selectionSet":{"kind":"SelectionSet","selections":[{"kind":"Field","name":{"kind":"Name","value":"id"}},{"kind":"Field","name":{"kind":"Name","value":"name"}}]}}]}}]};
export const ActionPageUpsertedDocument: DocumentNode<ActionPageUpserted, ActionPageUpsertedVariables> = {"kind":"Document","definitions":[{"kind":"OperationDefinition","operation":"subscription","name":{"kind":"Name","value":"ActionPageUpserted"},"variableDefinitions":[{"kind":"VariableDefinition","variable":{"kind":"Variable","name":{"kind":"Name","value":"org"}},"type":{"kind":"NamedType","name":{"kind":"Name","value":"String"}}}],"selectionSet":{"kind":"SelectionSet","selections":[{"kind":"Field","name":{"kind":"Name","value":"actionPageUpserted"},"arguments":[{"kind":"Argument","name":{"kind":"Name","value":"orgName"},"value":{"kind":"Variable","name":{"kind":"Name","value":"org"}}}],"selectionSet":{"kind":"SelectionSet","selections":[{"kind":"Field","name":{"kind":"Name","value":"id"}},{"kind":"Field","name":{"kind":"Name","value":"name"}},{"kind":"Field","name":{"kind":"Name","value":"locale"}},{"kind":"Field","name":{"kind":"Name","value":"journey"}},{"kind":"Field","name":{"kind":"Name","value":"config"}},{"kind":"Field","name":{"kind":"Name","value":"campaign"},"selectionSet":{"kind":"SelectionSet","selections":[{"kind":"Field","name":{"kind":"Name","value":"id"}},{"kind":"Field","name":{"kind":"Name","value":"name"}},{"kind":"Field","name":{"kind":"Name","value":"title"}},{"kind":"Field","name":{"kind":"Name","value":"externalId"}}]}},{"kind":"Field","name":{"kind":"Name","value":"org"},"selectionSet":{"kind":"SelectionSet","selections":[{"kind":"Field","name":{"kind":"Name","value":"title"}}]}}]}}]}}]};
export const CurrentUserOrgsDocument: DocumentNode<CurrentUserOrgs, CurrentUserOrgsVariables> = {"kind":"Document","definitions":[{"kind":"OperationDefinition","operation":"query","name":{"kind":"Name","value":"CurrentUserOrgs"},"selectionSet":{"kind":"SelectionSet","selections":[{"kind":"Field","name":{"kind":"Name","value":"currentUser"},"selectionSet":{"kind":"SelectionSet","selections":[{"kind":"Field","name":{"kind":"Name","value":"id"}},{"kind":"Field","name":{"kind":"Name","value":"email"}},{"kind":"Field","name":{"kind":"Name","value":"roles"},"selectionSet":{"kind":"SelectionSet","selections":[{"kind":"Field","name":{"kind":"Name","value":"role"}},{"kind":"Field","name":{"kind":"Name","value":"org"},"selectionSet":{"kind":"SelectionSet","selections":[{"kind":"Field","name":{"kind":"Name","value":"id"}},{"kind":"Field","name":{"kind":"Name","value":"name"}},{"kind":"Field","name":{"kind":"Name","value":"title"}}]}}]}}]}}]}}]};
export const DashOrgOverviewDocument: DocumentNode<DashOrgOverview, DashOrgOverviewVariables> = {"kind":"Document","definitions":[{"kind":"OperationDefinition","operation":"query","name":{"kind":"Name","value":"DashOrgOverview"},"variableDefinitions":[{"kind":"VariableDefinition","variable":{"kind":"Variable","name":{"kind":"Name","value":"org"}},"type":{"kind":"NonNullType","type":{"kind":"NamedType","name":{"kind":"Name","value":"String"}}}}],"selectionSet":{"kind":"SelectionSet","selections":[{"kind":"Field","name":{"kind":"Name","value":"org"},"arguments":[{"kind":"Argument","name":{"kind":"Name","value":"name"},"value":{"kind":"Variable","name":{"kind":"Name","value":"org"}}}],"selectionSet":{"kind":"SelectionSet","selections":[{"kind":"Field","name":{"kind":"Name","value":"id"}},{"kind":"Field","name":{"kind":"Name","value":"name"}},{"kind":"Field","name":{"kind":"Name","value":"title"}},{"kind":"Field","name":{"kind":"Name","value":"campaigns"},"selectionSet":{"kind":"SelectionSet","selections":[{"kind":"Field","name":{"kind":"Name","value":"id"}},{"kind":"Field","name":{"kind":"Name","value":"externalId"}},{"kind":"Field","name":{"kind":"Name","value":"name"}},{"kind":"Field","name":{"kind":"Name","value":"title"}},{"kind":"Field","name":{"kind":"Name","value":"org"},"selectionSet":{"kind":"SelectionSet","selections":[{"kind":"Field","name":{"kind":"Name","value":"name"}},{"kind":"Field","name":{"kind":"Name","value":"title"}}]}},{"kind":"Field","name":{"kind":"Name","value":"config"}},{"kind":"Field","name":{"kind":"Name","value":"stats"},"selectionSet":{"kind":"SelectionSet","selections":[{"kind":"Field","name":{"kind":"Name","value":"supporterCount"}}]}}]}}]}}]}}]};
export type ListCampaignsVariables = Types.Exact<{
  org: Types.Scalars['String'];
}>;


export type ListCampaigns = { org: (
    { __typename?: 'Org' }
    & { campaigns: Array<(
      { __typename?: 'Campaign' }
      & Pick<Types.Campaign, 'id' | 'externalId' | 'name' | 'title'>
      & { org: (
        { __typename?: 'PublicOrg' }
        & Pick<Types.PublicOrg, 'name' | 'title'>
      ) }
    )> }
  ) };

export type GetCampaignVariables = Types.Exact<{
  org: Types.Scalars['String'];
  id: Types.Scalars['Int'];
}>;


export type GetCampaign = { org: (
    { __typename?: 'Org' }
    & { campaign: (
      { __typename?: 'Campaign' }
      & Pick<Types.Campaign, 'id' | 'externalId' | 'name' | 'title'>
      & { stats: (
        { __typename?: 'CampaignStats' }
        & Pick<Types.CampaignStats, 'supporterCount'>
        & { actionCount: Array<(
          { __typename?: 'ActionTypeCount' }
          & Pick<Types.ActionTypeCount, 'actionType' | 'count'>
        )> }
      ) }
    ) }
  ) };

export type GetActionPageVariables = Types.Exact<{
  org: Types.Scalars['String'];
  id?: Types.Maybe<Types.Scalars['Int']>;
  name?: Types.Maybe<Types.Scalars['String']>;
}>;


export type GetActionPage = { org: (
    { __typename?: 'Org' }
    & Pick<Types.Org, 'name' | 'title'>
    & { actionPage: (
      { __typename?: 'ActionPage' }
      & Pick<Types.ActionPage, 'id' | 'name' | 'locale' | 'extraSupporters' | 'thankYouTemplateRef' | 'journey' | 'config'>
      & { campaign?: Types.Maybe<(
        { __typename?: 'Campaign' }
        & Pick<Types.Campaign, 'id' | 'name' | 'title' | 'externalId'>
      )> }
    ) }
  ) };

export type ListActionPagesVariables = Types.Exact<{
  org: Types.Scalars['String'];
}>;


export type ListActionPages = { org: (
    { __typename?: 'Org' }
    & Pick<Types.Org, 'name' | 'title'>
    & { actionPages: Array<(
      { __typename?: 'ActionPage' }
      & Pick<Types.ActionPage, 'id' | 'name' | 'locale' | 'extraSupporters'>
      & { campaign?: Types.Maybe<(
        { __typename?: 'Campaign' }
        & Pick<Types.Campaign, 'name' | 'id' | 'externalId'>
      )> }
    )> }
  ) };

export type ListActionPagesByCampaignVariables = Types.Exact<{
  org: Types.Scalars['String'];
  campaignId: Types.Scalars['Int'];
}>;


export type ListActionPagesByCampaign = { org: (
    { __typename?: 'Org' }
    & Pick<Types.Org, 'name' | 'title'>
    & { actionPages: Array<(
      { __typename?: 'ActionPage' }
      & Pick<Types.ActionPage, 'id' | 'name' | 'locale' | 'extraSupporters'>
      & { campaign?: Types.Maybe<(
        { __typename?: 'Campaign' }
        & Pick<Types.Campaign, 'name' | 'id' | 'externalId'>
      )> }
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
    { __typename?: 'Action' }
    & Pick<Types.Action, 'actionId' | 'actionType' | 'createdAt'>
    & { contact: (
      { __typename?: 'Contact' }
      & Pick<Types.Contact, 'contactRef' | 'payload' | 'nonce'>
      & { publicKey?: Types.Maybe<(
        { __typename?: 'Key' }
        & Pick<Types.Key, 'id' | 'public'>
      )>, signKey?: Types.Maybe<(
        { __typename?: 'Key' }
        & Pick<Types.Key, 'id' | 'public'>
      )> }
    ), fields: Array<(
      { __typename?: 'CustomField' }
      & Pick<Types.CustomField, 'key' | 'value'>
    )>, tracking?: Types.Maybe<(
      { __typename?: 'Tracking' }
      & Pick<Types.Tracking, 'source' | 'medium' | 'campaign' | 'content'>
    )>, actionPage: (
      { __typename?: 'SimpleActionPage' }
      & Pick<Types.SimpleActionPage, 'id' | 'name'>
    ), privacy: (
      { __typename?: 'Consent' }
      & Pick<Types.Consent, 'optIn'>
    ) }
  )>> };

export type ExportOrgActionsVariables = Types.Exact<{
  org: Types.Scalars['String'];
  start?: Types.Maybe<Types.Scalars['Int']>;
  after?: Types.Maybe<Types.Scalars['DateTime']>;
  limit?: Types.Maybe<Types.Scalars['Int']>;
  onlyOptIn?: Types.Maybe<Types.Scalars['Boolean']>;
}>;


export type ExportOrgActions = { exportActions: Array<Types.Maybe<(
    { __typename?: 'Action' }
    & Pick<Types.Action, 'actionId' | 'actionType' | 'createdAt'>
    & { contact: (
      { __typename?: 'Contact' }
      & Pick<Types.Contact, 'contactRef' | 'payload' | 'nonce'>
      & { publicKey?: Types.Maybe<(
        { __typename?: 'Key' }
        & Pick<Types.Key, 'id' | 'public'>
      )>, signKey?: Types.Maybe<(
        { __typename?: 'Key' }
        & Pick<Types.Key, 'id' | 'public'>
      )> }
    ), fields: Array<(
      { __typename?: 'CustomField' }
      & Pick<Types.CustomField, 'key' | 'value'>
    )>, tracking?: Types.Maybe<(
      { __typename?: 'Tracking' }
      & Pick<Types.Tracking, 'source' | 'medium' | 'campaign' | 'content'>
    )>, actionPage: (
      { __typename?: 'SimpleActionPage' }
      & Pick<Types.SimpleActionPage, 'id' | 'name'>
    ), campaign: (
      { __typename?: 'ActionCampaign' }
      & Pick<Types.ActionCampaign, 'name' | 'externalId'>
    ), privacy: (
      { __typename?: 'Consent' }
      & Pick<Types.Consent, 'optIn'>
    ) }
  )>> };

export type UpdateActionPageVariables = Types.Exact<{
  id: Types.Scalars['Int'];
  actionPage: Types.ActionPageInput;
}>;


export type UpdateActionPage = { updateActionPage: (
    { __typename?: 'ActionPage' }
    & Pick<Types.ActionPage, 'id'>
  ) };

export type UpsertCampaignVariables = Types.Exact<{
  org: Types.Scalars['String'];
  campaign: Types.CampaignInput;
}>;


export type UpsertCampaign = { upsertCampaign: (
    { __typename?: 'Campaign' }
    & Pick<Types.Campaign, 'id'>
  ) };

export type ListKeysVariables = Types.Exact<{
  org: Types.Scalars['String'];
}>;


export type ListKeys = { org: (
    { __typename?: 'Org' }
    & { keys: Array<(
      { __typename?: 'Key' }
      & Pick<Types.Key, 'id' | 'name' | 'public' | 'active' | 'expired' | 'expiredAt'>
    )> }
  ) };

export type GenerateKeyVariables = Types.Exact<{
  org: Types.Scalars['String'];
  input: Types.GenKeyInput;
}>;


export type GenerateKey = { generateKey: (
    { __typename?: 'KeyWithPrivate' }
    & Pick<Types.KeyWithPrivate, 'id' | 'name' | 'public' | 'private' | 'active' | 'expired' | 'expiredAt'>
  ) };

export type ActivateKeyVariables = Types.Exact<{
  org: Types.Scalars['String'];
  id: Types.Scalars['Int'];
}>;


export type ActivateKey = { activateKey: (
    { __typename?: 'ActivateKeyResult' }
    & Pick<Types.ActivateKeyResult, 'status'>
  ) };

export type AddOrgVariables = Types.Exact<{
  org: Types.OrgInput;
}>;


export type AddOrg = { addOrg: (
    { __typename?: 'Org' }
    & Pick<Types.Org, 'id' | 'name'>
  ) };

export type ActionPageUpsertedVariables = Types.Exact<{
  org?: Types.Maybe<Types.Scalars['String']>;
}>;


export type ActionPageUpserted = { actionPageUpserted: (
    { __typename?: 'PublicActionPage' }
    & Pick<Types.PublicActionPage, 'id' | 'name' | 'locale' | 'journey' | 'config'>
    & { campaign: (
      { __typename?: 'Campaign' }
      & Pick<Types.Campaign, 'id' | 'name' | 'title' | 'externalId'>
    ), org: (
      { __typename?: 'PublicOrg' }
      & Pick<Types.PublicOrg, 'title'>
    ) }
  ) };

export type CurrentUserOrgsVariables = Types.Exact<{ [key: string]: never; }>;


export type CurrentUserOrgs = { currentUser: (
    { __typename?: 'User' }
    & Pick<Types.User, 'id' | 'email'>
    & { roles: Array<(
      { __typename?: 'UserRole' }
      & Pick<Types.UserRole, 'role'>
      & { org: (
        { __typename?: 'Org' }
        & Pick<Types.Org, 'id' | 'name' | 'title'>
      ) }
    )> }
  ) };

export type DashOrgOverviewVariables = Types.Exact<{
  org: Types.Scalars['String'];
}>;


export type DashOrgOverview = { org: (
    { __typename?: 'Org' }
    & Pick<Types.Org, 'id' | 'name' | 'title'>
    & { campaigns: Array<(
      { __typename?: 'Campaign' }
      & Pick<Types.Campaign, 'id' | 'externalId' | 'name' | 'title' | 'config'>
      & { org: (
        { __typename?: 'PublicOrg' }
        & Pick<Types.PublicOrg, 'name' | 'title'>
      ), stats: (
        { __typename?: 'CampaignStats' }
        & Pick<Types.CampaignStats, 'supporterCount'>
      ) }
    )> }
  ) };
