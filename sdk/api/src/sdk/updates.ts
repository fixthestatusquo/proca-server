import * as Types from 'types';

import { TypedDocumentNode as DocumentNode } from '@graphql-typed-document-node/core';

export const ActionPageUpdatedDocument: DocumentNode<ActionPageUpdatedSubscription, ActionPageUpdatedSubscriptionVariables> = {"kind":"Document","definitions":[{"kind":"OperationDefinition","operation":"subscription","name":{"kind":"Name","value":"ActionPageUpdated"},"variableDefinitions":[{"kind":"VariableDefinition","variable":{"kind":"Variable","name":{"kind":"Name","value":"orgName"}},"type":{"kind":"NonNullType","type":{"kind":"NamedType","name":{"kind":"Name","value":"String"}}},"directives":[]}],"directives":[],"selectionSet":{"kind":"SelectionSet","selections":[{"kind":"Field","name":{"kind":"Name","value":"actionPageUpdated"},"arguments":[{"kind":"Argument","name":{"kind":"Name","value":"orgName"},"value":{"kind":"Variable","name":{"kind":"Name","value":"orgName"}}}],"directives":[],"selectionSet":{"kind":"SelectionSet","selections":[{"kind":"Field","name":{"kind":"Name","value":"id"},"arguments":[],"directives":[]},{"kind":"Field","name":{"kind":"Name","value":"name"},"arguments":[],"directives":[]}]}}]}}]};
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
