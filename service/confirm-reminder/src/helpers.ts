/*
 * Date - datetime in ISO format
 * attempts - how many previous attempts were there (for first confirmation = 1)
 * if RETRY_INTERVAL not configured, use interval of 2
 */
export const changeDate = (date: string, attempts: number, retryArray : number[]): string => {
  let retryInterval = 2;
  if (retryArray[attempts - 1]) {
    retryInterval = retryArray[attempts - 1]
  }
  const oldDate = new Date(date)
  return new Date(oldDate.setDate(oldDate.getDate() + retryInterval)).toISOString();
};

export const retryExpired = (date: string, interval: number) => {
  const today = new Date();
  today.setDate(today.getDate() - interval);

  const retryDate = new Date(date);

  console.log("aa", date, today, retryDate, interval)

  return retryDate < today;
};

