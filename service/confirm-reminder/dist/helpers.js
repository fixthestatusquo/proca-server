"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.changeDate = void 0;
let retryArray = [];
if (process.env.RETRY_INTERVAL)
    retryArray = process.env.RETRY_INTERVAL.split(",").map(x => parseInt(x)).filter(x => x > 0);
/*
 * Date - datetime in ISO format
 * attempts - how many previous attempts were there (for first confirmation = 1)
 * if RETRY_INTERVAL not configured, use interval of 2
 */
const changeDate = (date, attempts) => {
    let retryInterval = 2;
    if (retryArray[attempts - 1]) {
        retryInterval = retryArray[attempts - 1];
    }
    const oldDate = new Date(date);
    return new Date(oldDate.setDate(oldDate.getDate() + retryInterval)).toISOString();
};
exports.changeDate = changeDate;
