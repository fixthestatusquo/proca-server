import {getWidgetSdk} from './index'
import {GraphQLClient} from 'graphql-request'


async function m(name : string) {
  const client = new GraphQLClient("https://api-stg.proca.app/api")
  const sdk = getWidgetSdk(client)


  console.log("?")
  try {
    const r = await sdk.GetActionPage({"name": name})
    console.log(r)
  } catch (failure) {
    console.error(typeof failure)
    console.log(failure.response.data)
    console.log(failure.response.status)
    console.log(failure.response.errors[0])
  } 

}


m(process.argv[2])
