import { FormatOpts } from './format';
import { CliConfig } from './config';
export declare function listCampaigns(argv: FormatOpts, config: CliConfig): Promise<void>;
interface IdOpt {
    id?: number;
}
export declare function getCampaign(argv: IdOpt & FormatOpts, config: CliConfig): Promise<void>;
export declare function listActionPages(argv: FormatOpts, config: CliConfig): Promise<void>;
interface GetActionPageOpts {
    name?: string;
    id?: number;
    public: boolean;
}
export declare function getActionPage(argv: GetActionPageOpts & FormatOpts, config: CliConfig): Promise<void>;
interface UpdateActionPageOpts {
    id: number;
    name?: string;
    config?: string;
    tytpl?: string;
    extra?: number;
}
export declare function updateActionPage(argv: UpdateActionPageOpts & FormatOpts, config: CliConfig): Promise<void>;
export {};
