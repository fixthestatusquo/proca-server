import { LevelError } from './types';
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

export const nullIfNotFound = async <T>(promise : Promise<T>) : Promise<T | any> => {
  try {
    const v = await promise;
  } catch (_error) {
      const error = _error as LevelError;
      if (error.notFound) {
        return null; // convert not found to null
      } else {
        throw _error; // retrow
      }
  }
}