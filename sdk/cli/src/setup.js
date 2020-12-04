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
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.setup = void 0;
const inquirer_1 = __importDefault(require("inquirer"));
const email_validator_1 = __importDefault(require("email-validator"));
const config_1 = require("./config");
const crypto_1 = require("./crypto");
function setup(config) {
    return __awaiter(this, void 0, void 0, function* () {
        const msgHello = `Hello!\n\n` +
            `- Using current working directory: ${process.cwd()}\n` +
            (config.envFile ?
                `- I have read settings from .env file` :
                `- There is not .env file - I will create it after asking You some questions`);
        console.log(msgHello);
        let keys = null;
        try {
            keys = crypto_1.loadKeys(config);
        }
        catch (errorLoadingKeys) {
            console.warn(`- I can't load keys, because`, errorLoadingKeys.message);
            console.warn(`  You might want to use setup to add the keys.`);
            keys = {
                keys: [],
                readFromFile: true,
                filename: "keys.json"
            };
        }
        while (true) {
            const msgAuthStatus = (config.org ? `org is ${config.org}` : `no org set`) + ', ' +
                (config.username ? `user is: ${config.username}` : `user is not set up`) + ', ' +
                (config.password ? `password is set` : `password is not set`);
            const msgKeyStatus = keys === null ?
                `keys are not loaded` :
                (`${keys.keys.length} keys loaded` + (keys.readFromFile ?
                    ` from file ${keys.filename}` :
                    ` from KEYS var`));
            console.log(`\n`);
            const topMenu = yield inquirer_1.default.prompt([{
                    type: 'list',
                    message: 'What would you like to do?',
                    name: 'cmd',
                    choices: [
                        { name: "Save current config to .env file and leave", value: 'save' },
                        { name: "Just leave", value: 'leave' },
                        { name: `Set up authentication (${msgAuthStatus})`, value: 'auth' },
                        { name: `List and verify keys (${msgKeyStatus})`, value: 'keys' },
                        { name: `Add key pair`, value: 'addKeys' },
                    ]
                }]);
            switch (topMenu.cmd) {
                case 'save': {
                    config_1.storeConfig(config, '.env');
                    return;
                }
                case 'leave': {
                    console.log(`bye! Config wasn't saved`);
                    return;
                }
                case 'auth': {
                    yield setupAuth(config);
                    break;
                }
                case 'keys': {
                    yield listKeys(config, keys);
                    break;
                }
                case 'addKeys': {
                    yield addKey(keys, config);
                    break;
                }
            }
        }
    });
}
exports.setup = setup;
function validateOrg(org) {
    if (/^[\w\d_-]+$/.test(org)) {
        return true;
    }
    return `should only contain letters, numbers hyphen and underscore`;
}
function setupAuth(config) {
    return __awaiter(this, void 0, void 0, function* () {
        const info = yield inquirer_1.default.prompt([
            { type: 'input', name: 'org', default: config.org,
                message: 'What is the short name of your org?',
                validate: validateOrg },
            { type: 'input', name: 'username', default: config.username,
                message: 'What is your username (email)?',
                validate: email_validator_1.default.validate },
            { type: 'password', name: 'password', default: config.password, messsage: 'Your password?' }
        ]);
        config.org = info.org;
        config.username = info.username;
        config.password = info.password;
        console.log(`Thanks! To check if these credentials work, run proca-cli campaigns or proca-cli pages`);
        return config;
    });
}
function validateKeypart(kp) {
    const keypartRegex = /^[A-Za-z0-9_=-]+$/;
    if (kp.length == 43 && keypartRegex.test(kp)) {
        return true;
    }
    return `key part does not look right! It should be 43 chars, only A-Za-z0-9_=-`;
}
function listKeys(config, keys) {
    return __awaiter(this, void 0, void 0, function* () {
        const msgIntro = `You have ${keys.keys.length} keys in your keychain.` +
            (keys.keys.length > 0 ? ` Their public parts are (private parts not shown):` : ``);
        console.log(msgIntro);
        keys.keys.forEach((k, idx) => {
            console.log(`${idx}. ${k.public} (private key not shown)`);
            const okPub = validateKeypart(k.public);
            const okPriv = validateKeypart(k.private);
            if (okPub !== true) {
                console.warn(`  public ${okPub}`);
            }
            if (okPriv !== true) {
                console.warn(`  private ${okPriv}`);
            }
        });
        return config;
    });
}
function addKey(keys, config) {
    return __awaiter(this, void 0, void 0, function* () {
        const newKey = yield inquirer_1.default.prompt([
            { type: 'input', name: 'public', validate: validateKeypart,
                message: 'Paste public part of the key' },
            { type: 'password', name: 'private', validate: validateKeypart,
                message: 'Paste private part of the key' }
        ]);
        keys.keys.push({
            private: newKey.private,
            public: newKey.public
        });
        console.log(`Storing the new key`);
        try {
            crypto_1.storeKeys(keys);
        }
        catch (e) {
            console.error(`I cannot store the new key:`, e.message);
        }
        return keys;
    });
}
//# sourceMappingURL=setup.js.map