import * as Types from 'types';

import { TypedDocumentNode as DocumentNode } from '@graphql-typed-document-node/core';

export const GetActionPageDocument: DocumentNode<GetActionPage, GetActionPageVariables> = {"kind":"Document","definitions":[{"kind":"OperationDefinition","operation":"query","name":{"kind":"Name","value":"GetActionPage"},"variableDefinitions":[{"kind":"VariableDefinition","variable":{"kind":"Variable","name":{"kind":"Name","value":"name"}},"type":{"kind":"NamedType","name":{"kind":"Name","value":"String"}},"directives":[]},{"kind":"VariableDefinition","variable":{"kind":"Variable","name":{"kind":"Name","value":"id"}},"type":{"kind":"NamedType","name":{"kind":"Name","value":"Int"}},"directives":[]}],"directives":[],"selectionSet":{"kind":"SelectionSet","selections":[{"kind":"Field","name":{"kind":"Name","value":"actionPage"},"arguments":[{"kind":"Argument","name":{"kind":"Name","value":"name"},"value":{"kind":"Variable","name":{"kind":"Name","value":"name"}}},{"kind":"Argument","name":{"kind":"Name","value":"id"},"value":{"kind":"Variable","name":{"kind":"Name","value":"id"}}}],"directives":[],"selectionSet":{"kind":"SelectionSet","selections":[{"kind":"Field","name":{"kind":"Name","value":"id"},"arguments":[],"directives":[]},{"kind":"Field","name":{"kind":"Name","value":"config"},"arguments":[],"directives":[]},{"kind":"Field","name":{"kind":"Name","value":"locale"},"arguments":[],"directives":[]},{"kind":"Field","name":{"kind":"Name","value":"journey"},"arguments":[],"directives":[]},{"kind":"Field","name":{"kind":"Name","value":"name"},"arguments":[],"directives":[]},{"kind":"Field","name":{"kind":"Name","value":"org"},"arguments":[],"directives":[],"selectionSet":{"kind":"SelectionSet","selections":[{"kind":"Field","name":{"kind":"Name","value":"title"},"arguments":[],"directives":[]}]}},{"kind":"Field","name":{"kind":"Name","value":"campaign"},"arguments":[],"directives":[],"selectionSet":{"kind":"SelectionSet","selections":[{"kind":"Field","name":{"kind":"Name","value":"title"},"arguments":[],"directives":[]},{"kind":"Field","name":{"kind":"Name","value":"name"},"arguments":[],"directives":[]},{"kind":"Field","name":{"kind":"Name","value":"externalId"},"arguments":[],"directives":[]},{"kind":"Field","name":{"kind":"Name","value":"stats"},"arguments":[],"directives":[],"selectionSet":{"kind":"SelectionSet","selections":[{"kind":"Field","name":{"kind":"Name","value":"actionCount"},"arguments":[],"directives":[],"selectionSet":{"kind":"SelectionSet","selections":[{"kind":"Field","name":{"kind":"Name","value":"actionType"},"arguments":[],"directives":[]},{"kind":"Field","name":{"kind":"Name","value":"count"},"arguments":[],"directives":[]}]}},{"kind":"Field","name":{"kind":"Name","value":"supporterCount"},"arguments":[],"directives":[]}]}},{"kind":"Field","name":{"kind":"Name","value":"org"},"arguments":[],"directives":[],"selectionSet":{"kind":"SelectionSet","selections":[{"kind":"Field","name":{"kind":"Name","value":"title"},"arguments":[],"directives":[]}]}}]}}]}}]}}]};
export const GetStatsDocument: DocumentNode<GetStats, GetStatsVariables> = {"kind":"Document","definitions":[{"kind":"OperationDefinition","operation":"query","name":{"kind":"Name","value":"GetStats"},"variableDefinitions":[{"kind":"VariableDefinition","variable":{"kind":"Variable","name":{"kind":"Name","value":"name"}},"type":{"kind":"NamedType","name":{"kind":"Name","value":"String"}},"directives":[]},{"kind":"VariableDefinition","variable":{"kind":"Variable","name":{"kind":"Name","value":"id"}},"type":{"kind":"NamedType","name":{"kind":"Name","value":"Int"}},"directives":[]}],"directives":[],"selectionSet":{"kind":"SelectionSet","selections":[{"kind":"Field","name":{"kind":"Name","value":"actionPage"},"arguments":[{"kind":"Argument","name":{"kind":"Name","value":"id"},"value":{"kind":"Variable","name":{"kind":"Name","value":"id"}}},{"kind":"Argument","name":{"kind":"Name","value":"name"},"value":{"kind":"Variable","name":{"kind":"Name","value":"name"}}}],"directives":[],"selectionSet":{"kind":"SelectionSet","selections":[{"kind":"Field","name":{"kind":"Name","value":"campaign"},"arguments":[],"directives":[],"selectionSet":{"kind":"SelectionSet","selections":[{"kind":"Field","name":{"kind":"Name","value":"stats"},"arguments":[],"directives":[],"selectionSet":{"kind":"SelectionSet","selections":[{"kind":"Field","name":{"kind":"Name","value":"supporterCount"},"arguments":[],"directives":[]},{"kind":"Field","name":{"kind":"Name","value":"actionCount"},"arguments":[],"directives":[],"selectionSet":{"kind":"SelectionSet","selections":[{"kind":"Field","name":{"kind":"Name","value":"actionType"},"arguments":[],"directives":[]},{"kind":"Field","name":{"kind":"Name","value":"count"},"arguments":[],"directives":[]}]}}]}}]}}]}}]}}]};
export const GetPublicResultDocument: DocumentNode<GetPublicResult, GetPublicResultVariables> = {"kind":"Document","definitions":[{"kind":"OperationDefinition","operation":"query","name":{"kind":"Name","value":"GetPublicResult"},"variableDefinitions":[{"kind":"VariableDefinition","variable":{"kind":"Variable","name":{"kind":"Name","value":"name"}},"type":{"kind":"NamedType","name":{"kind":"Name","value":"String"}},"directives":[]},{"kind":"VariableDefinition","variable":{"kind":"Variable","name":{"kind":"Name","value":"id"}},"type":{"kind":"NamedType","name":{"kind":"Name","value":"Int"}},"directives":[]},{"kind":"VariableDefinition","variable":{"kind":"Variable","name":{"kind":"Name","value":"actionType"}},"type":{"kind":"NonNullType","type":{"kind":"NamedType","name":{"kind":"Name","value":"String"}}},"directives":[]}],"directives":[],"selectionSet":{"kind":"SelectionSet","selections":[{"kind":"Field","name":{"kind":"Name","value":"actionPage"},"arguments":[{"kind":"Argument","name":{"kind":"Name","value":"name"},"value":{"kind":"Variable","name":{"kind":"Name","value":"name"}}},{"kind":"Argument","name":{"kind":"Name","value":"id"},"value":{"kind":"Variable","name":{"kind":"Name","value":"id"}}}],"directives":[],"selectionSet":{"kind":"SelectionSet","selections":[{"kind":"Field","name":{"kind":"Name","value":"config"},"arguments":[],"directives":[]},{"kind":"Field","name":{"kind":"Name","value":"locale"},"arguments":[],"directives":[]},{"kind":"Field","name":{"kind":"Name","value":"journey"},"arguments":[],"directives":[]},{"kind":"Field","name":{"kind":"Name","value":"name"},"arguments":[],"directives":[]},{"kind":"Field","name":{"kind":"Name","value":"campaign"},"arguments":[],"directives":[],"selectionSet":{"kind":"SelectionSet","selections":[{"kind":"Field","name":{"kind":"Name","value":"title"},"arguments":[],"directives":[]},{"kind":"Field","name":{"kind":"Name","value":"name"},"arguments":[],"directives":[]},{"kind":"Field","name":{"kind":"Name","value":"externalId"},"arguments":[],"directives":[]},{"kind":"Field","name":{"kind":"Name","value":"stats"},"arguments":[],"directives":[],"selectionSet":{"kind":"SelectionSet","selections":[{"kind":"Field","name":{"kind":"Name","value":"actionCount"},"arguments":[],"directives":[],"selectionSet":{"kind":"SelectionSet","selections":[{"kind":"Field","name":{"kind":"Name","value":"actionType"},"arguments":[],"directives":[]},{"kind":"Field","name":{"kind":"Name","value":"count"},"arguments":[],"directives":[]}]}},{"kind":"Field","name":{"kind":"Name","value":"supporterCount"},"arguments":[],"directives":[]}]}},{"kind":"Field","name":{"kind":"Name","value":"actions"},"arguments":[{"kind":"Argument","name":{"kind":"Name","value":"actionType"},"value":{"kind":"Variable","name":{"kind":"Name","value":"actionType"}}}],"directives":[],"selectionSet":{"kind":"SelectionSet","selections":[{"kind":"Field","name":{"kind":"Name","value":"fieldKeys"},"arguments":[],"directives":[]},{"kind":"Field","name":{"kind":"Name","value":"list"},"arguments":[],"directives":[],"selectionSet":{"kind":"SelectionSet","selections":[{"kind":"Field","name":{"kind":"Name","value":"actionType"},"arguments":[],"directives":[]},{"kind":"Field","name":{"kind":"Name","value":"insertedAt"},"arguments":[],"directives":[]},{"kind":"Field","name":{"kind":"Name","value":"fields"},"arguments":[],"directives":[],"selectionSet":{"kind":"SelectionSet","selections":[{"kind":"Field","name":{"kind":"Name","value":"key"},"arguments":[],"directives":[]},{"kind":"Field","name":{"kind":"Name","value":"value"},"arguments":[],"directives":[]}]}}]}}]}},{"kind":"Field","name":{"kind":"Name","value":"org"},"arguments":[],"directives":[],"selectionSet":{"kind":"SelectionSet","selections":[{"kind":"Field","name":{"kind":"Name","value":"title"},"arguments":[],"directives":[]}]}}]}}]}}]}}]};
export const AddActionContactDocument: DocumentNode<AddActionContact, AddActionContactVariables> = {"kind":"Document","definitions":[{"kind":"OperationDefinition","operation":"mutation","name":{"kind":"Name","value":"AddActionContact"},"variableDefinitions":[{"kind":"VariableDefinition","variable":{"kind":"Variable","name":{"kind":"Name","value":"id"}},"type":{"kind":"NonNullType","type":{"kind":"NamedType","name":{"kind":"Name","value":"Int"}}},"directives":[]},{"kind":"VariableDefinition","variable":{"kind":"Variable","name":{"kind":"Name","value":"contact"}},"type":{"kind":"NonNullType","type":{"kind":"NamedType","name":{"kind":"Name","value":"ContactInput"}}},"directives":[]},{"kind":"VariableDefinition","variable":{"kind":"Variable","name":{"kind":"Name","value":"contactRef"}},"type":{"kind":"NamedType","name":{"kind":"Name","value":"ID"}},"directives":[]},{"kind":"VariableDefinition","variable":{"kind":"Variable","name":{"kind":"Name","value":"actionType"}},"type":{"kind":"NonNullType","type":{"kind":"NamedType","name":{"kind":"Name","value":"String"}}},"directives":[]},{"kind":"VariableDefinition","variable":{"kind":"Variable","name":{"kind":"Name","value":"fields"}},"type":{"kind":"ListType","type":{"kind":"NonNullType","type":{"kind":"NamedType","name":{"kind":"Name","value":"CustomFieldInput"}}}},"directives":[]},{"kind":"VariableDefinition","variable":{"kind":"Variable","name":{"kind":"Name","value":"privacy"}},"type":{"kind":"NonNullType","type":{"kind":"NamedType","name":{"kind":"Name","value":"ConsentInput"}}},"directives":[]},{"kind":"VariableDefinition","variable":{"kind":"Variable","name":{"kind":"Name","value":"tracking"}},"type":{"kind":"NamedType","name":{"kind":"Name","value":"TrackingInput"}},"directives":[]}],"directives":[],"selectionSet":{"kind":"SelectionSet","selections":[{"kind":"Field","name":{"kind":"Name","value":"addActionContact"},"arguments":[{"kind":"Argument","name":{"kind":"Name","value":"actionPageId"},"value":{"kind":"Variable","name":{"kind":"Name","value":"id"}}},{"kind":"Argument","name":{"kind":"Name","value":"contact"},"value":{"kind":"Variable","name":{"kind":"Name","value":"contact"}}},{"kind":"Argument","name":{"kind":"Name","value":"contactRef"},"value":{"kind":"Variable","name":{"kind":"Name","value":"contactRef"}}},{"kind":"Argument","name":{"kind":"Name","value":"action"},"value":{"kind":"ObjectValue","fields":[{"kind":"ObjectField","name":{"kind":"Name","value":"actionType"},"value":{"kind":"Variable","name":{"kind":"Name","value":"actionType"}}},{"kind":"ObjectField","name":{"kind":"Name","value":"fields"},"value":{"kind":"Variable","name":{"kind":"Name","value":"fields"}}}]}},{"kind":"Argument","name":{"kind":"Name","value":"privacy"},"value":{"kind":"Variable","name":{"kind":"Name","value":"privacy"}}},{"kind":"Argument","name":{"kind":"Name","value":"tracking"},"value":{"kind":"Variable","name":{"kind":"Name","value":"tracking"}}}],"directives":[],"selectionSet":{"kind":"SelectionSet","selections":[{"kind":"Field","name":{"kind":"Name","value":"contactRef"},"arguments":[],"directives":[]},{"kind":"Field","name":{"kind":"Name","value":"firstName"},"arguments":[],"directives":[]}]}}]}}]};
export const AddActionDocument: DocumentNode<AddAction, AddActionVariables> = {"kind":"Document","definitions":[{"kind":"OperationDefinition","operation":"mutation","name":{"kind":"Name","value":"AddAction"},"variableDefinitions":[{"kind":"VariableDefinition","variable":{"kind":"Variable","name":{"kind":"Name","value":"id"}},"type":{"kind":"NonNullType","type":{"kind":"NamedType","name":{"kind":"Name","value":"Int"}}},"directives":[]},{"kind":"VariableDefinition","variable":{"kind":"Variable","name":{"kind":"Name","value":"contactRef"}},"type":{"kind":"NonNullType","type":{"kind":"NamedType","name":{"kind":"Name","value":"ID"}}},"directives":[]},{"kind":"VariableDefinition","variable":{"kind":"Variable","name":{"kind":"Name","value":"actionType"}},"type":{"kind":"NonNullType","type":{"kind":"NamedType","name":{"kind":"Name","value":"String"}}},"directives":[]},{"kind":"VariableDefinition","variable":{"kind":"Variable","name":{"kind":"Name","value":"fields"}},"type":{"kind":"ListType","type":{"kind":"NonNullType","type":{"kind":"NamedType","name":{"kind":"Name","value":"CustomFieldInput"}}}},"directives":[]},{"kind":"VariableDefinition","variable":{"kind":"Variable","name":{"kind":"Name","value":"tracking"}},"type":{"kind":"NamedType","name":{"kind":"Name","value":"TrackingInput"}},"directives":[]}],"directives":[],"selectionSet":{"kind":"SelectionSet","selections":[{"kind":"Field","name":{"kind":"Name","value":"addAction"},"arguments":[{"kind":"Argument","name":{"kind":"Name","value":"actionPageId"},"value":{"kind":"Variable","name":{"kind":"Name","value":"id"}}},{"kind":"Argument","name":{"kind":"Name","value":"contactRef"},"value":{"kind":"Variable","name":{"kind":"Name","value":"contactRef"}}},{"kind":"Argument","name":{"kind":"Name","value":"action"},"value":{"kind":"ObjectValue","fields":[{"kind":"ObjectField","name":{"kind":"Name","value":"actionType"},"value":{"kind":"Variable","name":{"kind":"Name","value":"actionType"}}},{"kind":"ObjectField","name":{"kind":"Name","value":"fields"},"value":{"kind":"Variable","name":{"kind":"Name","value":"fields"}}}]}},{"kind":"Argument","name":{"kind":"Name","value":"tracking"},"value":{"kind":"Variable","name":{"kind":"Name","value":"tracking"}}}],"directives":[],"selectionSet":{"kind":"SelectionSet","selections":[{"kind":"Field","name":{"kind":"Name","value":"contactRef"},"arguments":[],"directives":[]},{"kind":"Field","name":{"kind":"Name","value":"firstName"},"arguments":[],"directives":[]}]}}]}}]};
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
      & Pick<Types.PublicOrg, 'title'>
    )>, campaign?: Types.Maybe<(
      { __typename?: 'Campaign' }
      & Pick<Types.Campaign, 'title' | 'name' | 'externalId'>
      & { stats?: Types.Maybe<(
        { __typename?: 'CampaignStats' }
        & Pick<Types.CampaignStats, 'supporterCount'>
        & { actionCount?: Types.Maybe<Array<(
          { __typename?: 'ActionTypeCount' }
          & Pick<Types.ActionTypeCount, 'actionType' | 'count'>
        )>> }
      )>, org?: Types.Maybe<(
        { __typename?: 'PublicOrg' }
        & Pick<Types.PublicOrg, 'title'>
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
