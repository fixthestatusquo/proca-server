var __create = Object.create;
var __defProp = Object.defineProperty;
var __getOwnPropDesc = Object.getOwnPropertyDescriptor;
var __getOwnPropNames = Object.getOwnPropertyNames;
var __getProtoOf = Object.getPrototypeOf;
var __hasOwnProp = Object.prototype.hasOwnProperty;
var __export = (target, all) => {
  for (var name in all)
    __defProp(target, name, { get: all[name], enumerable: true });
};
var __copyProps = (to, from, except, desc) => {
  if (from && typeof from === "object" || typeof from === "function") {
    for (let key of __getOwnPropNames(from))
      if (!__hasOwnProp.call(to, key) && key !== except)
        __defProp(to, key, { get: () => from[key], enumerable: !(desc = __getOwnPropDesc(from, key)) || desc.enumerable });
  }
  return to;
};
var __toESM = (mod, isNodeMode, target) => (target = mod != null ? __create(__getProtoOf(mod)) : {}, __copyProps(
  // If the importer is in node compatibility mode or this is not an ESM
  // file that has been converted to a CommonJS file using a Babel-
  // compatible transform (i.e. "__esModule" has not been set), then set
  // "default" to the CommonJS "module.exports" for node compatibility.
  isNodeMode || !mod || !mod.__esModule ? __defProp(target, "default", { value: mod, enumerable: true }) : target,
  mod
));
var __toCommonJS = (mod) => __copyProps(__defProp({}, "__esModule", { value: true }), mod);

// src/contact.ts
var contact_exports = {};
__export(contact_exports, {
  FALSE: () => FALSE,
  TRUE: () => TRUE,
  actionToContact: () => actionToContact,
  eventToContact: () => eventToContact,
  getCountry: () => getCountry,
  isFalse: () => isFalse,
  isTrue: () => isTrue
});
module.exports = __toCommonJS(contact_exports);
var import_i18n_iso_countries = __toESM(require("i18n-iso-countries"));
var import_en = __toESM(require("i18n-iso-countries/langs/en.json"));
import_en.default.countries["NL"] = "The Netherlands";
import_i18n_iso_countries.default.registerLocale(import_en.default);
var getCountry = (c) => import_i18n_iso_countries.default.getName(c, "en");
var TRUE = 1;
var FALSE = 2;
var isTrue = (v) => v === 1 || typeof v === "string" && parseInt(v) === 1;
var isFalse = (v) => v === 2 || typeof v === "string" && parseInt(v) === 2;
var eventToContact = (msg) => {
  if (msg.eventType === "email_status") {
    const c = msg.supporter.contact;
    const p = msg.supporter.privacy;
    if (p.emailStatus === null)
      return null;
    const optIn = msg.supporter.privacy.emailStatus === "double_opt_in";
    const record = {
      identifier: c.contactRef,
      optin: optIn ? TRUE : FALSE
    };
    return record;
  }
  return null;
};
var actionToContact = (msg) => {
  var _a, _b, _c;
  const c = msg.contact;
  const ap = msg.actionPage;
  let optin = void 0;
  switch (msg.privacy.emailStatus) {
    case "double_opt_in": {
      optin = TRUE;
      break;
    }
    case "spam":
    case "unsub":
    case "blocked":
    case "bounce": {
      optin = FALSE;
    }
    default: {
      if (msg.privacy.optIn === false) {
        optin = FALSE;
      }
    }
  }
  const country = c.country ? import_i18n_iso_countries.default.getName(c.country.toUpperCase(), "en") : void 0;
  let salutation = void 0;
  switch (msg.action.customFields.salutation) {
    case "m": {
      salutation = "Mr.";
      break;
    }
    case "f": {
      salutation = "Ms.";
      break;
    }
    case "other": {
      salutation = "Mx.";
      break;
    }
    default: {
      salutation = null;
      break;
    }
  }
  const record = {
    first_name: c.firstName,
    last_name: c.lastName,
    salutation,
    email: c.email,
    identifier: c.contactRef,
    phone: c.phone,
    address: (_a = c.address) == null ? void 0 : _a.street,
    city: (_b = c.address) == null ? void 0 : _b.locality,
    state: (_c = c.address) == null ? void 0 : _c.region,
    zip_code: c.postcode,
    country,
    ietf_language_tag: ap.locale.replace("_", "-"),
    // ietf format eg en-US
    optin,
    key1: "proca"
    //   registration_date: msg.action.createdAt.split('T')[0] // YYYY-MM-DD
  };
  if (record.first_name === "supporter")
    record.first_name = "";
  return record;
};
// Annotate the CommonJS export names for ESM import in node:
0 && (module.exports = {
  FALSE,
  TRUE,
  actionToContact,
  eventToContact,
  getCountry,
  isFalse,
  isTrue
});
