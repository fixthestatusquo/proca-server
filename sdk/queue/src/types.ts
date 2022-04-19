import {KeyStore} from '@proca/crypto'
import {ActionMessageV2} from './actionMessage'
import {Message} from 'amqplib'

export type DecryptOpts = {
  decrypt?: boolean,
  ignore?: boolean
}

export type QueueOpts = {
  prefetch?: number;
  keyStore?: KeyStore;
}

export type SyncCallback = (action : ActionMessageV2, msg? : Message) => Promise<any>
