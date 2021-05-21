import customScalarsExchange from 'urql-custom-scalars-exchange'
import schema from './graphql.schema.json'
import {IntrospectionQuery} from 'graphql'
// Typescript graphql is broken and will not work with above schema.json

export const jsonExchange = customScalarsExchange({
      schema: schema as unknown as IntrospectionQuery,
      scalars: {
            Json(value:string):any {
                  return JSON.parse(value)
            },
      },
});

