import { KeyStore } from "@proca/crypto";
import { ActionMessageV2 } from "./actionMessage";
import { EventMessageV2 } from "./eventMessage";

export type DecryptOpts = {
  decrypt?: boolean;
  ignore?: boolean;
};

export type ConsumerOpts = {
  concurrency?: number; // 1 by default
  prefetch?: number; // 2x concurrency by default
  keyStore?: KeyStore;
  tag?: string; // custom name for the consumer, package name by default
};

export type SyncResult = {
  processed: boolean;
}

export type SyncCallback = (action: ActionMessageV2 | EventMessageV2) => Promise<SyncResult | boolean>;
