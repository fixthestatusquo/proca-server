
import 'cross-fetch/polyfill'

import * as widget from './queries/widget'
import * as admin from './queries/admin'
import {basicAuth, tokenAuth} from './auth'
import {link, request, subscribe} from './client'


export {
  widget, admin,
  link, request, subscribe,
  basicAuth, tokenAuth
}
