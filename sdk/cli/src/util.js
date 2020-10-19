import config from "./config";
import {basicAuth} from '@proca/api'
import client from './client'

export async function showToken(argv) {
  const a = basicAuth({username: argv.user, password: argv.password})
  console.log(a);
}

export async function setup(argv) {
  config.setup();
}
