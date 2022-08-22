const crypto = require('crypto');
const axios = require('axios').default
const dotenv = require('dotenv');
dotenv.config();

// {
//   protected $_secret;
//   protected $_ttl;
//   protected $_digest;

//   public function __construct($secret, $ttl=30, $digest='sha256')
//   {
//     $this->_secret = $secret;
//     $this->_ttl = $ttl;
//     $this->_digest = $digest;
//   }

//   public function generate()
//   {
//     return hash_hmac($this->_digest, $this->stamp(), $this->_secret);
//   }

//   protected function stamp()
//   {
//    return (string) ((int) (time() / $this->_ttl));
//   }
// }



const key = process.env['TRUST_KEY'];
console.log("key", key)
const stamp = Math.floor(Math.floor(Date.now() / 1000)/30).toString();

let token = crypto.createHmac("sha256", key).update(stamp).digest().toString('hex');

const headers = {
  headers: {
    'Authorization': `Token token="proca-test:${token}"`,
    'Content-Type': 'application/json'
  }
}
const url = "https://lc-trust-stage.palasthotel.de/api/v1/ping"

async function getPing() {
  try {
    const { data, status } = await axios.post(
      url,
      {},
      headers,
    );

    console.log(JSON.stringify(data));
    console.log('Status: ', status);
    return data;
  } catch (error: any) {
    if (axios.isAxiosError(error)) {
      console.log('error: ', error.code, error.config.data, error.message, error.response.status, error.response.statusText);
      return error.message;
    } else {
      console.log('unexpected error: ', error);
      return 'An unexpected error occurred';
    }
  }
}

console.log(crypto.createHmac('sha256', 'secret').update('data').digest().toString('hex'))

getPing();
