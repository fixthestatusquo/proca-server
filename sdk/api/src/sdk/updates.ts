import * as Types from 'types';

import { GraphQLClient } from 'graphql-request';
import { print } from 'graphql';
import gql from 'graphql-tag';

export const ActionPageUpdatedDocument = gql`
    subscription ActionPageUpdated($orgName: String!) {
  actionPageUpdated(orgName: $orgName) {
    id
    name
  }
}
    `;

export type SdkFunctionWrapper = <T>(action: () => Promise<T>) => Promise<T>;


const defaultWrapper: SdkFunctionWrapper = sdkFunction => sdkFunction();
export function getSdk(client: GraphQLClient, withWrapper: SdkFunctionWrapper = defaultWrapper) {
  return {
    ActionPageUpdated(variables: ActionPageUpdatedSubscriptionVariables): Promise<ActionPageUpdatedSubscription> {
      return withWrapper(() => client.request<ActionPageUpdatedSubscription>(print(ActionPageUpdatedDocument), variables));
    }
  };
}
export type Sdk = ReturnType<typeof getSdk>;
export type ActionPageUpdatedSubscriptionVariables = Types.Exact<{
  orgName: Types.Scalars['String'];
}>;


export type ActionPageUpdatedSubscription = (
  { __typename?: 'RootSubscriptionType' }
  & { actionPageUpdated?: Types.Maybe<(
    { __typename?: 'ActionPage' }
    & Pick<Types.ActionPage, 'id' | 'name'>
  )> }
);
