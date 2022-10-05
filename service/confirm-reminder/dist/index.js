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
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
const queue_1 = require("@proca/queue");
const helpers_1 = require("./helpers");
const amqplib_1 = __importDefault(require("amqplib"));
const level_1 = require("level");
const node_schedule_1 = __importDefault(require("node-schedule"));
const minimist_1 = __importDefault(require("minimist"));
// READ PARAMS
const args = (0, minimist_1.default)(process.argv.slice(2));
const db = new level_1.Level(process.env.DB_PATH || args.db || "./reminder.db", { valueEncoding: 'json' });
const user = process.env.RABBIT_USER || args.user;
const pass = process.env.RABBIT_PASSWORD || args.password;
const queueConfirm = process.env.CONFIRM_QUEUE || args.qc || "";
const queueConfirmed = process.env.CONFIRMED_QUEUE || args.qd || "";
const emailQueue = process.env.EMAIL_QUEUE || args.qe || "";
const remindExchange = process.env.REMIND_EXCHANGE || args.qe || "";
const maxRetries = parseInt(process.env.MAX_RETIRES || args.r || "3");
const retryArray = (process.env.RETRY_INTERVAL || "2,3").split(",").map(x => parseInt(x)).filter(x => x > 0);
// debug
const debugDayOffset = parseInt(process.env.ADD_DAYS || args.A || "0");
const amqp_url = `amqps://${user}:${pass}@api.proca.app/proca_live`;
//TODO: run every 10 min
const job = node_schedule_1.default.scheduleJob('* * * * *', () => __awaiter(void 0, void 0, void 0, function* () {
    var e_1, _a;
    console.log('running every minute', maxRetries);
    const conn = yield amqplib_1.default.connect(amqp_url);
    const chan = yield conn.createChannel();
    try {
        try {
            for (var _b = __asyncValues(db.iterator({ gt: 'retry-' })), _c; _c = yield _b.next(), !_c.done;) {
                const [key, value] = _c.value;
                console.log("Confirm:", key, value);
                const actionId = key.split("-")[1];
                if (value.attempts >= maxRetries) { // attempts counts also 1st normal confirm
                    console.log(`Confirm ${actionId} had already ${value.attempts}, deleting`);
                    yield db.put('done-' + actionId, { done: false }, {});
                    yield db.del('action-' + actionId);
                    yield db.del('retry-' + actionId);
                }
                else {
                    const today = new Date();
                    today.setDate(today.getDate() + debugDayOffset);
                    console.log(`${new Date(value.retry)} < ${today} ?`);
                    if ((new Date(value.retry)) < today && value.attempts < maxRetries) {
                        console.log(`Reminding action ${actionId} (due ${value.retry})`);
                        // publish
                        const action = yield db.get("action-" + actionId, {});
                        action.action.customFields.reminder = true;
                        console.log("PUB", emailQueue, action);
                        const r = yield chan.publish(remindExchange, action.action.actionType + '.' + action.campaign.name, Buffer.from(JSON.stringify(action)));
                        console.log('publish', r);
                        let retry = yield db.get("retry-" + actionId, {});
                        retry = { retry: (0, helpers_1.changeDate)(value.retry, value.attempts + 1, retryArray), attempts: value.attempts + 1 };
                        console.debug("Retried", retry);
                        yield db.put('retry-' + actionId, retry, {});
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
    }
    finally {
        yield chan.close();
        yield conn.close();
    }
}));
(0, queue_1.syncQueue)(amqp_url, queueConfirm, (action) => __awaiter(void 0, void 0, void 0, function* () {
    if (action.schema === 'proca:action:2' && action.contact.dupeRank === 0) {
        console.log(`New confirm `, action.actionId);
        try {
            // ignore if we have it
            const _payload = yield db.get('action-' + action.actionId);
        }
        catch (_error) {
            console.error('catch', _error);
            const error = _error;
            if (error.notFound) {
                yield db.put('action-' + action.actionId, action, {});
                const retry = { retry: (0, helpers_1.changeDate)(action.action.createdAt, 1, retryArray), attempts: 1 };
                yield db.put('retry-' + action.actionId, retry, {});
                console.log(`Scheduled confirm reminder: ${action.actionId}`, action);
            }
            else {
                console.error(`Error checking if confirm scheduled in DB`, error);
                throw error;
            }
        }
    }
}));
(0, queue_1.syncQueue)(amqp_url, queueConfirmed, (action) => __awaiter(void 0, void 0, void 0, function* () {
    if (action.schema === 'proca:action:2') {
        console.log("Confirmed:", action.actionId);
        yield db.put('done-' + action.actionId, { done: true }, {});
        yield db.del('action-' + action.actionId);
        yield db.del('retry-' + action.actionId);
    }
}));
