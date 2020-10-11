import * as Types from 'types';

import { GraphQLClient } from 'graphql-request';
import { print } from 'graphql';
import gql from 'graphql-tag';

export const ListCampaignsDocument = gql`
    query ListCampaigns($org: String!) {
  org(name: $org) {
    campaigns {
      id
      externalId
      name
      title
      org {
        name
        title
      }
    }
  }
}
    `;
export const GetCampaignDocument = gql`
    query GetCampaign($org: String!, $id: Int!) {
  org(name: $org) {
    campaign(id: $id) {
      id
      externalId
      name
      title
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
export const GetActionPageDocument = gql`
    query GetActionPage($org: String!, $id: Int!) {
  org(name: $org) {
    actionPage(id: $id) {
      id
      name
      locale
      extraSupporters
      thankYouTemplateRef
      config
      campaign {
        name
        id
        externalId
      }
    }
  }
}
    `;
export const ListActionPagesDocument = gql`
    query ListActionPages($org: String!) {
  org(name: $org) {
    actionPages {
      id
      name
      locale
      extraSupporters
      campaign {
        name
        id
        externalId
      }
    }
  }
}
    `;
export const ExportCampaignActionsDocument = gql`
    query ExportCampaignActions($org: String!, $campaignId: Int!, $start: Int, $after: Datetime, $limit: Int) {
  exportActions(orgName: $org, campaignId: $campaignId, start: $start, after: $after, limit: $limit) {
    actionId
    actionType
    contact {
      contactRef
      payload
      nonce
      publicKey {
        id
        public
      }
      signKey {
        id
        public
      }
    }
    fields {
      key
      value
    }
    tracking {
      source
      medium
      campaign
      content
    }
    actionPage {
      id
      name
    }
    privacy {
      optIn
    }
  }
}
    `;
export const ExportOrgActionsDocument = gql`
    query ExportOrgActions($org: String!, $start: Int, $after: Datetime, $limit: Int) {
  exportActions(orgName: $org, start: $start, after: $after, limit: $limit) {
    actionId
    actionType
    contact {
      contactRef
      payload
      nonce
      publicKey {
        id
        public
      }
      signKey {
        id
        public
      }
    }
    fields {
      key
      value
    }
    tracking {
      source
      medium
      campaign
      content
    }
    actionPage {
      id
      name
    }
    privacy {
      optIn
    }
  }
}
    `;
export const UpdateActionPageDocument = gql`
    mutation UpdateActionPage($id: Int!, $name: String, $locale: String, $thankYouTemplateRef: String, $extraSupporters: Int, $config: String) {
  updateActionPage(id: $id, name: $name, locale: $locale, thankYouTemplateRef: $thankYouTemplateRef, extraSupporters: $extraSupporters, config: $config) {
    id
  }
}
    `;
export const UpsertCampaignDocument = gql`
    mutation UpsertCampaign($org: String!, $name: String!, $externalId: Int, $title: String, $actionPages: [ActionPageInput]!) {
  upsertCampaign(orgName: $org, name: $name, externalId: $externalId, title: $title, actionPages: $actionPages) {
    id
  }
}
    `;
export const ListKeysDocument = gql`
    query ListKeys {
  org(name: "campax") {
    keys {
      id
      name
      public
      expiredAt
    }
  }
}
    `;

export type SdkFunctionWrapper = <T>(action: () => Promise<T>) => Promise<T>;


const defaultWrapper: SdkFunctionWrapper = sdkFunction => sdkFunction();
export function getSdk(client: GraphQLClient, withWrapper: SdkFunctionWrapper = defaultWrapper) {
  return {
    ListCampaigns(variables: ListCampaignsQueryVariables): Promise<ListCampaignsQuery> {
      return withWrapper(() => client.request<ListCampaignsQuery>(print(ListCampaignsDocument), variables));
    },
    GetCampaign(variables: GetCampaignQueryVariables): Promise<GetCampaignQuery> {
      return withWrapper(() => client.request<GetCampaignQuery>(print(GetCampaignDocument), variables));
    },
    GetActionPage(variables: GetActionPageQueryVariables): Promise<GetActionPageQuery> {
      return withWrapper(() => client.request<GetActionPageQuery>(print(GetActionPageDocument), variables));
    },
    ListActionPages(variables: ListActionPagesQueryVariables): Promise<ListActionPagesQuery> {
      return withWrapper(() => client.request<ListActionPagesQuery>(print(ListActionPagesDocument), variables));
    },
    ExportCampaignActions(variables: ExportCampaignActionsQueryVariables): Promise<ExportCampaignActionsQuery> {
      return withWrapper(() => client.request<ExportCampaignActionsQuery>(print(ExportCampaignActionsDocument), variables));
    },
    ExportOrgActions(variables: ExportOrgActionsQueryVariables): Promise<ExportOrgActionsQuery> {
      return withWrapper(() => client.request<ExportOrgActionsQuery>(print(ExportOrgActionsDocument), variables));
    },
    UpdateActionPage(variables: UpdateActionPageMutationVariables): Promise<UpdateActionPageMutation> {
      return withWrapper(() => client.request<UpdateActionPageMutation>(print(UpdateActionPageDocument), variables));
    },
    UpsertCampaign(variables: UpsertCampaignMutationVariables): Promise<UpsertCampaignMutation> {
      return withWrapper(() => client.request<UpsertCampaignMutation>(print(UpsertCampaignDocument), variables));
    },
    ListKeys(variables?: ListKeysQueryVariables): Promise<ListKeysQuery> {
      return withWrapper(() => client.request<ListKeysQuery>(print(ListKeysDocument), variables));
    }
  };
}
export type Sdk = ReturnType<typeof getSdk>;
export type ListCampaignsQueryVariables = Types.Exact<{
  org: Types.Scalars['String'];
}>;


export type ListCampaignsQuery = (
  { __typename?: 'RootQueryType' }
  & { org?: Types.Maybe<(
    { __typename?: 'Org' }
    & { campaigns?: Types.Maybe<Array<Types.Maybe<(
      { __typename?: 'Campaign' }
      & Pick<Types.Campaign, 'id' | 'externalId' | 'name' | 'title'>
      & { org?: Types.Maybe<(
        { __typename?: 'PublicOrg' }
        & Pick<Types.PublicOrg, 'name' | 'title'>
      )> }
    )>>> }
  )> }
);

export type GetCampaignQueryVariables = Types.Exact<{
  org: Types.Scalars['String'];
  id: Types.Scalars['Int'];
}>;


export type GetCampaignQuery = (
  { __typename?: 'RootQueryType' }
  & { org?: Types.Maybe<(
    { __typename?: 'Org' }
    & { campaign?: Types.Maybe<(
      { __typename?: 'Campaign' }
      & Pick<Types.Campaign, 'id' | 'externalId' | 'name' | 'title'>
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

export type GetActionPageQueryVariables = Types.Exact<{
  org: Types.Scalars['String'];
  id: Types.Scalars['Int'];
}>;


export type GetActionPageQuery = (
  { __typename?: 'RootQueryType' }
  & { org?: Types.Maybe<(
    { __typename?: 'Org' }
    & { actionPage?: Types.Maybe<(
      { __typename?: 'ActionPage' }
      & Pick<Types.ActionPage, 'id' | 'name' | 'locale' | 'extraSupporters' | 'thankYouTemplateRef' | 'config'>
      & { campaign?: Types.Maybe<(
        { __typename?: 'Campaign' }
        & Pick<Types.Campaign, 'name' | 'id' | 'externalId'>
      )> }
    )> }
  )> }
);

export type ListActionPagesQueryVariables = Types.Exact<{
  org: Types.Scalars['String'];
}>;


export type ListActionPagesQuery = (
  { __typename?: 'RootQueryType' }
  & { org?: Types.Maybe<(
    { __typename?: 'Org' }
    & { actionPages?: Types.Maybe<Array<Types.Maybe<(
      { __typename?: 'ActionPage' }
      & Pick<Types.ActionPage, 'id' | 'name' | 'locale' | 'extraSupporters'>
      & { campaign?: Types.Maybe<(
        { __typename?: 'Campaign' }
        & Pick<Types.Campaign, 'name' | 'id' | 'externalId'>
      )> }
    )>>> }
  )> }
);

export type ExportCampaignActionsQueryVariables = Types.Exact<{
  org: Types.Scalars['String'];
  campaignId: Types.Scalars['Int'];
  start?: Types.Maybe<Types.Scalars['Int']>;
  after?: Types.Maybe<Types.Scalars['Datetime']>;
  limit?: Types.Maybe<Types.Scalars['Int']>;
}>;


export type ExportCampaignActionsQuery = (
  { __typename?: 'RootQueryType' }
  & { exportActions?: Types.Maybe<Array<Types.Maybe<(
    { __typename?: 'Action' }
    & Pick<Types.Action, 'actionId' | 'actionType'>
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
  )>>> }
);

export type ExportOrgActionsQueryVariables = Types.Exact<{
  org: Types.Scalars['String'];
  start?: Types.Maybe<Types.Scalars['Int']>;
  after?: Types.Maybe<Types.Scalars['Datetime']>;
  limit?: Types.Maybe<Types.Scalars['Int']>;
}>;


export type ExportOrgActionsQuery = (
  { __typename?: 'RootQueryType' }
  & { exportActions?: Types.Maybe<Array<Types.Maybe<(
    { __typename?: 'Action' }
    & Pick<Types.Action, 'actionId' | 'actionType'>
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
  )>>> }
);

export type UpdateActionPageMutationVariables = Types.Exact<{
  id: Types.Scalars['Int'];
  name?: Types.Maybe<Types.Scalars['String']>;
  locale?: Types.Maybe<Types.Scalars['String']>;
  thankYouTemplateRef?: Types.Maybe<Types.Scalars['String']>;
  extraSupporters?: Types.Maybe<Types.Scalars['Int']>;
  config?: Types.Maybe<Types.Scalars['String']>;
}>;


export type UpdateActionPageMutation = (
  { __typename?: 'RootMutationType' }
  & { updateActionPage?: Types.Maybe<(
    { __typename?: 'ActionPage' }
    & Pick<Types.ActionPage, 'id'>
  )> }
);

export type UpsertCampaignMutationVariables = Types.Exact<{
  org: Types.Scalars['String'];
  name: Types.Scalars['String'];
  externalId?: Types.Maybe<Types.Scalars['Int']>;
  title?: Types.Maybe<Types.Scalars['String']>;
  actionPages: Array<Types.Maybe<Types.ActionPageInput>>;
}>;


export type UpsertCampaignMutation = (
  { __typename?: 'RootMutationType' }
  & { upsertCampaign?: Types.Maybe<(
    { __typename?: 'Campaign' }
    & Pick<Types.Campaign, 'id'>
  )> }
);

export type ListKeysQueryVariables = Types.Exact<{ [key: string]: never; }>;


export type ListKeysQuery = (
  { __typename?: 'RootQueryType' }
  & { org?: Types.Maybe<(
    { __typename?: 'Org' }
    & { keys: Array<(
      { __typename?: 'Key' }
      & Pick<Types.Key, 'id' | 'name' | 'public' | 'expiredAt'>
    )> }
  )> }
);
