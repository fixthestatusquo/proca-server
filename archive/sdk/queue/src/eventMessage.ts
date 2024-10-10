import {ContactV2, PrivacyV2, Campaign, ActionV2, ActionPage, Tracking} from './actionMessage'

export type EmailStatusEvent = {
  eventType: 'email_status';
  action?: ActionV2;
  actionPage?: ActionPage;
  campaign?: Campaign;
  supporter: {
    contact: ContactV2;
    privacy: PrivacyV2;
  },
  tracking?: Tracking;
}

export type EventMessageV2 = {
  schema: 'proca:event:2',
  timestamp: string,
} & EmailStatusEvent
