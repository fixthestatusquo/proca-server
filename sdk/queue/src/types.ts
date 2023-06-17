import { KeyStore } from "@proca/crypto";
import { ActionMessageV2 } from "./actionMessage";
import { EventMessageV2 } from "./eventMessage";

export type DecryptOpts = {
  decrypt?: boolean;
  ignore?: boolean;
};

export type ConsumerOpts = {
  concurrency?: number; // 1 if not set
  // prefetch? number; // 2xconcurrency
  keyStore?: KeyStore;
};

export type SyncCallback = (action: ActionMessageV2 | EventMessageV2) => Promise<any>;
