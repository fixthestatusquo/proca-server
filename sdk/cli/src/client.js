"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
const api_1 = require("@proca/api");
function getClient(config) {
    let a = null;
    if (config.username && config.password) {
        a = api_1.basicAuth(config);
    }
    let c = api_1.link(config.url, a);
    return c;
}
exports.default = getClient;
//# sourceMappingURL=client.js.map