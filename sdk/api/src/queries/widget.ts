import * as Types from '../apiTypes';

import { TypedDocumentNode as DocumentNode } from '@graphql-typed-document-node/core';

export const GetActionPageDocument: DocumentNode<GetActionPage, GetActionPageVariables> = {"kind":"Document","definitions":[{"kind":"OperationDefinition","operation":"query","name":{"kind":"Name","value":"GetActionPage"},"variableDefinitions":[{"kind":"VariableDefinition","variable":{"kind":"Variable","name":{"kind":"Name","value":"name"}},"type":{"kind":"NamedType","name":{"kind":"Name","value":"String"}}},{"kind":"VariableDefinition","variable":{"kind":"Variable","name":{"kind":"Name","value":"id"}},"type":{"kind":"NamedType","name":{"kind":"Name","value":"Int"}}}],"selectionSet":{"kind":"SelectionSet","selections":[{"kind":"Field","name":{"kind":"Name","value":"actionPage"},"arguments":[{"kind":"Argument","name":{"kind":"Name","value":"name"},"value":{"kind":"Variable","name":{"kind":"Name","value":"name"}}},{"kind":"Argument","name":{"kind":"Name","value":"id"},"value":{"kind":"Variable","name":{"kind":"Name","value":"id"}}}],"selectionSet":{"kind":"SelectionSet","selections":[{"kind":"Field","name":{"kind":"Name","value":"id"}},{"kind":"Field","name":{"kind":"Name","value":"config"}},{"kind":"Field","name":{"kind":"Name","value":"locale"}},{"kind":"Field","name":{"kind":"Name","value":"journey"}},{"kind":"Field","name":{"kind":"Name","value":"name"}},{"kind":"Field","name":{"kind":"Name","value":"org"},"selectionSet":{"kind":"SelectionSet","selections":[{"kind":"Field","name":{"kind":"Name","value":"name"}},{"kind":"Field","name":{"kind":"Name","value":"title"}}]}},{"kind":"Field","name":{"kind":"Name","value":"campaign"},"selectionSet":{"kind":"SelectionSet","selections":[{"kind":"Field","name":{"kind":"Name","value":"id"}},{"kind":"Field","name":{"kind":"Name","value":"title"}},{"kind":"Field","name":{"kind":"Name","value":"name"}},{"kind":"Field","name":{"kind":"Name","value":"externalId"}},{"kind":"Field","name":{"kind":"Name","value":"stats"},"selectionSet":{"kind":"SelectionSet","selections":[{"kind":"Field","name":{"kind":"Name","value":"actionCount"},"selectionSet":{"kind":"SelectionSet","selections":[{"kind":"Field","name":{"kind":"Name","value":"actionType"}},{"kind":"Field","name":{"kind":"Name","value":"count"}}]}},{"kind":"Field","name":{"kind":"Name","value":"supporterCount"}}]}},{"kind":"Field","name":{"kind":"Name","value":"org"},"selectionSet":{"kind":"SelectionSet","selections":[{"kind":"Field","name":{"kind":"Name","value":"name"}},{"kind":"Field","name":{"kind":"Name","value":"title"}}]}}]}}]}}]}}]};
export const GetStatsDocument: DocumentNode<GetStats, GetStatsVariables> = {"kind":"Document","definitions":[{"kind":"OperationDefinition","operation":"query","name":{"kind":"Name","value":"GetStats"},"variableDefinitions":[{"kind":"VariableDefinition","variable":{"kind":"Variable","name":{"kind":"Name","value":"name"}},"type":{"kind":"NamedType","name":{"kind":"Name","value":"String"}}},{"kind":"VariableDefinition","variable":{"kind":"Variable","name":{"kind":"Name","value":"id"}},"type":{"kind":"NamedType","name":{"kind":"Name","value":"Int"}}}],"selectionSet":{"kind":"SelectionSet","selections":[{"kind":"Field","name":{"kind":"Name","value":"actionPage"},"arguments":[{"kind":"Argument","name":{"kind":"Name","value":"id"},"value":{"kind":"Variable","name":{"kind":"Name","value":"id"}}},{"kind":"Argument","name":{"kind":"Name","value":"name"},"value":{"kind":"Variable","name":{"kind":"Name","value":"name"}}}],"selectionSet":{"kind":"SelectionSet","selections":[{"kind":"Field","name":{"kind":"Name","value":"campaign"},"selectionSet":{"kind":"SelectionSet","selections":[{"kind":"Field","name":{"kind":"Name","value":"stats"},"selectionSet":{"kind":"SelectionSet","selections":[{"kind":"Field","name":{"kind":"Name","value":"supporterCount"}},{"kind":"Field","name":{"kind":"Name","value":"actionCount"},"selectionSet":{"kind":"SelectionSet","selections":[{"kind":"Field","name":{"kind":"Name","value":"actionType"}},{"kind":"Field","name":{"kind":"Name","value":"count"}}]}}]}}]}}]}}]}}]};
export const GetPublicResultDocument: DocumentNode<GetPublicResult, GetPublicResultVariables> = {"kind":"Document","definitions":[{"kind":"OperationDefinition","operation":"query","name":{"kind":"Name","value":"GetPublicResult"},"variableDefinitions":[{"kind":"VariableDefinition","variable":{"kind":"Variable","name":{"kind":"Name","value":"name"}},"type":{"kind":"NamedType","name":{"kind":"Name","value":"String"}}},{"kind":"VariableDefinition","variable":{"kind":"Variable","name":{"kind":"Name","value":"id"}},"type":{"kind":"NamedType","name":{"kind":"Name","value":"Int"}}},{"kind":"VariableDefinition","variable":{"kind":"Variable","name":{"kind":"Name","value":"actionType"}},"type":{"kind":"NonNullType","type":{"kind":"NamedType","name":{"kind":"Name","value":"String"}}}},{"kind":"VariableDefinition","variable":{"kind":"Variable","name":{"kind":"Name","value":"limit"}},"type":{"kind":"NonNullType","type":{"kind":"NamedType","name":{"kind":"Name","value":"Int"}}}}],"selectionSet":{"kind":"SelectionSet","selections":[{"kind":"Field","name":{"kind":"Name","value":"actionPage"},"arguments":[{"kind":"Argument","name":{"kind":"Name","value":"name"},"value":{"kind":"Variable","name":{"kind":"Name","value":"name"}}},{"kind":"Argument","name":{"kind":"Name","value":"id"},"value":{"kind":"Variable","name":{"kind":"Name","value":"id"}}}],"selectionSet":{"kind":"SelectionSet","selections":[{"kind":"Field","name":{"kind":"Name","value":"config"}},{"kind":"Field","name":{"kind":"Name","value":"locale"}},{"kind":"Field","name":{"kind":"Name","value":"journey"}},{"kind":"Field","name":{"kind":"Name","value":"name"}},{"kind":"Field","name":{"kind":"Name","value":"campaign"},"selectionSet":{"kind":"SelectionSet","selections":[{"kind":"Field","name":{"kind":"Name","value":"title"}},{"kind":"Field","name":{"kind":"Name","value":"name"}},{"kind":"Field","name":{"kind":"Name","value":"externalId"}},{"kind":"Field","name":{"kind":"Name","value":"stats"},"selectionSet":{"kind":"SelectionSet","selections":[{"kind":"Field","name":{"kind":"Name","value":"actionCount"},"selectionSet":{"kind":"SelectionSet","selections":[{"kind":"Field","name":{"kind":"Name","value":"actionType"}},{"kind":"Field","name":{"kind":"Name","value":"count"}}]}},{"kind":"Field","name":{"kind":"Name","value":"supporterCount"}}]}},{"kind":"Field","name":{"kind":"Name","value":"actions"},"arguments":[{"kind":"Argument","name":{"kind":"Name","value":"actionType"},"value":{"kind":"Variable","name":{"kind":"Name","value":"actionType"}}},{"kind":"Argument","name":{"kind":"Name","value":"limit"},"value":{"kind":"Variable","name":{"kind":"Name","value":"limit"}}}],"selectionSet":{"kind":"SelectionSet","selections":[{"kind":"Field","name":{"kind":"Name","value":"fieldKeys"}},{"kind":"Field","name":{"kind":"Name","value":"list"},"selectionSet":{"kind":"SelectionSet","selections":[{"kind":"Field","name":{"kind":"Name","value":"actionType"}},{"kind":"Field","name":{"kind":"Name","value":"insertedAt"}},{"kind":"Field","name":{"kind":"Name","value":"fields"},"selectionSet":{"kind":"SelectionSet","selections":[{"kind":"Field","name":{"kind":"Name","value":"key"}},{"kind":"Field","name":{"kind":"Name","value":"value"}}]}}]}}]}},{"kind":"Field","name":{"kind":"Name","value":"org"},"selectionSet":{"kind":"SelectionSet","selections":[{"kind":"Field","name":{"kind":"Name","value":"title"}}]}}]}}]}}]}}]};
export const AddActionContactDocument: DocumentNode<AddActionContact, AddActionContactVariables> = {"kind":"Document","definitions":[{"kind":"OperationDefinition","operation":"mutation","name":{"kind":"Name","value":"AddActionContact"},"variableDefinitions":[{"kind":"VariableDefinition","variable":{"kind":"Variable","name":{"kind":"Name","value":"id"}},"type":{"kind":"NonNullType","type":{"kind":"NamedType","name":{"kind":"Name","value":"Int"}}}},{"kind":"VariableDefinition","variable":{"kind":"Variable","name":{"kind":"Name","value":"contact"}},"type":{"kind":"NonNullType","type":{"kind":"NamedType","name":{"kind":"Name","value":"ContactInput"}}}},{"kind":"VariableDefinition","variable":{"kind":"Variable","name":{"kind":"Name","value":"contactRef"}},"type":{"kind":"NamedType","name":{"kind":"Name","value":"ID"}}},{"kind":"VariableDefinition","variable":{"kind":"Variable","name":{"kind":"Name","value":"actionType"}},"type":{"kind":"NonNullType","type":{"kind":"NamedType","name":{"kind":"Name","value":"String"}}}},{"kind":"VariableDefinition","variable":{"kind":"Variable","name":{"kind":"Name","value":"fields"}},"type":{"kind":"ListType","type":{"kind":"NonNullType","type":{"kind":"NamedType","name":{"kind":"Name","value":"CustomFieldInput"}}}}},{"kind":"VariableDefinition","variable":{"kind":"Variable","name":{"kind":"Name","value":"privacy"}},"type":{"kind":"NonNullType","type":{"kind":"NamedType","name":{"kind":"Name","value":"ConsentInput"}}}},{"kind":"VariableDefinition","variable":{"kind":"Variable","name":{"kind":"Name","value":"tracking"}},"type":{"kind":"NamedType","name":{"kind":"Name","value":"TrackingInput"}}}],"selectionSet":{"kind":"SelectionSet","selections":[{"kind":"Field","name":{"kind":"Name","value":"addActionContact"},"arguments":[{"kind":"Argument","name":{"kind":"Name","value":"actionPageId"},"value":{"kind":"Variable","name":{"kind":"Name","value":"id"}}},{"kind":"Argument","name":{"kind":"Name","value":"contact"},"value":{"kind":"Variable","name":{"kind":"Name","value":"contact"}}},{"kind":"Argument","name":{"kind":"Name","value":"contactRef"},"value":{"kind":"Variable","name":{"kind":"Name","value":"contactRef"}}},{"kind":"Argument","name":{"kind":"Name","value":"action"},"value":{"kind":"ObjectValue","fields":[{"kind":"ObjectField","name":{"kind":"Name","value":"actionType"},"value":{"kind":"Variable","name":{"kind":"Name","value":"actionType"}}},{"kind":"ObjectField","name":{"kind":"Name","value":"fields"},"value":{"kind":"Variable","name":{"kind":"Name","value":"fields"}}}]}},{"kind":"Argument","name":{"kind":"Name","value":"privacy"},"value":{"kind":"Variable","name":{"kind":"Name","value":"privacy"}}},{"kind":"Argument","name":{"kind":"Name","value":"tracking"},"value":{"kind":"Variable","name":{"kind":"Name","value":"tracking"}}}],"selectionSet":{"kind":"SelectionSet","selections":[{"kind":"Field","name":{"kind":"Name","value":"contactRef"}},{"kind":"Field","name":{"kind":"Name","value":"firstName"}}]}}]}}]};
export const AddActionDocument: DocumentNode<AddAction, AddActionVariables> = {"kind":"Document","definitions":[{"kind":"OperationDefinition","operation":"mutation","name":{"kind":"Name","value":"AddAction"},"variableDefinitions":[{"kind":"VariableDefinition","variable":{"kind":"Variable","name":{"kind":"Name","value":"id"}},"type":{"kind":"NonNullType","type":{"kind":"NamedType","name":{"kind":"Name","value":"Int"}}}},{"kind":"VariableDefinition","variable":{"kind":"Variable","name":{"kind":"Name","value":"contactRef"}},"type":{"kind":"NonNullType","type":{"kind":"NamedType","name":{"kind":"Name","value":"ID"}}}},{"kind":"VariableDefinition","variable":{"kind":"Variable","name":{"kind":"Name","value":"actionType"}},"type":{"kind":"NonNullType","type":{"kind":"NamedType","name":{"kind":"Name","value":"String"}}}},{"kind":"VariableDefinition","variable":{"kind":"Variable","name":{"kind":"Name","value":"fields"}},"type":{"kind":"ListType","type":{"kind":"NonNullType","type":{"kind":"NamedType","name":{"kind":"Name","value":"CustomFieldInput"}}}}},{"kind":"VariableDefinition","variable":{"kind":"Variable","name":{"kind":"Name","value":"tracking"}},"type":{"kind":"NamedType","name":{"kind":"Name","value":"TrackingInput"}}}],"selectionSet":{"kind":"SelectionSet","selections":[{"kind":"Field","name":{"kind":"Name","value":"addAction"},"arguments":[{"kind":"Argument","name":{"kind":"Name","value":"actionPageId"},"value":{"kind":"Variable","name":{"kind":"Name","value":"id"}}},{"kind":"Argument","name":{"kind":"Name","value":"contactRef"},"value":{"kind":"Variable","name":{"kind":"Name","value":"contactRef"}}},{"kind":"Argument","name":{"kind":"Name","value":"action"},"value":{"kind":"ObjectValue","fields":[{"kind":"ObjectField","name":{"kind":"Name","value":"actionType"},"value":{"kind":"Variable","name":{"kind":"Name","value":"actionType"}}},{"kind":"ObjectField","name":{"kind":"Name","value":"fields"},"value":{"kind":"Variable","name":{"kind":"Name","value":"fields"}}}]}},{"kind":"Argument","name":{"kind":"Name","value":"tracking"},"value":{"kind":"Variable","name":{"kind":"Name","value":"tracking"}}}],"selectionSet":{"kind":"SelectionSet","selections":[{"kind":"Field","name":{"kind":"Name","value":"contactRef"}},{"kind":"Field","name":{"kind":"Name","value":"firstName"}}]}}]}}]};
export type GetActionPageVariables = Types.Exact<{
  name?: Types.Maybe<Types.Scalars['String']>;
  id?: Types.Maybe<Types.Scalars['Int']>;
}>;


export type GetActionPage = { actionPage: (
    Pick<Types.PublicActionPage, 'id' | 'config' | 'locale' | 'journey' | 'name'>
    & { org: Pick<Types.PublicOrg, 'name' | 'title'>, campaign: (
      Pick<Types.Campaign, 'id' | 'title' | 'name' | 'externalId'>
      & { stats: (
        Pick<Types.CampaignStats, 'supporterCount'>
        & { actionCount: Array<Pick<Types.ActionTypeCount, 'actionType' | 'count'>> }
      ), org: Pick<Types.PublicOrg, 'name' | 'title'> }
    ) }
  ) };

export type GetStatsVariables = Types.Exact<{
  name?: Types.Maybe<Types.Scalars['String']>;
  id?: Types.Maybe<Types.Scalars['Int']>;
}>;


export type GetStats = { actionPage: { campaign: { stats: (
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
    Pick<Types.PublicActionPage, 'config' | 'locale' | 'journey' | 'name'>
    & { campaign: (
      Pick<Types.Campaign, 'title' | 'name' | 'externalId'>
      & { stats: (
        Pick<Types.CampaignStats, 'supporterCount'>
        & { actionCount: Array<Pick<Types.ActionTypeCount, 'actionType' | 'count'>> }
      ), actions: (
        Pick<Types.PublicActionsResult, 'fieldKeys'>
        & { list: Types.Maybe<Array<Types.Maybe<(
          Pick<Types.ActionCustomFields, 'actionType' | 'insertedAt'>
          & { fields: Array<Pick<Types.CustomField, 'key' | 'value'>> }
        )>>> }
      ), org: Pick<Types.PublicOrg, 'title'> }
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
