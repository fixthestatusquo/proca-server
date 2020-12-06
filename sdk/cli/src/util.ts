import {basicAuth} from '@proca/api'
import {CliOpts} from './cli'
import {CliConfig} from './config'

export async function showToken(argv : CliOpts, _ : CliConfig) {
  const a = basicAuth({username: argv.user, password: argv.password})
  console.log(`This is your username and password in a form of Basic HTTP token:\n${JSON.stringify(a)}`)
}

