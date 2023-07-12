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
const dotenv_1 = __importDefault(require("dotenv"));
dotenv_1.default.config();
// READ PARAMS
const args = (0, minimist_1.default)(process.argv.slice(2));
const db = new level_1.Level(process.env.DB_PATH || args.db || "./reminder.db", { valueEncoding: 'json' });
const user = process.env.RABBIT_USER || args.user;
const pass = process.env.RABBIT_PASSWORD || args.password;
const queueConfirm = process.env.CONFIRM_QUEUE || args.qc || "";
const queueConfirmed = process.env.CONFIRMED_QUEUE || args.qd || "";
const remindExchange = process.env.REMIND_EXCHANGE || args.qe || "";
const retryArray = (process.env.RETRY_INTERVAL || "2,3").split(",").map(x => parseInt(x)).filter(x => x > 0);
const maxPeriod = retryArray.reduce((max, d) => (max + d), 0);
const maxRetries = retryArray.length + 1;
// debug
const debugDayOffset = parseInt(process.env.ADD_DAYS || args.A || "0");
const amqp_url = `amqps://${user}:${pass}@api.proca.app/proca_live`;
//TODO: run every 10 min
const job = node_schedule_1.default.scheduleJob('* * * * *', () => __awaiter(void 0, void 0, void 0, function* () {
    var _a, e_1, _b, _c;
    console.log('running every minute', maxRetries);
    const conn = yield amqplib_1.default.connect(amqp_url);
    const chan = yield conn.createChannel();
    try {
        try {
            for (var _d = true, _e = __asyncValues(db.iterator({ gt: 'retry-' })), _f; _f = yield _e.next(), _a = _f.done, !_a;) {
                _c = _f.value;
                _d = false;
                try {
                    const [key, value] = _c;
                    // console.log("Confirm:", key, value);
                    const actionId = key.split("-")[1];
                    // we already had max retries, or retry record is too old
                    if (value.attempts >= maxRetries || !(0, helpers_1.retryValid)(value.retry, maxPeriod)) { // attempts counts also 1st normal confirm
                        const msg = value.attempts >= maxRetries
                            ? `Confirm ${actionId} had already ${value.attempts}, deleting`
                            : `Confirm ${actionId} expired. ${value.retry}, deleting`;
                        console.log(msg);
                        yield db.put('done-' + actionId, { done: false }, {});
                        yield db.del('action-' + actionId);
                        yield db.del('retry-' + actionId);
                    }
                    else {
                        const today = new Date();
                        today.setDate(today.getDate() + debugDayOffset);
                        // check if it is time for reminder
                        if ((new Date(value.retry)) < today && value.attempts < maxRetries) {
                            console.log(`Reminding action ${actionId} (due ${value.retry})`);
                            // publish
                            const action = yield db.get("action-" + actionId, {});
                            action.action.customFields.reminder = true;
                            const r = yield chan.publish(remindExchange, action.action.actionType + '.' + action.campaign.name, Buffer.from(JSON.stringify(action)));
                            console.log('publish', r);
                            // change retry record
                            let retry = yield db.get("retry-" + actionId, {});
                            retry = { retry: (0, helpers_1.changeDate)(value.retry, value.attempts + 1, retryArray), attempts: value.attempts + 1 };
                            yield db.put('retry-' + actionId, retry, {});
                        }
                    }
                }
                finally {
                    _d = true;
                }
            }
        }
        catch (e_1_1) { e_1 = { error: e_1_1 }; }
        finally {
            try {
                if (!_d && !_a && (_b = _e.return)) yield _b.call(_e);
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
        // Don't remind if action from the queue is too old
        if ((0, helpers_1.retryValid)(action.action.createdAt, maxPeriod)) {
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
            return;
        }
        console.log(`${action.actionId} created at ${action.action.createdAt} from the confirm queue expired, deleting`);
        yield db.put('done-' + action.actionId, { done: false }, {});
        yield db.del('action-' + action.actionId);
        yield db.del('retry-' + action.actionId);
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
