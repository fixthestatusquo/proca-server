"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
exports.__esModule = true;
exports.getContact = exports.decryptAction = exports.decrypt = exports.storeKeys = exports.loadKeys = void 0;
var tweetnacl_1 = __importDefault(require("tweetnacl"));
var tweetnacl_util_1 = require("tweetnacl-util");
var base64url_1 = __importDefault(require("base64url"));
var fs_1 = require("fs");
function readMixedFormat(ks, keys) {
    for (var _i = 0, _a = Object.entries(keys); _i < _a.length; _i++) {
        var _b = _a[_i], key = _b[0], value = _b[1];
        if (typeof key !== "string")
            throw new Error("keys must be a map keyed by public key");
        if (typeof value == "string")
            ks.keys.push({ public: key, private: value });
        if (typeof value == "object") {
            if (typeof value.private !== "string")
                throw new Error("keys must be a map with values containing private key");
            ks.keys.push({ public: key, private: value.private });
        }
    }
    return ks;
}
function loadKeys(config) {
    if (config.keyData[0] === '{') {
        // in env-memory key list -----------------------
        var ks = {
            filename: null,
            readFromFile: false,
            keys: []
        };
        var kd = JSON.parse(config.keyData);
        return readMixedFormat(ks, kd);
    }
    else {
        // filename -------------------------------------
        var ks = {
            filename: config.keyData,
            readFromFile: true,
            keys: []
        };
        var kd = JSON.parse(fs_1.readFileSync(ks.filename, 'utf8'));
        return readMixedFormat(ks, kd);
    }
}
exports.loadKeys = loadKeys;
function storeKeys(ks) {
    var data = ks.keys.reduce(function (m, k) {
        m[k.public] = { private: k.private };
        return m;
    }, {});
    var content = JSON.stringify(data, null, 2);
    fs_1.writeFileSync(ks.filename, content, { mode: 384 });
}
exports.storeKeys = storeKeys;
function base64url2normal(s) {
    return tweetnacl_util_1.decodeBase64(base64url_1["default"].toBase64(s));
}
function decrypt(payload, nonce, public_key, sign_key, keys) {
    if (!nonce) {
        return payload; // decrypted
    }
    if (!(public_key && sign_key)) {
        throw new Error("Tried to decrypt a payload providing null public_key or sign_key");
    }
    var privIdx = keys.keys.findIndex(function (k) { return k.public == public_key.public; });
    if (privIdx < 0)
        return null;
    var privPair = keys.keys[privIdx];
    var priv = base64url2normal(privPair.private);
    var pub = base64url2normal(sign_key.public);
    // decrypt
    var clear = tweetnacl_1["default"].box.open(base64url2normal(payload), base64url2normal(nonce), pub, priv);
    if (clear === null) {
        throw new Error("decrypting payload returned null (payload " + payload + ")");
    }
    else {
        return tweetnacl_util_1.encodeUTF8(clear);
    }
}
exports.decrypt = decrypt;
function decryptAction(action, argv, config) {
    var pii = getContact(action.contact, argv, config);
    action.contact.pii = pii;
    return action;
}
exports.decryptAction = decryptAction;
function getContact(contact, argv, config) {
    var payload = contact.payload, nonce = contact.nonce, publicKey = contact.publicKey, signKey = contact.signKey;
    if (payload === undefined)
        throw new Error("action contact has no payload: " + JSON.stringify(contact));
    if (publicKey === null || publicKey === undefined) {
        // plain text
        return JSON.parse(payload);
    }
    if (!argv.decrypt)
        return {};
    var ks = loadKeys(config);
    var clear = decrypt(payload, nonce, publicKey, signKey, ks);
    if (clear === null) {
        if (argv.ignore) {
            return {};
        }
        else {
            throw new Error("Cannot decrypt action data encrypted for key " + JSON.stringify(publicKey));
        }
    }
    return JSON.parse(clear);
}
exports.getContact = getContact;
