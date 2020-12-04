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
exports.updateActionPage = exports.getActionPage = exports.listActionPages = exports.getCampaign = exports.listCampaigns = void 0;
const client_1 = __importDefault(require("./client"));
const api_1 = require("@proca/api");
const format_1 = require("./format");
const fs_1 = __importDefault(require("fs"));
function listCampaigns(argv, config) {
    return __awaiter(this, void 0, void 0, function* () {
        const c = client_1.default(config);
        const fmt = format_1.getFormatter(argv);
        const result = yield api_1.request(c, api_1.admin.ListCampaignsDocument, { "org": config.org });
        result.data.org.campaigns
            .map(c => fmt.campaign(c))
            .forEach((c) => {
            console.log(c);
        });
    });
}
exports.listCampaigns = listCampaigns;
function getCampaign(argv, config) {
    return __awaiter(this, void 0, void 0, function* () {
        const c = client_1.default(config);
        const fmt = format_1.getFormatter(argv);
        const { data, errors } = yield api_1.request(c, api_1.admin.GetCampaignDocument, { "org": config.org, "id": argv.id });
        if (errors)
            throw errors;
        console.log(fmt.campaign(data.org.campaign));
    });
}
exports.getCampaign = getCampaign;
function listActionPages(argv, config) {
    return __awaiter(this, void 0, void 0, function* () {
        const c = client_1.default(config);
        const fmt = format_1.getFormatter(argv);
        const { data, errors } = yield api_1.request(c, api_1.admin.ListActionPagesDocument, { "org": config.org });
        if (errors)
            throw errors;
        data.org.actionPages
            .map(ap => fmt.actionPage(ap, data.org))
            .forEach((ap) => { console.log(ap); });
    });
}
exports.listActionPages = listActionPages;
function getActionPage(argv, config) {
    return __awaiter(this, void 0, void 0, function* () {
        const c = client_1.default(config);
        const fmt = format_1.getFormatter(argv);
        let vars = {};
        let t = null;
        if (argv.name)
            vars.name = argv.name;
        if (argv.id)
            vars.id = argv.id;
        if (argv.public)
            vars.org = config.org;
        if (argv.public) {
            const { data, errors } = yield api_1.request(c, api_1.widget.GetActionPageDocument, vars);
            if (errors)
                throw errors;
            t = fmt.actionPage(data.actionPage, data.actionPage.org);
        }
        else {
            const { data, errors } = yield api_1.request(c, api_1.admin.GetActionPageDocument, vars);
            if (errors)
                throw errors;
            t = fmt.actionPage(data.org.actionPage, data.org);
        }
        console.log(t);
    });
}
exports.getActionPage = getActionPage;
function updateActionPage(argv, config) {
    return __awaiter(this, void 0, void 0, function* () {
        const c = client_1.default(config);
        const fmt = format_1.getFormatter(argv);
        let json = null;
        // json
        if (argv.config) {
            if (argv.config[0] == '{') {
                json = argv.config;
            }
            else {
                json = fs_1.default.readFileSync(argv.config, 'utf8');
            }
        }
        let actionPage = {
            name: argv.name,
            thankYouTemplateRef: argv.tytpl,
            extraSupporters: argv.extra,
            config: json
        };
        if (argv.json) {
            actionPage = fmt.addConfigKeysToAP(actionPage);
        }
        // DEBUG
        // console.debug(`updateActionPage(${JSON.stringify(ap_in)})`)
        const { errors } = yield api_1.request(c, api_1.admin.UpdateActionPageDocument, { id: argv.id, actionPage });
        if (errors) {
            throw errors;
        }
    });
}
exports.updateActionPage = updateActionPage;
//# sourceMappingURL=campaign.js.map