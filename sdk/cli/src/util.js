import config from "./config";
import client from './client'

export async function showToken(argv) {
  const c = client(argv);
  console.log(c.options.headers);
}

export async function setup(argv) {
  config.setup();
}
