const dotenv = require('dotenv');
dotenv.config();

let retryArray: string[] = [];
if (process.env.RETRY_INTERVAL) retryArray = process.env.RETRY_INTERVAL.split(",");

export const changeDate = (date: string, attempts: number): string => {
  let retryInterval = 2;
  if (retryArray[attempts - 1]) {
    retryInterval = parseInt(retryArray[attempts - 1])
  }
  const oldDate = new Date(date)
  return new Date(oldDate.setDate(oldDate.getDate() + retryInterval)).toISOString();
};