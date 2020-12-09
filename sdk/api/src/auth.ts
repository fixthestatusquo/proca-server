import {encode} from 'js-base64';

export type BasicAuth = {
  username: string,
  password: string
}

export type TokenAuth = {
  token: string
}

type Auth = BasicAuth | TokenAuth

export type AuthHeader = {
  authorization: string
}

export function basicAuth(cred : BasicAuth) : AuthHeader {
  if (!cred.username || !cred.password) {
    throw new Error("@proca/api: missing parameters for basicAuth({username, password})")
  }
  const up = cred.username + ":" + cred.password
  const baseup = encode(up)
  return {authorization: 'Basic ' + baseup}
}

export function tokenAuth(cred: TokenAuth) : AuthHeader {
  if (!cred.token) {
    throw new Error("@proca/api: missing parameters for tokenAuth({token})")
  }
  return {authorization: 'Bearer ' + cred.token}
}
