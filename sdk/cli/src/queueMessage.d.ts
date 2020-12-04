declare type contact = {
    email: string;
    firstName: string;
    ref: string;
    payload: string;
};
declare type campaign = {
    title: string;
    name: string;
    externalId: number;
};
declare type actionPage = {
    locale: string;
    name: string;
    thankYouTemplateRef: string;
};
declare type action = {
    actionType: string;
    fields: {
        [key: string]: string;
    };
};
declare type tracking = {
    source: string;
    medium: string;
    campaign: string;
    content: string;
};
export declare type actionMessage = {
    actionId: number;
    actionPageId: number;
    campaignId: number;
    orgId: number;
    action: action;
    contact: contact;
    campaign: campaign;
    actionPage: actionPage;
    tracking: tracking;
};
export {};
