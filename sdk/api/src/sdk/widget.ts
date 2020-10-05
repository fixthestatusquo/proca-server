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
export const GetActionPagePublicResultDocument = gql`
    query GetActionPagePublicResult($name: String, $id: Int, $actionType: String!) {
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

export type SdkFunctionWrapper = <T>(action: () => Promise<T>) => Promise<T>;


const defaultWrapper: SdkFunctionWrapper = sdkFunction => sdkFunction();
export function getSdk(client: GraphQLClient, withWrapper: SdkFunctionWrapper = defaultWrapper) {
  return {
    GetActionPage(variables?: GetActionPageQueryVariables): Promise<GetActionPageQuery> {
      return withWrapper(() => client.request<GetActionPageQuery>(print(GetActionPageDocument), variables));
    },
    GetActionPagePublicResult(variables: GetActionPagePublicResultQueryVariables): Promise<GetActionPagePublicResultQuery> {
      return withWrapper(() => client.request<GetActionPagePublicResultQuery>(print(GetActionPagePublicResultDocument), variables));
    },
    AddContactAction(variables: AddContactActionMutationVariables): Promise<AddContactActionMutation> {
      return withWrapper(() => client.request<AddContactActionMutation>(print(AddContactActionDocument), variables));
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
    { __typename?: 'ActionPage' }
    & Pick<Types.ActionPage, 'config' | 'locale' | 'journey' | 'name'>
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

export type GetActionPagePublicResultQueryVariables = Types.Exact<{
  name?: Types.Maybe<Types.Scalars['String']>;
  id?: Types.Maybe<Types.Scalars['Int']>;
  actionType: Types.Scalars['String'];
}>;


export type GetActionPagePublicResultQuery = (
  { __typename?: 'RootQueryType' }
  & { actionPage?: Types.Maybe<(
    { __typename?: 'ActionPage' }
    & Pick<Types.ActionPage, 'config' | 'locale' | 'journey' | 'name'>
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
