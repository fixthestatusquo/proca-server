const config = require('./config/get.js');
const {getCount,getSignature} = require ('./lib/server.js');
async function start (actionPage) {
  console.log(config);
  const count = await getCount(actionPage);
  console.log ("actionPage count:" +count);
  const data= await getSignature({authorization:config.authorization});
  console.log(data);
}

start (1);
