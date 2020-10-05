
# Generate Sdk matching GraphQL schema and operations

1. Run `mix absinthe.schema.sdl --schema ProcaWeb.Schema` in proca-backend repository
2. Move `schema.graphql` to `schema/`
3. Run `npm run generate`

# Usage

Package exports two SDK's, dedicated to:
- proca widget - contains functions to fetch action page data, relevant campaign statistics, store contact and action data.
- proca admin panel or CLI - contains functions for organisation, user, campaign, acton page management, as well as contact and action data export.

Simple example:

```js
  import {getWidgetSdk, getAdminSdk} from '@proca/api'

  // create a new GraphQL client
  const client = new GraphQLClient("https://api-stg.proca.app/api")

  const sdk = getWidgetSdk(client)
  
  try {
    const actionPage = await sdk.GetActionPage({"name": "tttp.eu/campaign-non-commercial"})
    // process
  } except (error) {
    const error = errror.response.errors[0]

    const error_code = error.extensions.code
    const error_message = error.message
    const error_path = error.path
    // handle error
  }
```


To use authenticated API, use `authBasic` or `authToken`:

```js
import {authBasic} from '@proca/api'

client = authBasic(client, "user@domain.com", "password123")
sdk = getAdminSdk(client)
```


# Operations in SDK

The sdk's contain operations defined in `schema` directory, in `widget.graphql` and `admin.graphql`. You can create queries in GraphiQL UI.


