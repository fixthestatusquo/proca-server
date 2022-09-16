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
var __asyncValues = (this && this.__asyncValues) || function (o) {
    if (!Symbol.asyncIterator) throw new TypeError("Symbol.asyncIterator is not defined.");
    var m = o[Symbol.asyncIterator], i;
    return m ? m.call(o) : (o = typeof __values === "function" ? __values(o) : o[Symbol.iterator](), i = {}, verb("next"), verb("throw"), verb("return"), i[Symbol.asyncIterator] = function () { return this; }, i);
    function verb(n) { i[n] = o[n] && function (v) { return new Promise(function (resolve, reject) { v = o[n](v), settle(resolve, reject, v.done, v.value); }); }; }
    function settle(resolve, reject, d, v) { Promise.resolve(v).then(function(v) { resolve({ value: v, done: d }); }, reject); }
};
Object.defineProperty(exports, "__esModule", { value: true });
const queue_1 = require("@proca/queue");
const helpers_1 = require("./helpers");
const amqplib = require('amqplib');
const { Level } = require("level");
const schedule = require('node-schedule');
//const nodeSchedule = require("@types/node-schedule")
const db = new Level(process.env.DB_PATH || "./repeater.db", { valueEncoding: 'json' });
const user = process.env.RABBIT_USER;
const pass = process.env.RABBIT_PASSWORD;
const queueConfirm = process.env.CONFIRM_QUEUE || "";
const queueConfirmed = process.env.CONFIRMED_QUEUE || "";
const maxRetries = parseInt(process.env.MAX_RETIRES || "3");
const debugDayOffset = parseInt(process.env.ADD_DAYS || "0");
const dbError = (operation) => (error) => {
    if (error) {
        console.error(`Could not store key in DB to ${operation}, exiting`);
        process.exit(1);
    }
};
//TODO: run every 10 min
const job = schedule.scheduleJob('* * * * *', () => __awaiter(void 0, void 0, void 0, function* () {
    var e_1, _a;
    console.log('running every minute', maxRetries);
    try {
        for (var _b = __asyncValues(db.iterator({ gt: 'retry-' })), _c; _c = yield _b.next(), !_c.done;) {
            const [key, value] = _c.value;
            console.log("Job:", key, value);
            const actionId = key.split("-")[1];
            if (value.attempts >= maxRetries) {
                yield db.put('done-' + actionId, { done: false }, dbError("mark action as failed"));
                yield db.del('action-' + actionId, dbError("delete action payload"));
                yield db.del('retry-' + actionId, dbError("delete action retry count"));
            }
            else {
                const today = new Date();
                today.setDate(today.getDate() + debugDayOffset);
                if ((new Date(value.retry)) > today && value.attempts < maxRetries) {
                    yield db.get("action-" + actionId, function (error, value) {
                        return __awaiter(this, void 0, void 0, function* () {
                            if (error)
                                console.log("Get action in job:", error);
                            //   todo: reinsert action to the queue
                            // amqplib.publish(
                            //   // exchange: ""
                            //   //   routing key:  "wrk.${org.id}.email.supporter"
                        });
                    });
                    yield db.get("retry-" + actionId, function (error, value) {
                        return __awaiter(this, void 0, void 0, function* () {
                            if (error) {
                                console.log("Get retry in job:", error);
                                process.exit(1);
                            }
                            else {
                                const retry = { retry: (0, helpers_1.changeDate)(value.retry, value.attempts + 1), attempts: value.attempts + 1 };
                                console.log("Retried", retry);
                                yield db.put('retry-' + actionId, retry, dbError('store retry date'));
                            }
                        });
                    });
                }
            }
        }
    }
    catch (e_1_1) { e_1 = { error: e_1_1 }; }
    finally {
        try {
            if (_c && !_c.done && (_a = _b.return)) yield _a.call(_b);
        }
        finally { if (e_1) throw e_1.error; }
    }
}));
(0, queue_1.syncQueue)(`amqps://${user}:${pass}@api.proca.app/proca_live`, queueConfirm, (action) => __awaiter(void 0, void 0, void 0, function* () {
    if (action.schema === 'proca:action:2') {
        console.log(action.actionId);
        yield db.get('action-' + action.actionId, function (error, value) {
            var _a;
            return __awaiter(this, void 0, void 0, function* () {
                console.log('db.get(action-...)', error);
                if (((_a = error === null || error === void 0 ? void 0 : error.cause) === null || _a === void 0 ? void 0 : _a.code) === 'LEVEL_NOT_FOUND') {
                    yield db.put('action-' + action.actionId, action, dbError('save action'));
                    yield db.get('action-' + action.actionId, dbError('check if saved action exists'));
                    const retry = { retry: (0, helpers_1.changeDate)(action.action.createdAt, 1), attempts: 1 };
                    yield db.put('retry-' + action.actionId, retry, dbError('save retry'));
                    yield db.get('retry-' + action.actionId, dbError('check if saved retry exists'));
                }
                else if (error) {
                    console.error(`failed to check if action in db: ${error.cause}`);
                }
            });
        });
    }
}));
(0, queue_1.syncQueue)(`amqps://${user}:${pass}@api.proca.app/proca_live`, queueConfirmed, (action) => __awaiter(void 0, void 0, void 0, function* () {
    if (action.schema === 'proca:action:2') {
        console.log("Confirmed:", action.actionId);
        yield db.put('done-' + action.actionId, { done: true }, dbError('save done success'));
        yield db.del('action-' + action.actionId, dbError('remove confirmed action'));
        yield db.del('retry-' + action.actionId, dbError('remove confirmed retry'));
    }
}));
