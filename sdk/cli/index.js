const config = require('./config/get.js');
const {getCount,getSignature} = require ('./lib/server.js');
const nacl = require ('tweetnacl');
const util = require("tweetnacl-util");

async function start (actionPage) {
  const data= await getSignature("realgreendeal",3,{limit:100,authorization:config.authorization});
  const key=util.decodeBase64(data.org.signatures.public_key);
  const private_key=util.decodeBase64(config.private_key);
//  console.log(data.org.campaigns);
  process.stdout.write("[\n");
  let first=true;
  data.org.signatures.list.forEach(s => {
//    console.log("message:"+s.contact+"\nnounce:"+ s.nonce+"\nkey:" +key+"\nprivate:"+ config.private_key);
    const d = util.encodeUTF8(nacl.box.open(util.decodeBase64(s.contact), util.decodeBase64(s.nonce), key, private_key));
    //d = JSON.parse(d);
    first ? first=false :  process.stdout.write(","); 
    process.stdout.write(d+"\n");
  });
  process.stdout.write("]\n");

}

start (3);
