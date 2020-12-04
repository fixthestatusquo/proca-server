/// <reference types="node" />
export declare type CliConfig = {
    org?: string;
    username?: string;
    password?: string;
    queue_url?: string;
    identity_url?: string;
    identity_api_token?: string;
    identity_consent?: string;
    identity_action_fields?: string[];
    identity_contact_fields?: string[];
    service_url?: string;
    url: string;
    keyData?: string;
    envFile?: boolean;
    verbose?: boolean;
};
export declare function load(): CliConfig;
export declare function loadFromEnv(env?: NodeJS.ProcessEnv): CliConfig;
export declare function storeConfig(config: CliConfig, file_name: string): void;
export declare type WidgetConfig = {
    actionpage: number;
    lang: string;
    journey: string[];
    filename: string;
    organisation: string;
};
