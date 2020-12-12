import * as Types from '../types';

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


export type GetActionPage = (
  { __typename?: 'RootQueryType' }
  & { actionPage?: Types.Maybe<(
    { __typename?: 'PublicActionPage' }
    & Pick<Types.PublicActionPage, 'id' | 'config' | 'locale' | 'journey' | 'name'>
    & { org?: Types.Maybe<(
      { __typename?: 'PublicOrg' }
      & Pick<Types.PublicOrg, 'name' | 'title'>
    )>, campaign?: Types.Maybe<(
      { __typename?: 'Campaign' }
      & Pick<Types.Campaign, 'id' | 'title' | 'name' | 'externalId'>
      & { stats?: Types.Maybe<(
        { __typename?: 'CampaignStats' }
        & Pick<Types.CampaignStats, 'supporterCount'>
        & { actionCount?: Types.Maybe<Array<(
          { __typename?: 'ActionTypeCount' }
          & Pick<Types.ActionTypeCount, 'actionType' | 'count'>
        )>> }
      )>, org?: Types.Maybe<(
        { __typename?: 'PublicOrg' }
        & Pick<Types.PublicOrg, 'name' | 'title'>
      )> }
    )> }
  )> }
);

export type GetStatsVariables = Types.Exact<{
  name?: Types.Maybe<Types.Scalars['String']>;
  id?: Types.Maybe<Types.Scalars['Int']>;
}>;


export type GetStats = (
  { __typename?: 'RootQueryType' }
  & { actionPage?: Types.Maybe<(
    { __typename?: 'PublicActionPage' }
    & { campaign?: Types.Maybe<(
      { __typename?: 'Campaign' }
      & { stats?: Types.Maybe<(
        { __typename?: 'CampaignStats' }
        & Pick<Types.CampaignStats, 'supporterCount'>
        & { actionCount?: Types.Maybe<Array<(
          { __typename?: 'ActionTypeCount' }
          & Pick<Types.ActionTypeCount, 'actionType' | 'count'>
        )>> }
      )> }
    )> }
  )> }
);

export type GetPublicResultVariables = Types.Exact<{
  name?: Types.Maybe<Types.Scalars['String']>;
  id?: Types.Maybe<Types.Scalars['Int']>;
  actionType: Types.Scalars['String'];
  limit: Types.Scalars['Int'];
}>;


export type GetPublicResult = (
  { __typename?: 'RootQueryType' }
  & { actionPage?: Types.Maybe<(
    { __typename?: 'PublicActionPage' }
    & Pick<Types.PublicActionPage, 'config' | 'locale' | 'journey' | 'name'>
    & { campaign?: Types.Maybe<(
      { __typename?: 'Campaign' }
      & Pick<Types.Campaign, 'title' | 'name' | 'externalId'>
      & { stats?: Types.Maybe<(
        { __typename?: 'CampaignStats' }
        & Pick<Types.CampaignStats, 'supporterCount'>
        & { actionCount?: Types.Maybe<Array<(
          { __typename?: 'ActionTypeCount' }
          & Pick<Types.ActionTypeCount, 'actionType' | 'count'>
        )>> }
      )>, actions?: Types.Maybe<(
        { __typename?: 'PublicActionsResult' }
        & Pick<Types.PublicActionsResult, 'fieldKeys'>
        & { list?: Types.Maybe<Array<Types.Maybe<(
          { __typename?: 'ActionCustomFields' }
          & Pick<Types.ActionCustomFields, 'actionType' | 'insertedAt'>
          & { fields?: Types.Maybe<Array<(
            { __typename?: 'CustomField' }
            & Pick<Types.CustomField, 'key' | 'value'>
          )>> }
        )>>> }
      )>, org?: Types.Maybe<(
        { __typename?: 'PublicOrg' }
        & Pick<Types.PublicOrg, 'title'>
      )> }
    )> }
  )> }
);

export type AddActionContactVariables = Types.Exact<{
  id: Types.Scalars['Int'];
  contact: Types.ContactInput;
  contactRef?: Types.Maybe<Types.Scalars['ID']>;
  actionType: Types.Scalars['String'];
  fields?: Types.Maybe<Array<Types.CustomFieldInput>>;
  privacy: Types.ConsentInput;
  tracking?: Types.Maybe<Types.TrackingInput>;
}>;


export type AddActionContact = (
  { __typename?: 'RootMutationType' }
  & { addActionContact?: Types.Maybe<(
    { __typename?: 'ContactReference' }
    & Pick<Types.ContactReference, 'contactRef' | 'firstName'>
  )> }
);

export type AddActionVariables = Types.Exact<{
  id: Types.Scalars['Int'];
  contactRef: Types.Scalars['ID'];
  actionType: Types.Scalars['String'];
  fields?: Types.Maybe<Array<Types.CustomFieldInput>>;
  tracking?: Types.Maybe<Types.TrackingInput>;
}>;


export type AddAction = (
  { __typename?: 'RootMutationType' }
  & { addAction?: Types.Maybe<(
    { __typename?: 'ContactReference' }
    & Pick<Types.ContactReference, 'contactRef' | 'firstName'>
  )> }
);
