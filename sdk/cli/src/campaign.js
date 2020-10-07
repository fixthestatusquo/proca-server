
import client from './client'
import {adminSdk} from '@proca/api'
import {getFormatter} from './format'

export async function listCampaigns(argv) {
  const admin = adminSdk(client(argv))
  const fmt = getFormatter(argv)

  try {
    const resp = await admin.ListCampaigns({"org": argv.org})
    resp.org.campaigns
      .map(c => fmt.campaign(c))
      .forEach((c) => {
        console.log(c)
      })
  } catch (problem) {
    if (problem.response) {
      console.error(fmt.errors(problem.response.errors))
    } else {
      console.error(problem)
    }
  }
}

export async function getCampaign(argv) {
  const admin = adminSdk(client(argv))
  const fmt = getFormatter(argv)
  
  try {
    const resp = await admin.GetCampaign({"org": argv.org, "id": argv.c})
    console.log(fmt.campaign(resp.org.campaign))
    console.log(fmt.campaignStats(resp.org.campaign))

  } catch (problem) {
    if (problem.response) {
      console.error(fmt.errors(problem.response.errors))
    } else {
      console.error(problem)
    }
  }

}

