if (!process.env.PRIVATE_KEY && !process.env.BASIC_AUTHORIZATION) {
//  console.log("getting config from .env");
  const dotenv=require('dotenv').config();
  if (dotenv.error) {
    console.log(dotenv.error);
    process.exit ("you need to set up environment variables. read the README.md file for how to do that")
  }
}
module.exports = {
  authorization: process.env.BASIC_AUTHORIZATION,
  private_key: process.env.PRIVATE_KEY,
  public_key: process.env.PUBLIC_KEY,
  url: process.env.API_URL
};