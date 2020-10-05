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

export type SdkFunctionWrapper = <T>(action: () => Promise<T>) => Promise<T>;


const defaultWrapper: SdkFunctionWrapper = sdkFunction => sdkFunction();
export function getSdk(client: GraphQLClient, withWrapper: SdkFunctionWrapper = defaultWrapper) {
  return {
    ListCampaigns(variables: ListCampaignsQueryVariables): Promise<ListCampaignsQuery> {
      return withWrapper(() => client.request<ListCampaignsQuery>(print(ListCampaignsDocument), variables));
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
