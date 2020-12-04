import { types } from '@proca/api';
import { KeyStore } from './crypto';
export interface FormatOpts {
    org?: string;
    json?: boolean;
    csv?: boolean;
    campaign?: string;
    fields?: string;
}
interface OrgDetails {
    title?: string;
    name: string;
}
declare class Terminal {
    org: string;
    constructor(options: FormatOpts);
    campaign(c: types.Campaign): string;
    actionPage(ap: types.ActionPage | types.PublicActionPage, org: any): string;
    addAPkeysToConfig(ap: types.ActionPage, org: OrgDetails): any;
    addConfigKeysToAP(ap: types.ActionPageInput): types.ActionPageInput;
    action(a: types.Action): string;
    hasPublicKey(key: types.Key, keyStore: KeyStore): boolean;
    key(k: types.Key, keys: KeyStore): string;
    error(err: any): any;
}
export declare function getFormatter(argv: FormatOpts): Terminal;
export {};
