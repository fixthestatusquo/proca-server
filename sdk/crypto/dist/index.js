"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.decrypt = exports.decryptPersonalInfo = exports.decodeBase64url = exports.addKeysToKeyStore = exports.loadKeyStoreFromString = exports.storeKeyStoreToFile = exports.loadKeyStoreFromFile = void 0;
const tweetnacl_1 = __importDefault(require("tweetnacl"));
const tweetnacl_util_1 = require("tweetnacl-util");
const base64url_1 = __importDefault(require("base64url"));
const lodash_1 = __importDefault(require("lodash"));
var utils_1 = require("./utils");
Object.defineProperty(exports, "loadKeyStoreFromFile", { enumerable: true, get: function () { return utils_1.loadKeyStoreFromFile; } });
Object.defineProperty(exports, "storeKeyStoreToFile", { enumerable: true, get: function () { return utils_1.storeKeyStoreToFile; } });
Object.defineProperty(exports, "loadKeyStoreFromString", { enumerable: true, get: function () { return utils_1.loadKeyStoreFromString; } });
function addKeysToKeyStore(keys, ks) {
    if (typeof keys !== "object")
        throw new Error("key store must be object");
    for (let [key, value] of Object.entries(keys)) {
        if (typeof key !== "string")
            throw new Error("keys must be a map keyed by public key");
        if (typeof value === "object" &&
            'private' in value &&
            typeof value.private === "string") {
            ks.keys.push({ public: key, private: value.private });
        }
        else {
            throw new Error("keys must be a map with values containing private key");
        }
    }
    ks.keys = lodash_1.default.uniqBy(ks.keys, "public");
    return true;
}
exports.addKeysToKeyStore = addKeysToKeyStore;
function decodeBase64url(s) {
    return (0, tweetnacl_util_1.decodeBase64)(base64url_1.default.toBase64(s));
}
exports.decodeBase64url = decodeBase64url;
function decryptPersonalInfo(pii, keyStore) {
    if (!pii) {
        return {}; // decrypted
    }
    if (!(pii.encryptKey && pii.signKey && pii.nonce)) {
        throw new Error("Tried to decrypt a payload providing null public_key or sign_key");
    }
    const privIdx = keyStore.keys.findIndex((k) => k.public == pii.encryptKey.public);
    if (privIdx < 0)
        return null;
    const privPair = keyStore.keys[privIdx];
    const clear = decrypt(pii.payload, pii.nonce, privPair.private, pii.signKey.public);
    return JSON.parse(clear);
}
exports.decryptPersonalInfo = decryptPersonalInfo;
// decrypt and verify a payload with nonce, encryption key private side, signing key public side
function decrypt(ciphertext, nonce, encPriv, signPub) {
    const priv = decodeBase64url(encPriv);
    const pub = decodeBase64url(signPub);
    const n = decodeBase64url(nonce);
    const p = decodeBase64url(ciphertext);
    // decrypt
    const clear = tweetnacl_1.default.box.open(p, n, pub, priv);
    if (clear === null) {
        throw new Error(`decrypting ciphertext returned null (ciphertext ${ciphertext})`);
    }
    else {
        return (0, tweetnacl_util_1.encodeUTF8)(clear);
    }
}
exports.decrypt = decrypt;
//# sourceMappingURL=index.js.map