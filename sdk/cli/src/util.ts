import {basicAuth} from '@proca/api'

export async function showToken(argv) {
  const a = basicAuth({username: argv.user, password: argv.password})
  console.log(`This is your username and password in a form of Basic HTTP token:\n${JSON.stringify(a)}`)
}

