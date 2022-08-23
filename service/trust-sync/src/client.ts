const crypto = require('crypto');
const axios = require('axios').default;
const dotenv = require('dotenv');
dotenv.config();

import { Signature } from "./data";

const key = process.env['TRUST_KEY'];
const stamp = Math.floor(Math.floor(Date.now() / 1000)/30).toString();

let token = crypto.createHmac("sha256", key).update(stamp).digest().toString('hex');

const headers = {
  headers: {
    'Authorization': `Token token="proca-test:${token}"`,
    'Content-Type': 'application/json'
  }
}

const postUrl = "https://lc-trust-stage.palasthotel.de/api/v1/petition_signatures"

export const postAction = async (body: Signature) => {
  try {
    const { data, status } = await axios.post(
      postUrl,
      body,
      headers
    );
    console.log('Status: ', status, data);
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