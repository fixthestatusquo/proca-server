import config from "./config";

export async function showToken(argv) {
  const c = argv2client(argv);
  console.log(c.options.headers);
}

export async function setup(argv) {
  config.setup();
}
