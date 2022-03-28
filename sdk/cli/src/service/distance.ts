import {httpLink, basicAuth, request } from '@proca/api'
import {CliConfig} from '../config'
import getClient from '../client'
import {Client} from '@urql/core'
import {ActionMessage} from '../queueMessage'
import * as proca from '../proca'


const globals : {client: Client, ap: Record<number,number>} = {
  client: null,
  ap: {}
}


export async function syncAction(action : ActionMessage, _1 : any, config : CliConfig) {
  if (!globals.client) {
    globals.client = getClient(config)
  }


  if (action.schema == 'proca:action:2') {
    let distance = action.action.customFields['distance']
    if (typeof distance === "string")
      distance = Math.round(parseFloat(distance))
    if (typeof distance !== 'number') {
      console.error(`distance is not a number: ${distance}`)
      return;
    }

    let nd = 0;
    if (action.actionPageId in globals.ap) {
      nd = globals.ap[action.actionPageId] + distance
    } else {
      // if there are multiple messages processed at the start, we are racing here
      const {data, error} = await request(globals.client, proca.ActionPageExtraDocument, {id: action.actionPageId})
      if (error) {
        console.error(error)
        throw `Error ${error}`
      }

      if ('extraSupporters' in data.actionPage) {
        // try to read again from AP cache, because we might loose a race
        const es = globals.ap[action.actionPageId] || data.actionPage.extraSupporters
        nd = es + distance
      } else {
        console.error("You must authenticate")
      }
    }

    globals.ap[action.actionPageId] = nd

    const setOp = await request(globals.client, proca.ActionPageSetExtraDocument, {
      id: action.actionPageId,
      extra: nd
    })

    if (setOp.error) {
      console.error(setOp.error)
      throw `Cannot update extraSupporters: ${setOp}`
    }
parseInt
  } else {
    throw `I do not support action schema ${action.schema}`
  }
}
