export * as widget from './queries/widget'
export * as admin from './queries/admin'
export * as types from './types'

// Authentication primitives
export {
  basicAuth,
  tokenAuth,
  BasicAuth,
  TokenAuth,
  AuthHeader
} from './auth'

// Api operation primitives
export {
  link,     // advanced link that can do both get and subscribe requests
  httpLink, // simple link that can do get requests
  request,  // run get request
  subscribe, // run subscribe request
  ExecutionErrors
} from './client'
