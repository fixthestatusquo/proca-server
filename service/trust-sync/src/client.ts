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
  console.log("post headers:", headers, "post url:", postUrl)
  try {
    const { data, status } = await axios.post(
      postUrl,
      body,
      headers
    );
    console.log('Post status: ', status, data);
    return data;
    } catch (error: any) {
    if (axios.isAxiosError(error)) {
      console.log('post error: ', error.code, error.config.data, error.message, error.response.status, error.response.statusText);
      return error.message;
    } else {
      console.log('post unexpected error: ', error);
      return 'An unexpected error occurred';
    }
  }
}

export const verification = async (verificationToken: string) => {
  const verificationUrl = `https://lc-trust-stage.palasthotel.de/api/v1/petition_signatures/${verificationToken}/verify`;
  console.log("verification headers:", headers, "verification url:",verificationUrl)
  try {
    const { data, status } = await axios.post(
      verificationUrl,
      {},
      headers
    );
    console.log('Verification status: ', status, data);
    return data;
    } catch (error: any) {
    if (axios.isAxiosError(error)) {
      console.log('verification error: ', error.message, error);
      return error.message;
    } else {
      console.log('verification unexpected error: ', error);
      return 'An unexpected error occurred';
    }
  }
}

export const lookup = async (email: string) => {
  const url = `https://lc-trust-stage.palasthotel.de/api/v1/lookup/newsletter_subscribers?email=${email}`;
  console.log("lookup headers:", headers, "lookup url:", url)
  try {
    const { data, status } = await axios.get(url, headers);
    console.log('Lookup status: ',  data, status);
    return data;
    } catch (error: any) {
    if (axios.isAxiosError(error)) {
      console.log('Lookup error: ',  error.message, error.response.status, error.response.statusText);
      return error.message;
    } else {
      console.log('Lookup unexpected error: ', error);
      return 'An unexpected error occurred';
    }
  }
}