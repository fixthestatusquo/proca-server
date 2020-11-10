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
var __generator = (this && this.__generator) || function (thisArg, body) {
    var _ = { label: 0, sent: function() { if (t[0] & 1) throw t[1]; return t[1]; }, trys: [], ops: [] }, f, y, t, g;
    return g = { next: verb(0), "throw": verb(1), "return": verb(2) }, typeof Symbol === "function" && (g[Symbol.iterator] = function() { return this; }), g;
    function verb(n) { return function (v) { return step([n, v]); }; }
    function step(op) {
        if (f) throw new TypeError("Generator is already executing.");
        while (_) try {
            if (f = 1, y && (t = op[0] & 2 ? y["return"] : op[0] ? y["throw"] || ((t = y["return"]) && t.call(y), 0) : y.next) && !(t = t.call(y, op[1])).done) return t;
            if (y = 0, t) op = [op[0] & 2, t.value];
            switch (op[0]) {
                case 0: case 1: t = op; break;
                case 4: _.label++; return { value: op[1], done: false };
                case 5: _.label++; y = op[1]; op = [0]; continue;
                case 7: op = _.ops.pop(); _.trys.pop(); continue;
                default:
                    if (!(t = _.trys, t = t.length > 0 && t[t.length - 1]) && (op[0] === 6 || op[0] === 2)) { _ = 0; continue; }
                    if (op[0] === 3 && (!t || (op[1] > t[0] && op[1] < t[3]))) { _.label = op[1]; break; }
                    if (op[0] === 6 && _.label < t[1]) { _.label = t[1]; t = op; break; }
                    if (t && _.label < t[2]) { _.label = t[2]; _.ops.push(op); break; }
                    if (t[2]) _.ops.pop();
                    _.trys.pop(); continue;
            }
            op = body.call(thisArg, _);
        } catch (e) { op = [6, e]; y = 0; } finally { f = t = 0; }
        if (op[0] & 5) throw op[1]; return { value: op[0] ? op[1] : void 0, done: true };
    }
};
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
exports.__esModule = true;
exports.setup = void 0;
var inquirer_1 = __importDefault(require("inquirer"));
var email_validator_1 = __importDefault(require("email-validator"));
var config_1 = require("./config");
var crypto_1 = require("./crypto");
function setup(config) {
    return __awaiter(this, void 0, void 0, function () {
        var msgHello, keys, msgAuthStatus, msgKeyStatus, topMenu, _a;
        return __generator(this, function (_b) {
            switch (_b.label) {
                case 0:
                    msgHello = "Hello!\n\n" +
                        ("- Using current working directory: " + process.cwd() + "\n") +
                        (config.envFile ?
                            "- I have read settings from .env file" :
                            "- There is not .env file - I will create it after asking You some questions");
                    console.log(msgHello);
                    keys = null;
                    try {
                        keys = crypto_1.loadKeys(config);
                    }
                    catch (errorLoadingKeys) {
                        console.warn("- I can't load keys, because", errorLoadingKeys.message);
                        console.warn("  You might want to use setup to add the keys.");
                        keys = {
                            keys: [],
                            readFromFile: true,
                            filename: "keys.json"
                        };
                    }
                    _b.label = 1;
                case 1:
                    if (!true) return [3 /*break*/, 12];
                    msgAuthStatus = (config.org ? "org is " + config.org : "no org set") + ', ' +
                        (config.username ? "user is: " + config.username : "user is not set up") + ', ' +
                        (config.password ? "password is set" : "password is not set");
                    msgKeyStatus = keys === null ?
                        "keys are not loaded" :
                        (keys.keys.length + " keys loaded" + (keys.readFromFile ?
                            " from file " + keys.filename :
                            " from KEYS var"));
                    console.log("\n");
                    return [4 /*yield*/, inquirer_1["default"].prompt([{
                                type: 'list',
                                message: 'What would you like to do?',
                                name: 'cmd',
                                choices: [
                                    { name: "Save current config to .env file and leave", value: 'save' },
                                    { name: "Just leave", value: 'leave' },
                                    { name: "Set up authentication (" + msgAuthStatus + ")", value: 'auth' },
                                    { name: "List and verify keys (" + msgKeyStatus + ")", value: 'keys' },
                                    { name: "Add key pair", value: 'addKeys' },
                                ]
                            }])];
                case 2:
                    topMenu = _b.sent();
                    _a = topMenu.cmd;
                    switch (_a) {
                        case 'save': return [3 /*break*/, 3];
                        case 'leave': return [3 /*break*/, 4];
                        case 'auth': return [3 /*break*/, 5];
                        case 'keys': return [3 /*break*/, 7];
                        case 'addKeys': return [3 /*break*/, 9];
                    }
                    return [3 /*break*/, 11];
                case 3:
                    {
                        config_1.storeConfig(config, '.env');
                        return [2 /*return*/];
                    }
                    _b.label = 4;
                case 4:
                    {
                        console.log("bye! Config wasn't saved");
                        return [2 /*return*/];
                    }
                    _b.label = 5;
                case 5: return [4 /*yield*/, setupAuth(config)];
                case 6:
                    _b.sent();
                    return [3 /*break*/, 11];
                case 7: return [4 /*yield*/, listKeys(config, keys)];
                case 8:
                    _b.sent();
                    return [3 /*break*/, 11];
                case 9: return [4 /*yield*/, addKey(keys, config)];
                case 10:
                    _b.sent();
                    return [3 /*break*/, 11];
                case 11: return [3 /*break*/, 1];
                case 12: return [2 /*return*/];
            }
        });
    });
}
exports.setup = setup;
function validateOrg(org) {
    if (/^[\w\d_-]+$/.test(org)) {
        return true;
    }
    return "should only contain letters, numbers hyphen and underscore";
}
function setupAuth(config) {
    return __awaiter(this, void 0, void 0, function () {
        var info;
        return __generator(this, function (_a) {
            switch (_a.label) {
                case 0: return [4 /*yield*/, inquirer_1["default"].prompt([
                        { type: 'input', name: 'org', "default": config.org,
                            message: 'What is the short name of your org?',
                            validate: validateOrg },
                        { type: 'input', name: 'username', "default": config.username,
                            message: 'What is your username (email)?',
                            validate: email_validator_1["default"].validate },
                        { type: 'password', name: 'password', "default": config.password, messsage: 'Your password?' }
                    ])];
                case 1:
                    info = _a.sent();
                    config.org = info.org;
                    config.username = info.username;
                    config.password = info.password;
                    console.log("Thanks! To check if these credentials work, run proca-cli campaigns or proca-cli pages");
                    return [2 /*return*/, config];
            }
        });
    });
}
function validateKeypart(kp) {
    var keypartRegex = /^[A-Za-z0-9_=-]+$/;
    if (kp.length == 43 && keypartRegex.test(kp)) {
        return true;
    }
    return "key part does not look right! It should be 43 chars, only A-Za-z0-9_=-";
}
function listKeys(config, keys) {
    return __awaiter(this, void 0, void 0, function () {
        var msgIntro;
        return __generator(this, function (_a) {
            msgIntro = "You have " + keys.keys.length + " keys in your keychain." +
                (keys.keys.length > 0 ? " Their public parts are (private parts not shown):" : "");
            console.log(msgIntro);
            keys.keys.forEach(function (k, idx) {
                console.log(idx + ". " + k.public + " (private key not shown)");
                var okPub = validateKeypart(k.public);
                var okPriv = validateKeypart(k.private);
                if (okPub !== true) {
                    console.warn("  public " + okPub);
                }
                if (okPriv !== true) {
                    console.warn("  private " + okPriv);
                }
            });
            return [2 /*return*/, config];
        });
    });
}
function addKey(keys, config) {
    return __awaiter(this, void 0, void 0, function () {
        var newKey;
        return __generator(this, function (_a) {
            switch (_a.label) {
                case 0: return [4 /*yield*/, inquirer_1["default"].prompt([
                        { type: 'input', name: 'public', validate: validateKeypart,
                            message: 'Paste public part of the key' },
                        { type: 'password', name: 'private', validate: validateKeypart,
                            message: 'Paste private part of the key' }
                    ])];
                case 1:
                    newKey = _a.sent();
                    keys.keys.push({
                        private: newKey.private,
                        public: newKey.public
                    });
                    console.log("Storing the new key");
                    try {
                        crypto_1.storeKeys(keys);
                    }
                    catch (e) {
                        console.error("I cannot store the new key:", e.message);
                    }
                    return [2 /*return*/, keys];
            }
        });
    });
}
