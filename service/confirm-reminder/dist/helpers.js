"use strict";
var __awaiter = (this && this.__awaiter) || function (thisArg, _arguments, P, generator) {
    function adopt(value) { return value instanceof P ? value : new P(function (resolve) { resolve(value); }); }
    return new (P || (P = Promise))(function (resolve, reject) {
        function fulfilled(value) { try { step(generator.next(value)); } catch (e) { reject(e); } }
        function rejected(value) { try { step(generator["throw"](value)); } catch (e) { reject(e); } }
        function step(result) { result.done ? resolve(result.value) : adopt(result.value).then(fulfilled, rejected); }
        step((generator = generator.apply(thisArg, _arguments || [])).next());
    });
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.nullIfNotFound = exports.changeDate = void 0;
/*
 * Date - datetime in ISO format
 * attempts - how many previous attempts were there (for first confirmation = 1)
 * if RETRY_INTERVAL not configured, use interval of 2
 */
const changeDate = (date, attempts, retryArray) => {
    let retryInterval = 2;
    if (retryArray[attempts - 1]) {
        retryInterval = retryArray[attempts - 1];
    }
    const oldDate = new Date(date);
    return new Date(oldDate.setDate(oldDate.getDate() + retryInterval)).toISOString();
};
exports.changeDate = changeDate;
const nullIfNotFound = (promise) => __awaiter(void 0, void 0, void 0, function* () {
    try {
        const v = yield promise;
        return v;
    }
    catch (_error) {
        const error = _error;
        if (error.notFound) {
            return null; // convert not found to null
        }
        else {
            throw _error; // retrow
        }
    }
});
exports.nullIfNotFound = nullIfNotFound;
