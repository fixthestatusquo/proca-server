const config = require('./config/get.js');
const {getCount,getSignature} = require ('./lib/server.js');

async function start (actionPage) {
  const count = await getCount(actionPage);
  console.log ("actionPage count:" +count);
  const data= await getSignature();
  console.log(data);
}

start (1);
