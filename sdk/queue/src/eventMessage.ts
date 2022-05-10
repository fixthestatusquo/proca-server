import {ContactV2, PrivacyV2} from './actionMessage'

export type EmailStatusEvent = {
  eventType: 'email_status';
  supporter: {
    contact: ContactV2;
    privacy: PrivacyV2;
  }
}

export type EventMessageV2 = {
  schema: 'proca:event:2',
  timestamp: string,
} & EmailStatusEvent
