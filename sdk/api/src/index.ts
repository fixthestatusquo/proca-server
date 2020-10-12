import * as widgetSdk from './sdk/widget'
import * as adminSdk from './sdk/admin'
import * as updatesSdk from './sdk/updates'
import {authBasic, authToken} from './auth'
import {client} from './client'

function foo () {
  const c = client('http://localhost:4000')

  const a = updatesSdk.ActionPageUpdatedDocument.definitions

  const q = c.subscribe({
    query: updatesSdk.ActionPageUpdatedDocument,
    variables: {orgName: 'test'}
  })

  const s = q.subscribe({
    next: (r) => { console.log('next:', r)},
    error: (e) => {console.error('not good', e)},
    complete: () => {console.info('complete')}
  })
  return [c, s]
}


export {
  foo, 
  widgetSdk,
  adminSdk,
  updatesSdk,
  client,
  authBasic,
  authToken,
}
