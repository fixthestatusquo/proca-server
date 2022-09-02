const dotenv = require('dotenv');
dotenv.config();

const retryInterval = process.env.RETRY_INTERVAL || '1';

export const changeDate = (date: string): string => {
  const oldDate = new Date(date)
  return new Date(oldDate.setDate(oldDate.getDate() + +retryInterval)).toISOString();
};