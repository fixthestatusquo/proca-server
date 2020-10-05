import {getWidgetSdk, getAdminSdk} from './index'
import {authBasic} from './auth'
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

async function a(name: string) {
  const pw = "pelolpe123"
  let client = new GraphQLClient("http://localhost:4000/api")
  client = authBasic(client, "marcin@cahoots.pl", pw)
  const sdk = getAdminSdk(client)

  const campaigns = await sdk.ListCampaigns({"org": name})

  console.log(campaigns.org.campaigns)
}

a(process.argv[2])
