const config = require('./config/get.js');
const {getCount} = require ('./lib/server.js');

async function start (actionPage) {
  const count = await getCount(actionPage);
  console.log ("actionPage count:" +count);
}

start (1);
