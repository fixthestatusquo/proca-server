import * as Types from 'types';

import { GraphQLClient } from 'graphql-request';
import { print } from 'graphql';
import gql from 'graphql-tag';

export const GetActionPageDocument = gql`
    query GetActionPage($name: String, $id: Int) {
  actionPage(name: $name, id: $id) {
    config
    locale
    journey
    name
    campaign {
      title
      name
      externalId
      stats {
        actionCount {
          actionType
          count
        }
        supporterCount
      }
      org {
        title
      }
    }
  }
}
    `;
export const GetStatsDocument = gql`
    query GetStats($name: String, $id: Int) {
  actionPage(id: $id, name: $name) {
    campaign {
      stats {
        supporterCount
        actionCount {
          actionType
          count
        }
      }
    }
  }
}
    `;
export const GetPublicResultDocument = gql`
    query GetPublicResult($name: String, $id: Int, $actionType: String!) {
  actionPage(name: $name, id: $id) {
    config
    locale
    journey
    name
    campaign {
      title
      name
      externalId
      stats {
        actionCount {
          actionType
          count
        }
        supporterCount
      }
      actions(actionType: $actionType) {
        fieldKeys
        list {
          actionType
          insertedAt
          fields {
            key
            value
          }
        }
      }
      org {
        title
      }
    }
  }
}
    `;
export const AddContactActionDocument = gql`
    mutation AddContactAction($id: Int!, $contact: ContactInput!, $actionType: String!, $fields: [CustomFieldInput!], $privacy: ConsentInput!, $tracking: TrackingInput) {
  addActionContact(actionPageId: $id, contact: $contact, action: {actionType: $actionType, fields: $fields}, privacy: $privacy, tracking: $tracking) {
    contactRef
    firstName
  }
}
    `;
export const AddActionDocument = gql`
    mutation AddAction($id: Int!, $contactRef: ID!, $actionType: String!, $fields: [CustomFieldInput!], $tracking: TrackingInput) {
  addAction(actionPageId: $id, contactRef: $contactRef, action: {actionType: $actionType, fields: $fields}, tracking: $tracking) {
    contactRef
    firstName
  }
}
    `;

export type SdkFunctionWrapper = <T>(action: () => Promise<T>) => Promise<T>;


const defaultWrapper: SdkFunctionWrapper = sdkFunction => sdkFunction();
export function getSdk(client: GraphQLClient, withWrapper: SdkFunctionWrapper = defaultWrapper) {
  return {
    GetActionPage(variables?: GetActionPageQueryVariables): Promise<GetActionPageQuery> {
      return withWrapper(() => client.request<GetActionPageQuery>(print(GetActionPageDocument), variables));
    },
    GetStats(variables?: GetStatsQueryVariables): Promise<GetStatsQuery> {
      return withWrapper(() => client.request<GetStatsQuery>(print(GetStatsDocument), variables));
    },
    GetPublicResult(variables: GetPublicResultQueryVariables): Promise<GetPublicResultQuery> {
      return withWrapper(() => client.request<GetPublicResultQuery>(print(GetPublicResultDocument), variables));
    },
    AddContactAction(variables: AddContactActionMutationVariables): Promise<AddContactActionMutation> {
      return withWrapper(() => client.request<AddContactActionMutation>(print(AddContactActionDocument), variables));
    },
    AddAction(variables: AddActionMutationVariables): Promise<AddActionMutation> {
      return withWrapper(() => client.request<AddActionMutation>(print(AddActionDocument), variables));
    }
  };
}
export type Sdk = ReturnType<typeof getSdk>;
export type GetActionPageQueryVariables = Types.Exact<{
  name?: Types.Maybe<Types.Scalars['String']>;
  id?: Types.Maybe<Types.Scalars['Int']>;
}>;


export type GetActionPageQuery = (
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
      )>, org?: Types.Maybe<(
        { __typename?: 'PublicOrg' }
        & Pick<Types.PublicOrg, 'title'>
      )> }
    )> }
  )> }
);

export type GetStatsQueryVariables = Types.Exact<{
  name?: Types.Maybe<Types.Scalars['String']>;
  id?: Types.Maybe<Types.Scalars['Int']>;
}>;


export type GetStatsQuery = (
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

export type GetPublicResultQueryVariables = Types.Exact<{
  name?: Types.Maybe<Types.Scalars['String']>;
  id?: Types.Maybe<Types.Scalars['Int']>;
  actionType: Types.Scalars['String'];
}>;


export type GetPublicResultQuery = (
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

export type AddContactActionMutationVariables = Types.Exact<{
  id: Types.Scalars['Int'];
  contact: Types.ContactInput;
  actionType: Types.Scalars['String'];
  fields?: Types.Maybe<Array<Types.CustomFieldInput>>;
  privacy: Types.ConsentInput;
  tracking?: Types.Maybe<Types.TrackingInput>;
}>;


export type AddContactActionMutation = (
  { __typename?: 'RootMutationType' }
  & { addActionContact?: Types.Maybe<(
    { __typename?: 'ContactReference' }
    & Pick<Types.ContactReference, 'contactRef' | 'firstName'>
  )> }
);

export type AddActionMutationVariables = Types.Exact<{
  id: Types.Scalars['Int'];
  contactRef: Types.Scalars['ID'];
  actionType: Types.Scalars['String'];
  fields?: Types.Maybe<Array<Types.CustomFieldInput>>;
  tracking?: Types.Maybe<Types.TrackingInput>;
}>;


export type AddActionMutation = (
  { __typename?: 'RootMutationType' }
  & { addAction?: Types.Maybe<(
    { __typename?: 'ContactReference' }
    & Pick<Types.ContactReference, 'contactRef' | 'firstName'>
  )> }
);
