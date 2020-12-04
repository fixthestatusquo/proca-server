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
exports.varsFromAction = exports.connect = exports.syncAction = void 0;
const node_mailjet_1 = __importDefault(require("node-mailjet"));
function syncAction(action, argv, config) {
    return __awaiter(this, void 0, void 0, function* () {
        const conn = connect();
        const tmplId = process.env['MAILJET_TEMPLATE'] || action.actionPage.thankYouTemplateRef;
        if (!tmplId)
            throw new Error('No MAILJET_TEMPLATE set not thankYouTemplateRef on action page');
        const vars = varsFromAction(action);
        // console.log(vars)
        let res = yield conn.post("send").request({
            FromEmail: 'noreply@proca.app',
            FromName: 'Is this correct',
            'Mj-TemplateID': tmplId,
            'Mj-TemplateLanguage': true,
            Recipients: [{ 'Email': 'marcin@cahoots.pl', 'Vars': vars }]
        });
        return res;
    });
}
exports.syncAction = syncAction;
function connect() {
    const mjKey = process.env['MAILJET_KEY'];
    const mjSec = process.env['MAILJET_SECRET'];
    if (!mjKey || !mjSec) {
        throw new Error('No MAILJET_KEY or MAILJET_SECRET set');
    }
    const conn = node_mailjet_1.default.connect(mjKey, mjSec);
    return conn;
}
exports.connect = connect;
function varsFromAction(action) {
    let vars = {
        first_name: action.contact ? action.contact.firstName : null,
        email: action.contact ? action.contact.email : null,
        ref: action.contact ? action.contact.ref : null,
        campaign_name: action.campaign ? action.campaign.name : null,
        campaign_title: action.campaign ? action.campaign.title : null,
        action_page_name: action.actionPage ? action.actionPage.name : null,
    };
    if (action.tracking) {
        vars = Object.assign(vars, {
            utm_source: action.tracking.source,
            utm_medium: action.tracking.medium,
            utm_campaign: action.tracking.campaign,
            utm_content: action.tracking.content
        });
    }
    vars = Object.assign(vars, action.action.fields);
    return vars;
}
exports.varsFromAction = varsFromAction;
//# sourceMappingURL=email.js.map