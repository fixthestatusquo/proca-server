import mailjet from "node-mailjet";
import { actionMessage } from '../queueMessage';
import { CliConfig } from '../config';
declare type argv = {
    queueName: string;
    decrypt: boolean;
    service: string;
    service_url: string;
};
export declare function syncAction(action: actionMessage, argv: argv, config: CliConfig): Promise<mailjet.Email.Response>;
export declare function connect(): mailjet.Email.Client;
export declare function varsFromAction(action: actionMessage): {
    first_name: string;
    email: string;
    ref: string;
    campaign_name: string;
    campaign_title: string;
    action_page_name: string;
};
export {};
