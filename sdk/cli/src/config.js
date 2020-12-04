"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.storeConfig = exports.loadFromEnv = exports.load = void 0;
const dotenv_1 = __importDefault(require("dotenv"));
const fs_1 = require("fs");
function load() {
    const { parsed } = dotenv_1.default.config();
    const config = loadFromEnv(process.env);
    // was env file loaded?
    config.envFile = parsed !== undefined;
    return config;
}
exports.load = load;
function loadFromEnv(env = process.env) {
    const config = {
        org: env["ORG_NAME"],
        username: env["AUTH_USER"],
        password: env["AUTH_PASSWORD"],
        queue_url: env["QUEUE_URL"] || 'amqp://api.proca.app/proca',
        identity_url: env["IDENTITY_URL"],
        identity_api_token: env["IDENTITY_API_TOKEN"],
        identity_consent: env["IDENTITY_CONSENT"],
        identity_action_fields: (env["IDENTITY_ACTION_FIELDS"] || '').toLowerCase().split(','),
        identity_contact_fields: (env["IDENTITY_CONTACT_FIELDS"] || '').toLowerCase().split(','),
        service_url: env["SERVICE_URL"] || env["IDENTITY_URL"],
        url: env["API_URL"] || 'https://api.proca.app',
        keyData: env["KEYS"] || 'keys.json',
        envFile: false,
        verbose: false
    };
    return config;
}
exports.loadFromEnv = loadFromEnv;
function storeConfig(config, file_name) {
    let data = '';
    const vars = {
        'ORG_NAME': config.org,
        'AUTH_USER': config.username,
        'AUTH_PASSWORD': config.password,
        'API_URL': config.url,
        'QUEUE_URL': config.queue_url,
        'IDENTITY_URL': config.identity_url,
        'IDENTITY_API_TOKEN': config.identity_api_token,
        'IDENTITY_CONSENT': config.identity_consent,
        'IDENTITY_ACTION_FIELDS': config.identity_action_fields ? config.identity_action_fields.join(",") : null,
        'IDENTITY_CONTACT_FIELDS': config.identity_contact_fields ? config.identity_contact_fields.join(",") : null,
        'SERVICE_URL': config.service_url,
        'KEYS': config.keyData
    };
    for (let [k, v] of Object.entries(vars)) {
        if (v) {
            data += `${k}=${v}\n`;
        }
    }
    fs_1.writeFileSync(file_name, data);
}
exports.storeConfig = storeConfig;
//# sourceMappingURL=config.js.map