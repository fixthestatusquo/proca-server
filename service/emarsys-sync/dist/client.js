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

// src/client.ts
var client_exports = {};
__export(client_exports, {
  REF_FIELD: () => REF_FIELD,
  REPLY_CODE: () => REPLY_CODE,
  addContact: () => addContact,
  addToList: () => addToList,
  call: () => call,
  contactToRecord: () => contactToRecord,
  createContactList: () => createContactList,
  createField: () => createField,
  deleteContactList: () => deleteContactList,
  findContactList: () => findContactList,
  getContactByEmail: () => getContactByEmail,
  getContactById: () => getContactById,
  getContactByRef: () => getContactByRef,
  initialize: () => initialize,
  lastRequestIds: () => lastRequestIds,
  model: () => model,
  recordToContact: () => recordToContact,
  updateContact: () => updateContact
});
module.exports = __toCommonJS(client_exports);
var crypto = __toESM(require("crypto"));
var import_debug = __toESM(require("debug"));
var log = (0, import_debug.default)("sync.client");
var REPLY_CODE = {
  CONTACT_EXISTS: 2009,
  LIST_EXISTS: 3005
};
var REF_FIELD = "identifier";
function getWsseHeader(user, password) {
  let nonce = crypto.randomBytes(16).toString("hex");
  let timestamp = (/* @__PURE__ */ new Date()).toISOString();
  let digest = base64Sha1(nonce + timestamp + password);
  return `UsernameToken Username="${user}", PasswordDigest="${digest}", Nonce="${nonce}", Created="${timestamp}"`;
}
function base64Sha1(str) {
  let hexDigest = crypto.createHash("sha1").update(str).digest("hex");
  return new Buffer(hexDigest).toString("base64");
}
var lastRequestIds = {};
var call = async (path, method = "GET", data = void 0) => {
  const user = process.env.EMARSYS_USER;
  const password = process.env.EMARSYS_PASSWORD;
  if (path[0] !== "/")
    throw new Error("call(path): path must begin with /");
  const opts = {
    method,
    headers: {
      "Content-Type": "application/json",
      "X-WSSE": getWsseHeader(user, password)
    }
  };
  if (data) {
    opts.body = JSON.stringify(data);
  }
  const url = process.env.EMARSYS_URL || "https://api.emarsys.net/api/v2";
  const r = await fetch(url + path, opts);
  const body = await r.text();
  lastRequestIds[path] = r.headers.get("x-emarsys-request-id");
  try {
    if (r.status === 200 || r.status === 400) {
      return JSON.parse(body);
    } else {
      throw Error(body);
    }
  } catch (e) {
    throw Error(`API error ${e}, ${r.status}: ${r.statusText} (request ${r.headers["x-emarsys-request-id"]})`);
  }
};
var model = {
  fields: {},
  choices: {},
  keyId: 0
};
var createContactList = async (name, description = "Proca Campaign") => {
  var _a;
  const c = await call("/contactlist", "POST", {
    key_id: model.keyId,
    name,
    description
  });
  if ((_a = c.data) == null ? void 0 : _a.id) {
    return c.data.id;
  }
  return c;
};
var deleteContactList = async (id) => {
  const c = await call(`/contactlist/${id}/deletelist`, "POST");
  return c;
};
var findContactList = async (name) => {
  const lists = await call("/contactlist");
  for (const l of lists.data) {
    if (l.name === name) {
      return l.id;
    }
  }
};
var createField = async (name) => {
  const c = await call("/field", "POST", { name, application_type: "shorttext" });
  return c;
};
var initialize = async () => {
  await createField(REF_FIELD);
  const fields = await call("/field");
  for (const f of fields.data) {
    model.fields[f.string_id] = f.id;
    if (f.application_type === "singlechoice") {
      const ch = await call(`/field/${f.id}/choice/translate/en`);
      model.choices[f.string_id] = ch.data.reduce((agg, { id, choice }) => {
        agg[choice] = id;
        return agg;
      }, {});
    }
  }
  model.keyId = model.fields[REF_FIELD];
};
var contactToRecord = (contact, only) => {
  const record = { key_id: model.keyId };
  for (const f in contact) {
    if (only && f !== REF_FIELD && only.indexOf(f) < 0)
      continue;
    const v = contact[f];
    if (typeof v === "undefined")
      continue;
    const idx = model.fields[f];
    if (f in model.choices) {
      const choice_id = model.choices[f][v];
      if (choice_id) {
        record[`${idx}`] = choice_id;
      } else {
        log("Field %s: choice value %s not found", f, v);
      }
    } else {
      record[`${idx}`] = v;
    }
  }
  return record;
};
var recordToContact = (record) => {
  const idxToField = Object.entries(model.fields).reduce((acc, [k, v]) => {
    acc[v] = k;
    return acc;
  }, {});
  return Object.entries(record).reduce((agg, [k, v]) => {
    if (v === null)
      return agg;
    const kid = parseInt(k);
    if (!isNaN(kid)) {
      agg[idxToField[k]] = v;
    } else {
      agg[k] = v;
    }
    return agg;
  }, {});
};
var addToList = async (listId, contactId) => {
  const r = await call(`/contactlist/${listId}/add`, "POST", { key_id: model.keyId, external_ids: [contactId] });
  return r;
};
var addContact = async (contact, listId) => {
  const record = contactToRecord(contact);
  console.debug("Adding contact", recordToContact(record));
  if (listId) {
    record.contact_list_id = listId;
  }
  const r = await call("/contact", "POST", record);
  if (r.replyCode === REPLY_CODE.CONTACT_EXISTS) {
    const r1 = await updateContact(contact);
    const r2 = await addToList(listId, record[REF_FIELD]);
    return r1;
  } else {
    return r;
  }
};
var updateContact = async (contact, unsubscribe = false) => {
  const existing = await getContactByRef(contact[REF_FIELD]);
  if (!existing)
    throw new Error(`Cannot add nor fetch contact by ref ${contact[REF_FIELD]} ${JSON.stringify(contact, null, 2)} (GET contact id: ${lastRequestIds["/contact/getdata"]}, POST contact id: ${lastRequestIds["/contact"]})`);
  const fields = [
    "first_name",
    "last_name",
    "salutation",
    "phone",
    "address",
    "city",
    "state",
    "zip_code",
    "country",
    "registration_date"
  ];
  if (existing[0][model.fields.key1] === null) {
    fields.push("key1");
  }
  if (unsubscribe) {
    fields.push("optin");
  }
  if (fields.length > 0) {
    const update = contactToRecord(contact, fields);
    console.log(`data to update (unsub=${unsubscribe})`, update);
    const r = await call("/contact/", "PUT", update);
    return r;
  }
  return { replyCode: 0, replyText: "OK" };
};
var getContactByRef = async (ref) => {
  const c = await call("/contact/getdata", "POST", { keyId: model.keyId, keyValues: [ref] });
  return c.data.result;
};
var getContactById = async (id) => {
  const c = await call("/contact/getdata", "POST", { keyId: "id", keyValues: [id] });
  return c.data.result;
};
var getContactByEmail = async (email) => {
  const c = await call("/contact/getdata", "POST", { keyId: model.fields.email, keyValues: [email] });
  return c.data.result;
};
// Annotate the CommonJS export names for ESM import in node:
0 && (module.exports = {
  REF_FIELD,
  REPLY_CODE,
  addContact,
  addToList,
  call,
  contactToRecord,
  createContactList,
  createField,
  deleteContactList,
  findContactList,
  getContactByEmail,
  getContactById,
  getContactByRef,
  initialize,
  lastRequestIds,
  model,
  recordToContact,
  updateContact
});
