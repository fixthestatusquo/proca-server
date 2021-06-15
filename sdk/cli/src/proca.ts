import { TypedDocumentNode as DocumentNode } from '@graphql-typed-document-node/core';
export type Maybe<T> = T | null;
export type Exact<T extends { [key: string]: unknown }> = { [K in keyof T]: T[K] };
export type MakeOptional<T, K extends keyof T> = Omit<T, K> & { [SubKey in K]?: Maybe<T[SubKey]> };
export type MakeMaybe<T, K extends keyof T> = Omit<T, K> & { [SubKey in K]: Maybe<T[SubKey]> };
/** All built-in and custom scalars, mapped to their actual values */
export type Scalars = {
  ID: string;
  String: string;
  Boolean: boolean;
  Int: number;
  Float: number;
  /**
   * The `Date` scalar type represents a date. The Date appears in a JSON
   * response as an ISO8601 formatted string, without a time component.
   */
  Date: any;
  /**
   * The `DateTime` scalar type represents a date and time in the UTC
   * timezone. The DateTime appears in a JSON response as an ISO8601 formatted
   * string, including UTC timezone ("Z"). The parsed date and time string will
   * be converted to UTC if there is an offset.
   */
  DateTime: any;
  /**
   * The `Decimal` scalar type represents signed double-precision fractional
   * values parsed by the `Decimal` library.  The Decimal appears in a JSON
   * response as a string to preserve precision.
   */
  Decimal: any;
  Json: any;
  /**
   * The `Naive DateTime` scalar type represents a naive date and time without
   * timezone. The DateTime appears in a JSON response as an ISO8601 formatted
   * string.
   */
  NaiveDateTime: any;
};

export type Action = {
  __typename?: 'Action';
  actionId: Scalars['Int'];
  createdAt: Scalars['NaiveDateTime'];
  actionType: Scalars['String'];
  contact: Contact;
  fields: Array<CustomField>;
  tracking: Maybe<Tracking>;
  campaign: Campaign;
  actionPage: ActionPage;
  privacy: Consent;
  donation: Maybe<Donation>;
};

export type ActionCustomFields = {
  __typename?: 'ActionCustomFields';
  actionId: Scalars['Int'];
  actionType: Scalars['String'];
  insertedAt: Scalars['NaiveDateTime'];
  fields: Array<CustomField>;
};

/** Custom field added to action. For signature it can be contact, for mail it can be subject and body */
export type ActionInput = {
  /** Action Type */
  actionType: Scalars['String'];
  /** Other fields that accompany the signature */
  fields?: Maybe<Array<CustomFieldInput>>;
  /** Donation payload */
  donation?: Maybe<DonationActionInput>;
};

export type ActionPage = {
  id: Scalars['Int'];
  /** Locale for the widget, in i18n format */
  locale: Scalars['String'];
  /** Name where the widget is hosted */
  name: Scalars['String'];
  /** Reference to thank you email templated of this Action Page */
  thankYouTemplateRef: Maybe<Scalars['String']>;
  /** Is live? */
  live: Scalars['Boolean'];
  /** List of steps in journey */
  journey: Array<Scalars['String']>;
  /** Config JSON of this action page */
  config: Scalars['Json'];
  /** Campaign this action page belongs to. */
  campaign: Campaign;
  /** Org the action page belongs to */
  org: Org;
};

/** ActionPage input */
export type ActionPageInput = {
  /**
   * Unique NAME identifying ActionPage.
   *
   * Does not have to exist, must be unique. Can be a 'technical' identifier
   * scoped to particular organization, so it does not have to change when the
   * slugs/names change (eg. some.org/1234). However, frontent Widget can
   * ask for ActionPage by it's current location.href (but without https://), in which case it is useful
   * to make this url match the real widget location.
   */
  name?: Maybe<Scalars['String']>;
  /** 2-letter, lowercase, code of ActionPage language */
  locale?: Maybe<Scalars['String']>;
  /** A reference to thank you email template of this ActionPage */
  thankYouTemplateRef?: Maybe<Scalars['String']>;
  /** Extra supporter count. If you want to add a number of signatories you have offline or kept in another system, you can specify the number here. */
  extraSupporters?: Maybe<Scalars['Int']>;
  /** List of steps in the journey */
  journey?: Maybe<Array<Scalars['String']>>;
  /** JSON string containing Action Page config */
  config?: Maybe<Scalars['Json']>;
};

/** Count of actions for particular action type */
export type ActionTypeCount = {
  __typename?: 'ActionTypeCount';
  /** action type */
  actionType: Scalars['String'];
  /** count of actions of action type */
  count: Scalars['Int'];
};

export type ActivateKeyResult = {
  __typename?: 'ActivateKeyResult';
  status: Status;
};

export type AddKeyInput = {
  name: Scalars['String'];
  public: Scalars['String'];
};

/** Address type which can hold different addres fields. */
export type AddressInput = {
  /** Country code (two-letter). */
  country?: Maybe<Scalars['String']>;
  /** Postcode, in format correct for country locale */
  postcode?: Maybe<Scalars['String']>;
  /** Locality, which can be a city/town/village */
  locality?: Maybe<Scalars['String']>;
  /** Region, being province, voyevodship, county */
  region?: Maybe<Scalars['String']>;
  /** Street name */
  street?: Maybe<Scalars['String']>;
  /** Street number */
  streetNumber?: Maybe<Scalars['String']>;
};

/** Count of actions for particular action type */
export type AreaCount = {
  __typename?: 'AreaCount';
  /** area */
  area: Scalars['String'];
  /** count of supporters in this area */
  count: Scalars['Int'];
};

/** Filter campaigns by id. If found, returns list of 1 campaign, otherwise an empty list */
export type Campaign = {
  /** Campaign id */
  id: Scalars['Int'];
  /** External ID (if set) */
  externalId: Maybe<Scalars['Int']>;
  /** Internal name of the campaign */
  name: Scalars['String'];
  /** Full, official name of the campaign */
  title: Scalars['String'];
  /** Schema for contact personal information */
  contactSchema: ContactSchema;
  /** Custom config map */
  config: Scalars['Json'];
  /** Campaign statistics */
  stats: CampaignStats;
  org: Org;
  /** Fetch public actions */
  actions: PublicActionsResult;
};


/** Filter campaigns by id. If found, returns list of 1 campaign, otherwise an empty list */
export type CampaignActionsArgs = {
  actionType: Scalars['String'];
  limit: Scalars['Int'];
};

/** Campaign input */
export type CampaignInput = {
  /** Campaign unchanging identifier */
  name: Scalars['String'];
  /** Campaign external_id. If provided, it will be used to find campaign. Can be used to rename a campaign */
  externalId?: Maybe<Scalars['Int']>;
  /** Campaign human readable title */
  title?: Maybe<Scalars['String']>;
  /** Schema for contact personal information */
  contactSchema?: Maybe<ContactSchema>;
  /** Custom config as stringified JSON map */
  config?: Maybe<Scalars['Json']>;
  /** Action pages of this campaign */
  actionPages: Array<ActionPageInput>;
};

/** Campaign statistics */
export type CampaignStats = {
  __typename?: 'CampaignStats';
  /** Unique action tagers count */
  supporterCount: Scalars['Int'];
  /** Unique action takers by area */
  supporterCountByArea: Array<AreaCount>;
  /** Unique action takers by org */
  supporterCountByOrg: Array<OrgCount>;
  supporterCountByOthers: Scalars['Int'];
  /** Action counts for selected action types */
  actionCount: Array<ActionTypeCount>;
};


/** Campaign statistics */
export type CampaignStatsSupporterCountByOthersArgs = {
  orgName: Scalars['String'];
};

export type ChangeUserStatus = {
  __typename?: 'ChangeUserStatus';
  status: Status;
};

export type Confirm = {
  __typename?: 'Confirm';
  code: Scalars['String'];
  email: Maybe<Scalars['String']>;
  objectId: Maybe<Scalars['Int']>;
};

export type ConfirmInput = {
  code: Scalars['String'];
  email?: Maybe<Scalars['String']>;
  objectId?: Maybe<Scalars['Int']>;
};

export type ConfirmResult = {
  __typename?: 'ConfirmResult';
  status: Status;
  actionPage: Maybe<ActionPage>;
  campaign: Maybe<Campaign>;
  org: Maybe<Org>;
};

/** GDPR consent data for this org */
export type Consent = {
  __typename?: 'Consent';
  optIn: Scalars['Boolean'];
  givenAt: Scalars['NaiveDateTime'];
};

/** GDPR consent data structure */
export type ConsentInput = {
  /** Has contact consented to receiving communication from widget owner? */
  optIn: Scalars['Boolean'];
  /** Opt in to the campaign leader */
  leadOptIn?: Maybe<Scalars['Boolean']>;
};

export type Contact = {
  __typename?: 'Contact';
  contactRef: Scalars['ID'];
  payload: Scalars['String'];
  nonce: Maybe<Scalars['String']>;
  publicKey: Maybe<KeyIds>;
  signKey: Maybe<KeyIds>;
};

/** Contact information */
export type ContactInput = {
  /** Full name */
  name?: Maybe<Scalars['String']>;
  /** First name (when you provide full name split into first and last) */
  firstName?: Maybe<Scalars['String']>;
  /** Last name (when you provide full name split into first and last) */
  lastName?: Maybe<Scalars['String']>;
  /** Email */
  email?: Maybe<Scalars['String']>;
  /** Contacts phone number */
  phone?: Maybe<Scalars['String']>;
  /** Date of birth in format YYYY-MM-DD */
  birthDate?: Maybe<Scalars['Date']>;
  /** Contacts address */
  address?: Maybe<AddressInput>;
  /** Nationality information */
  nationality?: Maybe<NationalityInput>;
};

export type ContactReference = {
  __typename?: 'ContactReference';
  /** Contact's reference */
  contactRef: Scalars['String'];
  /** Contacts first name */
  firstName: Maybe<Scalars['String']>;
};

export enum ContactSchema {
  Basic = 'BASIC',
  PopularInitiative = 'POPULAR_INITIATIVE',
  Eci = 'ECI',
  ItCi = 'IT_CI'
}

/** Custom field with a key and value. */
export type CustomField = {
  __typename?: 'CustomField';
  key: Scalars['String'];
  value: Scalars['String'];
};

/** Custom field with a key and value. Both are strings. */
export type CustomFieldInput = {
  key: Scalars['String'];
  value: Scalars['String'];
  transient?: Maybe<Scalars['Boolean']>;
};




export type DeleteUserResult = {
  __typename?: 'DeleteUserResult';
  status: Status;
};

export type Donation = {
  __typename?: 'Donation';
  schema: Maybe<DonationSchema>;
  /** Provide amount of this donation */
  amount: Scalars['Decimal'];
  /** Provide currency of this donation */
  currency: Scalars['String'];
  /** Donation data */
  payload: Scalars['Json'];
  /** Donation frequency unit */
  frequencyUnit: DonationFrequencyUnit;
};

export type DonationActionInput = {
  /** Provide payload schema to validate, eg. stripe_payment_intent */
  schema?: Maybe<DonationSchema>;
  /** Provide amount of this donation */
  amount?: Maybe<Scalars['Decimal']>;
  /** Provide currency of this donation */
  currency?: Maybe<Scalars['String']>;
  frequencyUnit?: Maybe<DonationFrequencyUnit>;
  payload: Scalars['Json'];
};

export enum DonationFrequencyUnit {
  OneOff = 'ONE_OFF',
  Weekly = 'WEEKLY',
  Monthly = 'MONTHLY'
}

export enum DonationSchema {
  StripePaymentIntent = 'STRIPE_PAYMENT_INTENT'
}

export type GenKeyInput = {
  name: Scalars['String'];
};

export type JoinOrgResult = {
  __typename?: 'JoinOrgResult';
  status: Status;
  org: Org;
};


/** Encryption or sign key with integer id (database) */
export type Key = {
  __typename?: 'Key';
  id: Scalars['Int'];
  public: Scalars['String'];
  name: Scalars['String'];
  active: Scalars['Boolean'];
  expired: Scalars['Boolean'];
  /** When the key was expired, in UTC */
  expiredAt: Maybe<Scalars['NaiveDateTime']>;
};

export type KeyIds = {
  __typename?: 'KeyIds';
  id: Scalars['Int'];
  public: Scalars['String'];
};

export type KeyWithPrivate = {
  __typename?: 'KeyWithPrivate';
  id: Scalars['Int'];
  public: Scalars['String'];
  private: Scalars['String'];
  name: Scalars['String'];
  active: Scalars['Boolean'];
  expired: Scalars['Boolean'];
  /** When the key was expired, in UTC */
  expiredAt: Maybe<Scalars['NaiveDateTime']>;
};

export type LaunchActionPageResult = {
  __typename?: 'LaunchActionPageResult';
  status: Status;
};


export type NationalityInput = {
  /** Nationality / issuer of id document */
  country: Scalars['String'];
  /** Document type */
  documentType?: Maybe<Scalars['String']>;
  /** Document serial id/number */
  documentNumber?: Maybe<Scalars['String']>;
};

export type Org = {
  /** Organisation short name */
  name: Scalars['String'];
  /** Organisation title (human readable name) */
  title: Scalars['String'];
};

/** Count of supporters for particular org */
export type OrgCount = {
  __typename?: 'OrgCount';
  /** org */
  org: Org;
  /** count of supporters registered by org */
  count: Scalars['Int'];
};

export type OrgInput = {
  /** Name used to rename */
  name?: Maybe<Scalars['String']>;
  /** Organisation title (human readable name) */
  title?: Maybe<Scalars['String']>;
  /** Schema for contact personal information */
  contactSchema?: Maybe<ContactSchema>;
  /** Email opt in enabled */
  emailOptIn?: Maybe<Scalars['Boolean']>;
  /** Email opt in template name */
  emailOptInTemplate?: Maybe<Scalars['String']>;
  /** Config */
  config?: Maybe<Scalars['Json']>;
};

export type OrgUser = {
  __typename?: 'OrgUser';
  email: Scalars['String'];
  role: Scalars['String'];
  createdAt: Scalars['NaiveDateTime'];
  joinedAt: Scalars['NaiveDateTime'];
  lastSigninAt: Maybe<Scalars['NaiveDateTime']>;
};

export type Partnership = {
  __typename?: 'Partnership';
  org: Org;
  actionPages: Array<ActionPage>;
  launchRequests: Array<Confirm>;
};

export type PersonalData = {
  __typename?: 'PersonalData';
  /** Schema for contact personal information */
  contactSchema: ContactSchema;
  /** Email opt in enabled */
  emailOptIn: Scalars['Boolean'];
  /** Email opt in template name */
  emailOptInTemplate: Maybe<Scalars['String']>;
};

export type PrivateActionPage = ActionPage & {
  __typename?: 'PrivateActionPage';
  id: Scalars['Int'];
  /** Locale for the widget, in i18n format */
  locale: Scalars['String'];
  /** Name where the widget is hosted */
  name: Scalars['String'];
  /** Reference to thank you email templated of this Action Page */
  thankYouTemplateRef: Maybe<Scalars['String']>;
  /** Is live? */
  live: Scalars['Boolean'];
  /** List of steps in journey */
  journey: Array<Scalars['String']>;
  /** Config JSON of this action page */
  config: Scalars['Json'];
  /** Campaign this action page belongs to. */
  campaign: Campaign;
  /** Org the action page belongs to */
  org: Org;
  extraSupporters: Scalars['Int'];
  /** Action page collects also opt-out actions */
  delivery: Scalars['Boolean'];
};

export type PrivateCampaign = Campaign & {
  __typename?: 'PrivateCampaign';
  /** Campaign id */
  id: Scalars['Int'];
  /** External ID (if set) */
  externalId: Maybe<Scalars['Int']>;
  /** Internal name of the campaign */
  name: Scalars['String'];
  /** Full, official name of the campaign */
  title: Scalars['String'];
  /** Schema for contact personal information */
  contactSchema: ContactSchema;
  /** Custom config map */
  config: Scalars['Json'];
  /** Campaign statistics */
  stats: CampaignStats;
  org: Org;
  /** Fetch public actions */
  actions: PublicActionsResult;
  /** Campaign onwer collects opt-out actions for delivery even if campaign partner is */
  forceDelivery: Scalars['Boolean'];
  /** List of partnerships and requests */
  partnerships: Maybe<Array<Partnership>>;
};


export type PrivateCampaignActionsArgs = {
  actionType: Scalars['String'];
  limit: Scalars['Int'];
};

export type PrivateOrg = Org & {
  __typename?: 'PrivateOrg';
  /** Organisation short name */
  name: Scalars['String'];
  /** Organisation title (human readable name) */
  title: Scalars['String'];
  /** Organization id */
  id: Scalars['Int'];
  /** config */
  config: Scalars['Json'];
  /** Personal data settings for this org */
  personalData: PersonalData;
  keys: Array<Key>;
  key: Key;
  services: Array<Maybe<Service>>;
  users: Array<Maybe<OrgUser>>;
  /** List campaigns this org is leader or partner of */
  campaigns: Array<Campaign>;
  /** List action pages this org has */
  actionPages: Array<ActionPage>;
  /** Action Page */
  actionPage: ActionPage;
  /** Get campaign this org is leader or partner of by id */
  campaign: Campaign;
};


export type PrivateOrgKeysArgs = {
  select?: Maybe<SelectKey>;
};


export type PrivateOrgKeyArgs = {
  select: SelectKey;
};


export type PrivateOrgServicesArgs = {
  select?: Maybe<SelectService>;
};


export type PrivateOrgCampaignsArgs = {
  select?: Maybe<SelectCampaign>;
};


export type PrivateOrgActionPagesArgs = {
  select?: Maybe<SelectActionPage>;
};


export type PrivateOrgActionPageArgs = {
  id?: Maybe<Scalars['Int']>;
  name?: Maybe<Scalars['String']>;
};


export type PrivateOrgCampaignArgs = {
  id?: Maybe<Scalars['Int']>;
};

export type PublicActionPage = ActionPage & {
  __typename?: 'PublicActionPage';
  id: Scalars['Int'];
  /** Locale for the widget, in i18n format */
  locale: Scalars['String'];
  /** Name where the widget is hosted */
  name: Scalars['String'];
  /** Reference to thank you email templated of this Action Page */
  thankYouTemplateRef: Maybe<Scalars['String']>;
  /** Is live? */
  live: Scalars['Boolean'];
  /** List of steps in journey */
  journey: Array<Scalars['String']>;
  /** Config JSON of this action page */
  config: Scalars['Json'];
  /** Campaign this action page belongs to. */
  campaign: Campaign;
  /** Org the action page belongs to */
  org: Org;
};

/** Result of actions query */
export type PublicActionsResult = {
  __typename?: 'PublicActionsResult';
  fieldKeys: Maybe<Array<Scalars['String']>>;
  list: Maybe<Array<Maybe<ActionCustomFields>>>;
};

export type PublicCampaign = Campaign & {
  __typename?: 'PublicCampaign';
  /** Campaign id */
  id: Scalars['Int'];
  /** External ID (if set) */
  externalId: Maybe<Scalars['Int']>;
  /** Internal name of the campaign */
  name: Scalars['String'];
  /** Full, official name of the campaign */
  title: Scalars['String'];
  /** Schema for contact personal information */
  contactSchema: ContactSchema;
  /** Custom config map */
  config: Scalars['Json'];
  /** Campaign statistics */
  stats: CampaignStats;
  org: Org;
  /** Fetch public actions */
  actions: PublicActionsResult;
};


export type PublicCampaignActionsArgs = {
  actionType: Scalars['String'];
  limit: Scalars['Int'];
};

export type PublicOrg = Org & {
  __typename?: 'PublicOrg';
  /** Organisation short name */
  name: Scalars['String'];
  /** Organisation title (human readable name) */
  title: Scalars['String'];
};

export type RootMutationType = {
  __typename?: 'RootMutationType';
  /**
   * Upserts a campaign.
   *
   * Creates or appends campaign and it's action pages. In case of append, it
   * will change the campaign with the matching name, and action pages with
   * matching names. It will create new action pages if you pass new names. No
   * Action Pages will be removed (principle of not removing signature data).
   */
  upsertCampaign: Campaign;
  /** Update an Action Page */
  updateActionPage: ActionPage;
  /**
   * Adds a new Action Page based on another Action Page. Intended to be used to
   * create a partner action page based off lead's one. Copies: campaign, locale, journey, config, delivery flag
   */
  copyActionPage: ActionPage;
  /**
   * Adds a new Action Page based on latest Action Page from campaign. Intended to be used to
   * create a partner action page based off lead's one. Copies: campaign, locale, journey, config, delivery flag
   */
  copyCampaignActionPage: ActionPage;
  launchActionPage: LaunchActionPageResult;
  /** Adds an action referencing contact data via contactRef */
  addAction: ContactReference;
  /** Adds an action with contact data */
  addActionContact: ContactReference;
  /** Link actions with refs to contact with contact reference */
  linkActions: ContactReference;
  addOrgUser: ChangeUserStatus;
  updateOrgUser: ChangeUserStatus;
  deleteOrgUser: Maybe<DeleteUserResult>;
  addOrg: Org;
  deleteOrg: Scalars['Boolean'];
  updateOrg: Org;
  joinOrg: JoinOrgResult;
  generateKey: KeyWithPrivate;
  addKey: Key;
  /** A separate key activate operation, because you also need to add the key to receiving system before it is used */
  activateKey: ActivateKeyResult;
  addStripePaymentIntent: Scalars['Json'];
  addStripeSubscription: Scalars['Json'];
  /**
   * Create stripe object using Stripe key associated with action page owning org.
   * Pass any of paymentIntent, subscription, customer, price json params to be sent as-is to Stripe API. The result is a JSON returned by Stripe API or a GraphQL Error object.
   * If you provide customer along payment intent or subscription, it will be first created, then their id will be added to params for the payment intent or subscription, so you can pack 2 Stripe API calls into one. You can do the same with price object in case of a subscription.
   */
  addStripeObject: Scalars['Json'];
  /** Accept a confirm on behalf of organisation. */
  acceptOrgConfirm: ConfirmResult;
  /** Reject a confirm on behalf of organisation. */
  rejectOrgConfirm: ConfirmResult;
};


export type RootMutationTypeUpsertCampaignArgs = {
  orgName: Scalars['String'];
  input: CampaignInput;
};


export type RootMutationTypeUpdateActionPageArgs = {
  id: Scalars['Int'];
  input: ActionPageInput;
};


export type RootMutationTypeCopyActionPageArgs = {
  orgName: Scalars['String'];
  name: Scalars['String'];
  fromName: Scalars['String'];
};


export type RootMutationTypeCopyCampaignActionPageArgs = {
  orgName: Scalars['String'];
  name: Scalars['String'];
  fromCampaignName: Scalars['String'];
};


export type RootMutationTypeLaunchActionPageArgs = {
  name: Scalars['String'];
};


export type RootMutationTypeAddActionArgs = {
  actionPageId: Scalars['Int'];
  action: ActionInput;
  contactRef: Scalars['ID'];
  tracking?: Maybe<TrackingInput>;
};


export type RootMutationTypeAddActionContactArgs = {
  actionPageId: Scalars['Int'];
  action: ActionInput;
  contact: ContactInput;
  privacy: ConsentInput;
  tracking?: Maybe<TrackingInput>;
  contactRef?: Maybe<Scalars['ID']>;
};


export type RootMutationTypeLinkActionsArgs = {
  actionPageId: Scalars['Int'];
  contactRef: Scalars['ID'];
  linkRefs?: Maybe<Array<Scalars['String']>>;
};


export type RootMutationTypeAddOrgUserArgs = {
  orgName: Scalars['String'];
  input: UserInput;
};


export type RootMutationTypeUpdateOrgUserArgs = {
  orgName: Scalars['String'];
  input: UserInput;
};


export type RootMutationTypeDeleteOrgUserArgs = {
  orgName: Scalars['String'];
  email: Scalars['String'];
};


export type RootMutationTypeAddOrgArgs = {
  input: OrgInput;
};


export type RootMutationTypeDeleteOrgArgs = {
  name: Scalars['String'];
};


export type RootMutationTypeUpdateOrgArgs = {
  name: Scalars['String'];
  input: OrgInput;
};


export type RootMutationTypeJoinOrgArgs = {
  name: Scalars['String'];
};


export type RootMutationTypeGenerateKeyArgs = {
  orgName: Scalars['String'];
  input: GenKeyInput;
};


export type RootMutationTypeAddKeyArgs = {
  orgName: Scalars['String'];
  input: AddKeyInput;
};


export type RootMutationTypeActivateKeyArgs = {
  orgName: Scalars['String'];
  id: Scalars['Int'];
};


export type RootMutationTypeAddStripePaymentIntentArgs = {
  actionPageId: Scalars['Int'];
  input: StripePaymentIntentInput;
  contactRef?: Maybe<Scalars['ID']>;
};


export type RootMutationTypeAddStripeSubscriptionArgs = {
  actionPageId: Scalars['Int'];
  input: StripeSubscriptionInput;
  contactRef?: Maybe<Scalars['ID']>;
};


export type RootMutationTypeAddStripeObjectArgs = {
  actionPageId: Scalars['Int'];
  paymentIntent?: Maybe<Scalars['Json']>;
  subscription?: Maybe<Scalars['Json']>;
  customer?: Maybe<Scalars['Json']>;
  price?: Maybe<Scalars['Json']>;
};


export type RootMutationTypeAcceptOrgConfirmArgs = {
  name: Scalars['String'];
  confirm: ConfirmInput;
};


export type RootMutationTypeRejectOrgConfirmArgs = {
  name: Scalars['String'];
  confirm: ConfirmInput;
};

export type RootQueryType = {
  __typename?: 'RootQueryType';
  /** Get a list of campains */
  campaigns: Array<Campaign>;
  /** Get action page */
  actionPage: ActionPage;
  exportActions: Array<Maybe<Action>>;
  currentUser: User;
  /** Organization api (authenticated) */
  org: PrivateOrg;
};


export type RootQueryTypeCampaignsArgs = {
  title?: Maybe<Scalars['String']>;
  name?: Maybe<Scalars['String']>;
};


export type RootQueryTypeActionPageArgs = {
  id?: Maybe<Scalars['Int']>;
  name?: Maybe<Scalars['String']>;
};


export type RootQueryTypeExportActionsArgs = {
  orgName: Scalars['String'];
  campaignName?: Maybe<Scalars['String']>;
  campaignId?: Maybe<Scalars['Int']>;
  start?: Maybe<Scalars['Int']>;
  after?: Maybe<Scalars['DateTime']>;
  limit?: Maybe<Scalars['Int']>;
  onlyOptIn?: Maybe<Scalars['Boolean']>;
};


export type RootQueryTypeOrgArgs = {
  name: Scalars['String'];
};

export type RootSubscriptionType = {
  __typename?: 'RootSubscriptionType';
  actionPageUpserted: ActionPage;
};


export type RootSubscriptionTypeActionPageUpsertedArgs = {
  orgName?: Maybe<Scalars['String']>;
};

export type SelectActionPage = {
  campaignId?: Maybe<Scalars['Int']>;
};

export type SelectCampaign = {
  id?: Maybe<Scalars['Int']>;
};

export type SelectKey = {
  id?: Maybe<Scalars['Int']>;
  active?: Maybe<Scalars['Boolean']>;
  public?: Maybe<Scalars['String']>;
};

export type SelectService = {
  name?: Maybe<ServiceName>;
};

export type Service = {
  __typename?: 'Service';
  id: Scalars['Int'];
  name: ServiceName;
  host: Maybe<Scalars['String']>;
  user: Maybe<Scalars['String']>;
  path: Maybe<Scalars['String']>;
};

export enum ServiceName {
  Ses = 'SES',
  Sqs = 'SQS',
  Mailjet = 'MAILJET',
  Wordpress = 'WORDPRESS',
  Stripe = 'STRIPE'
}

export enum Status {
  /** Operation completed succesfully */
  Success = 'SUCCESS',
  /** Operation awaiting confirmation */
  Confirming = 'CONFIRMING',
  /** Operation had no effect (already done) */
  Noop = 'NOOP'
}

export type StripePaymentIntentInput = {
  amount: Scalars['Float'];
  currency: Scalars['String'];
  paymentMethodTypes?: Maybe<Array<Scalars['String']>>;
};

export type StripeSubscriptionInput = {
  amount: Scalars['Float'];
  currency: Scalars['String'];
  frequencyUnit: DonationFrequencyUnit;
};

/** Tracking codes */
export type Tracking = {
  __typename?: 'Tracking';
  source: Scalars['String'];
  medium: Scalars['String'];
  campaign: Scalars['String'];
  content: Scalars['String'];
};

/** Tracking codes */
export type TrackingInput = {
  source: Scalars['String'];
  medium: Scalars['String'];
  campaign: Scalars['String'];
  content?: Maybe<Scalars['String']>;
};

export type User = {
  __typename?: 'User';
  id: Scalars['Int'];
  email: Scalars['String'];
  roles: Array<UserRole>;
};

export type UserInput = {
  email: Scalars['String'];
  role: Scalars['String'];
};

export type UserRole = {
  __typename?: 'UserRole';
  org: Org;
  role: Scalars['String'];
};

export const CampaignFields = {"kind":"Document","definitions":[{"kind":"FragmentDefinition","name":{"kind":"Name","value":"campaignFields"},"typeCondition":{"kind":"NamedType","name":{"kind":"Name","value":"Campaign"}},"selectionSet":{"kind":"SelectionSet","selections":[{"kind":"Field","name":{"kind":"Name","value":"__typename"}},{"kind":"Field","name":{"kind":"Name","value":"id"}},{"kind":"Field","name":{"kind":"Name","value":"externalId"}},{"kind":"Field","name":{"kind":"Name","value":"name"}},{"kind":"Field","name":{"kind":"Name","value":"title"}},{"kind":"Field","name":{"kind":"Name","value":"contactSchema"}},{"kind":"Field","name":{"kind":"Name","value":"config"}}]}}]} as unknown as DocumentNode<CampaignFields, unknown>;
export const CampaignPrivateFields = {"kind":"Document","definitions":[{"kind":"FragmentDefinition","name":{"kind":"Name","value":"campaignPrivateFields"},"typeCondition":{"kind":"NamedType","name":{"kind":"Name","value":"PrivateCampaign"}},"selectionSet":{"kind":"SelectionSet","selections":[{"kind":"Field","name":{"kind":"Name","value":"__typename"}},{"kind":"Field","name":{"kind":"Name","value":"forceDelivery"}}]}}]} as unknown as DocumentNode<CampaignPrivateFields, unknown>;
export const CampaignAllStats = {"kind":"Document","definitions":[{"kind":"FragmentDefinition","name":{"kind":"Name","value":"campaignAllStats"},"typeCondition":{"kind":"NamedType","name":{"kind":"Name","value":"Campaign"}},"selectionSet":{"kind":"SelectionSet","selections":[{"kind":"Field","name":{"kind":"Name","value":"stats"},"selectionSet":{"kind":"SelectionSet","selections":[{"kind":"Field","name":{"kind":"Name","value":"supporterCount"}},{"kind":"Field","name":{"kind":"Name","value":"supporterCountByOrg"},"selectionSet":{"kind":"SelectionSet","selections":[{"kind":"Field","name":{"kind":"Name","value":"org"},"selectionSet":{"kind":"SelectionSet","selections":[{"kind":"Field","name":{"kind":"Name","value":"name"}},{"kind":"Field","name":{"kind":"Name","value":"title"}}]}},{"kind":"Field","name":{"kind":"Name","value":"count"}}]}},{"kind":"Field","name":{"kind":"Name","value":"actionCount"},"selectionSet":{"kind":"SelectionSet","selections":[{"kind":"Field","name":{"kind":"Name","value":"actionType"}},{"kind":"Field","name":{"kind":"Name","value":"count"}}]}}]}}]}}]} as unknown as DocumentNode<CampaignAllStats, unknown>;
export const OrgIds = {"kind":"Document","definitions":[{"kind":"FragmentDefinition","name":{"kind":"Name","value":"orgIds"},"typeCondition":{"kind":"NamedType","name":{"kind":"Name","value":"Org"}},"selectionSet":{"kind":"SelectionSet","selections":[{"kind":"Field","name":{"kind":"Name","value":"__typename"}},{"kind":"Field","name":{"kind":"Name","value":"name"}},{"kind":"Field","name":{"kind":"Name","value":"title"}},{"kind":"InlineFragment","typeCondition":{"kind":"NamedType","name":{"kind":"Name","value":"PrivateOrg"}},"selectionSet":{"kind":"SelectionSet","selections":[{"kind":"Field","name":{"kind":"Name","value":"id"}}]}}]}}]} as unknown as DocumentNode<OrgIds, unknown>;
export const ActionPageFields = {"kind":"Document","definitions":[{"kind":"FragmentDefinition","name":{"kind":"Name","value":"actionPageFields"},"typeCondition":{"kind":"NamedType","name":{"kind":"Name","value":"ActionPage"}},"selectionSet":{"kind":"SelectionSet","selections":[{"kind":"Field","name":{"kind":"Name","value":"__typename"}},{"kind":"Field","name":{"kind":"Name","value":"id"}},{"kind":"Field","name":{"kind":"Name","value":"name"}},{"kind":"Field","name":{"kind":"Name","value":"locale"}},{"kind":"Field","name":{"kind":"Name","value":"config"}},{"kind":"Field","name":{"kind":"Name","value":"live"}},{"kind":"Field","name":{"kind":"Name","value":"journey"}},{"kind":"Field","name":{"kind":"Name","value":"thankYouTemplateRef"}}]}}]} as unknown as DocumentNode<ActionPageFields, unknown>;
export const CampaignPartnerships = {"kind":"Document","definitions":[{"kind":"FragmentDefinition","name":{"kind":"Name","value":"campaignPartnerships"},"typeCondition":{"kind":"NamedType","name":{"kind":"Name","value":"PrivateCampaign"}},"selectionSet":{"kind":"SelectionSet","selections":[{"kind":"Field","name":{"kind":"Name","value":"__typename"}},{"kind":"Field","name":{"kind":"Name","value":"partnerships"},"selectionSet":{"kind":"SelectionSet","selections":[{"kind":"Field","name":{"kind":"Name","value":"org"},"selectionSet":{"kind":"SelectionSet","selections":[{"kind":"FragmentSpread","name":{"kind":"Name","value":"orgIds"}}]}},{"kind":"Field","name":{"kind":"Name","value":"actionPages"},"selectionSet":{"kind":"SelectionSet","selections":[{"kind":"FragmentSpread","name":{"kind":"Name","value":"actionPageFields"}}]}},{"kind":"Field","name":{"kind":"Name","value":"launchRequests"},"selectionSet":{"kind":"SelectionSet","selections":[{"kind":"Field","name":{"kind":"Name","value":"code"}},{"kind":"Field","name":{"kind":"Name","value":"email"}},{"kind":"Field","name":{"kind":"Name","value":"objectId"}}]}}]}}]}},...OrgIds.definitions,...ActionPageFields.definitions]} as unknown as DocumentNode<CampaignPartnerships, unknown>;
export const CampaignOverview = {"kind":"Document","definitions":[{"kind":"FragmentDefinition","name":{"kind":"Name","value":"CampaignOverview"},"typeCondition":{"kind":"NamedType","name":{"kind":"Name","value":"PrivateCampaign"}},"selectionSet":{"kind":"SelectionSet","selections":[{"kind":"FragmentSpread","name":{"kind":"Name","value":"campaignFields"}},{"kind":"FragmentSpread","name":{"kind":"Name","value":"campaignPrivateFields"}},{"kind":"FragmentSpread","name":{"kind":"Name","value":"campaignAllStats"}},{"kind":"Field","name":{"kind":"Name","value":"org"},"selectionSet":{"kind":"SelectionSet","selections":[{"kind":"FragmentSpread","name":{"kind":"Name","value":"orgIds"}}]}},{"kind":"FragmentSpread","name":{"kind":"Name","value":"campaignPartnerships"}}]}},...CampaignFields.definitions,...CampaignPrivateFields.definitions,...CampaignAllStats.definitions,...OrgIds.definitions,...CampaignPartnerships.definitions]} as unknown as DocumentNode<CampaignOverview, unknown>;
export const CampaignIds = {"kind":"Document","definitions":[{"kind":"FragmentDefinition","name":{"kind":"Name","value":"campaignIds"},"typeCondition":{"kind":"NamedType","name":{"kind":"Name","value":"Campaign"}},"selectionSet":{"kind":"SelectionSet","selections":[{"kind":"Field","name":{"kind":"Name","value":"__typename"}},{"kind":"Field","name":{"kind":"Name","value":"id"}},{"kind":"Field","name":{"kind":"Name","value":"externalId"}},{"kind":"Field","name":{"kind":"Name","value":"name"}},{"kind":"Field","name":{"kind":"Name","value":"title"}}]}}]} as unknown as DocumentNode<CampaignIds, unknown>;
export const ActionPageOwners = {"kind":"Document","definitions":[{"kind":"FragmentDefinition","name":{"kind":"Name","value":"actionPageOwners"},"typeCondition":{"kind":"NamedType","name":{"kind":"Name","value":"ActionPage"}},"selectionSet":{"kind":"SelectionSet","selections":[{"kind":"FragmentSpread","name":{"kind":"Name","value":"actionPageFields"}},{"kind":"Field","name":{"kind":"Name","value":"campaign"},"selectionSet":{"kind":"SelectionSet","selections":[{"kind":"FragmentSpread","name":{"kind":"Name","value":"campaignIds"}},{"kind":"Field","name":{"kind":"Name","value":"org"},"selectionSet":{"kind":"SelectionSet","selections":[{"kind":"FragmentSpread","name":{"kind":"Name","value":"orgIds"}}]}}]}},{"kind":"Field","name":{"kind":"Name","value":"org"},"selectionSet":{"kind":"SelectionSet","selections":[{"kind":"FragmentSpread","name":{"kind":"Name","value":"orgIds"}}]}}]}},...ActionPageFields.definitions,...CampaignIds.definitions,...OrgIds.definitions]} as unknown as DocumentNode<ActionPageOwners, unknown>;
export const CampaignExportIds = {"kind":"Document","definitions":[{"kind":"FragmentDefinition","name":{"kind":"Name","value":"campaignExportIds"},"typeCondition":{"kind":"NamedType","name":{"kind":"Name","value":"Campaign"}},"selectionSet":{"kind":"SelectionSet","selections":[{"kind":"Field","name":{"kind":"Name","value":"__typename"}},{"kind":"Field","name":{"kind":"Name","value":"name"}},{"kind":"Field","name":{"kind":"Name","value":"externalId"}}]}}]} as unknown as DocumentNode<CampaignExportIds, unknown>;
export const ActionPageIds = {"kind":"Document","definitions":[{"kind":"FragmentDefinition","name":{"kind":"Name","value":"actionPageIds"},"typeCondition":{"kind":"NamedType","name":{"kind":"Name","value":"ActionPage"}},"selectionSet":{"kind":"SelectionSet","selections":[{"kind":"Field","name":{"kind":"Name","value":"id"}},{"kind":"Field","name":{"kind":"Name","value":"name"}},{"kind":"Field","name":{"kind":"Name","value":"locale"}}]}}]} as unknown as DocumentNode<ActionPageIds, unknown>;
export const ActionPagePrivateFields = {"kind":"Document","definitions":[{"kind":"FragmentDefinition","name":{"kind":"Name","value":"actionPagePrivateFields"},"typeCondition":{"kind":"NamedType","name":{"kind":"Name","value":"PrivateActionPage"}},"selectionSet":{"kind":"SelectionSet","selections":[{"kind":"Field","name":{"kind":"Name","value":"__typename"}},{"kind":"Field","name":{"kind":"Name","value":"extraSupporters"}},{"kind":"Field","name":{"kind":"Name","value":"delivery"}}]}}]} as unknown as DocumentNode<ActionPagePrivateFields, unknown>;
export const OrgFields = {"kind":"Document","definitions":[{"kind":"FragmentDefinition","name":{"kind":"Name","value":"orgFields"},"typeCondition":{"kind":"NamedType","name":{"kind":"Name","value":"Org"}},"selectionSet":{"kind":"SelectionSet","selections":[{"kind":"Field","name":{"kind":"Name","value":"__typename"}},{"kind":"Field","name":{"kind":"Name","value":"name"}},{"kind":"Field","name":{"kind":"Name","value":"title"}}]}}]} as unknown as DocumentNode<OrgFields, unknown>;
export const OrgPrivateFields = {"kind":"Document","definitions":[{"kind":"FragmentDefinition","name":{"kind":"Name","value":"orgPrivateFields"},"typeCondition":{"kind":"NamedType","name":{"kind":"Name","value":"PrivateOrg"}},"selectionSet":{"kind":"SelectionSet","selections":[{"kind":"Field","name":{"kind":"Name","value":"__typename"}},{"kind":"Field","name":{"kind":"Name","value":"config"}},{"kind":"Field","name":{"kind":"Name","value":"personalData"},"selectionSet":{"kind":"SelectionSet","selections":[{"kind":"Field","name":{"kind":"Name","value":"contactSchema"}},{"kind":"Field","name":{"kind":"Name","value":"emailOptIn"}},{"kind":"Field","name":{"kind":"Name","value":"emailOptInTemplate"}}]}}]}}]} as unknown as DocumentNode<OrgPrivateFields, unknown>;
export const KeyFields = {"kind":"Document","definitions":[{"kind":"FragmentDefinition","name":{"kind":"Name","value":"keyFields"},"typeCondition":{"kind":"NamedType","name":{"kind":"Name","value":"Key"}},"selectionSet":{"kind":"SelectionSet","selections":[{"kind":"Field","name":{"kind":"Name","value":"id"}},{"kind":"Field","name":{"kind":"Name","value":"name"}},{"kind":"Field","name":{"kind":"Name","value":"public"}},{"kind":"Field","name":{"kind":"Name","value":"active"}},{"kind":"Field","name":{"kind":"Name","value":"expired"}},{"kind":"Field","name":{"kind":"Name","value":"expiredAt"}}]}}]} as unknown as DocumentNode<KeyFields, unknown>;
export const ServiceFields = {"kind":"Document","definitions":[{"kind":"FragmentDefinition","name":{"kind":"Name","value":"serviceFields"},"typeCondition":{"kind":"NamedType","name":{"kind":"Name","value":"Service"}},"selectionSet":{"kind":"SelectionSet","selections":[{"kind":"Field","name":{"kind":"Name","value":"id"}},{"kind":"Field","name":{"kind":"Name","value":"name"}},{"kind":"Field","name":{"kind":"Name","value":"host"}},{"kind":"Field","name":{"kind":"Name","value":"user"}},{"kind":"Field","name":{"kind":"Name","value":"path"}}]}}]} as unknown as DocumentNode<ServiceFields, unknown>;
export const ContactExport = {"kind":"Document","definitions":[{"kind":"FragmentDefinition","name":{"kind":"Name","value":"contactExport"},"typeCondition":{"kind":"NamedType","name":{"kind":"Name","value":"Contact"}},"selectionSet":{"kind":"SelectionSet","selections":[{"kind":"Field","name":{"kind":"Name","value":"contactRef"}},{"kind":"Field","name":{"kind":"Name","value":"payload"}},{"kind":"Field","name":{"kind":"Name","value":"nonce"}},{"kind":"Field","name":{"kind":"Name","value":"publicKey"},"selectionSet":{"kind":"SelectionSet","selections":[{"kind":"Field","name":{"kind":"Name","value":"id"}},{"kind":"Field","name":{"kind":"Name","value":"public"}}]}},{"kind":"Field","name":{"kind":"Name","value":"signKey"},"selectionSet":{"kind":"SelectionSet","selections":[{"kind":"Field","name":{"kind":"Name","value":"id"}},{"kind":"Field","name":{"kind":"Name","value":"public"}}]}}]}}]} as unknown as DocumentNode<ContactExport, unknown>;
export const ActionExport = {"kind":"Document","definitions":[{"kind":"FragmentDefinition","name":{"kind":"Name","value":"actionExport"},"typeCondition":{"kind":"NamedType","name":{"kind":"Name","value":"Action"}},"selectionSet":{"kind":"SelectionSet","selections":[{"kind":"Field","name":{"kind":"Name","value":"actionId"}},{"kind":"Field","name":{"kind":"Name","value":"actionType"}},{"kind":"Field","name":{"kind":"Name","value":"createdAt"}},{"kind":"Field","name":{"kind":"Name","value":"contact"},"selectionSet":{"kind":"SelectionSet","selections":[{"kind":"FragmentSpread","name":{"kind":"Name","value":"contactExport"}}]}},{"kind":"Field","name":{"kind":"Name","value":"fields"},"selectionSet":{"kind":"SelectionSet","selections":[{"kind":"Field","name":{"kind":"Name","value":"key"}},{"kind":"Field","name":{"kind":"Name","value":"value"}}]}},{"kind":"Field","name":{"kind":"Name","value":"tracking"},"selectionSet":{"kind":"SelectionSet","selections":[{"kind":"Field","name":{"kind":"Name","value":"source"}},{"kind":"Field","name":{"kind":"Name","value":"medium"}},{"kind":"Field","name":{"kind":"Name","value":"campaign"}},{"kind":"Field","name":{"kind":"Name","value":"content"}}]}},{"kind":"Field","name":{"kind":"Name","value":"privacy"},"selectionSet":{"kind":"SelectionSet","selections":[{"kind":"Field","name":{"kind":"Name","value":"optIn"}},{"kind":"Field","name":{"kind":"Name","value":"givenAt"}}]}}]}},...ContactExport.definitions]} as unknown as DocumentNode<ActionExport, unknown>;
export const GetCampaignDocument = {"kind":"Document","definitions":[{"kind":"OperationDefinition","operation":"query","name":{"kind":"Name","value":"GetCampaign"},"variableDefinitions":[{"kind":"VariableDefinition","variable":{"kind":"Variable","name":{"kind":"Name","value":"org"}},"type":{"kind":"NonNullType","type":{"kind":"NamedType","name":{"kind":"Name","value":"String"}}}},{"kind":"VariableDefinition","variable":{"kind":"Variable","name":{"kind":"Name","value":"id"}},"type":{"kind":"NonNullType","type":{"kind":"NamedType","name":{"kind":"Name","value":"Int"}}}}],"selectionSet":{"kind":"SelectionSet","selections":[{"kind":"Field","name":{"kind":"Name","value":"org"},"arguments":[{"kind":"Argument","name":{"kind":"Name","value":"name"},"value":{"kind":"Variable","name":{"kind":"Name","value":"org"}}}],"selectionSet":{"kind":"SelectionSet","selections":[{"kind":"Field","name":{"kind":"Name","value":"campaign"},"arguments":[{"kind":"Argument","name":{"kind":"Name","value":"id"},"value":{"kind":"Variable","name":{"kind":"Name","value":"id"}}}],"selectionSet":{"kind":"SelectionSet","selections":[{"kind":"FragmentSpread","name":{"kind":"Name","value":"campaignFields"}},{"kind":"FragmentSpread","name":{"kind":"Name","value":"campaignPrivateFields"}},{"kind":"FragmentSpread","name":{"kind":"Name","value":"campaignAllStats"}},{"kind":"Field","name":{"kind":"Name","value":"org"},"selectionSet":{"kind":"SelectionSet","selections":[{"kind":"FragmentSpread","name":{"kind":"Name","value":"orgIds"}}]}},{"kind":"FragmentSpread","name":{"kind":"Name","value":"campaignPartnerships"}}]}}]}}]}},...CampaignFields.definitions,...CampaignPrivateFields.definitions,...CampaignAllStats.definitions,...OrgIds.definitions,...CampaignPartnerships.definitions]} as unknown as DocumentNode<GetCampaign, GetCampaignVariables>;
export const FindPublicCampaignDocument = {"kind":"Document","definitions":[{"kind":"OperationDefinition","operation":"query","name":{"kind":"Name","value":"FindPublicCampaign"},"variableDefinitions":[{"kind":"VariableDefinition","variable":{"kind":"Variable","name":{"kind":"Name","value":"name"}},"type":{"kind":"NamedType","name":{"kind":"Name","value":"String"}}},{"kind":"VariableDefinition","variable":{"kind":"Variable","name":{"kind":"Name","value":"title"}},"type":{"kind":"NamedType","name":{"kind":"Name","value":"String"}}}],"selectionSet":{"kind":"SelectionSet","selections":[{"kind":"Field","name":{"kind":"Name","value":"campaigns"},"arguments":[{"kind":"Argument","name":{"kind":"Name","value":"title"},"value":{"kind":"Variable","name":{"kind":"Name","value":"title"}}},{"kind":"Argument","name":{"kind":"Name","value":"name"},"value":{"kind":"Variable","name":{"kind":"Name","value":"name"}}}],"selectionSet":{"kind":"SelectionSet","selections":[{"kind":"FragmentSpread","name":{"kind":"Name","value":"campaignFields"}},{"kind":"Field","name":{"kind":"Name","value":"org"},"selectionSet":{"kind":"SelectionSet","selections":[{"kind":"FragmentSpread","name":{"kind":"Name","value":"orgIds"}}]}}]}}]}},...CampaignFields.definitions,...OrgIds.definitions]} as unknown as DocumentNode<FindPublicCampaign, FindPublicCampaignVariables>;
export const ListCampaignsDocument = {"kind":"Document","definitions":[{"kind":"OperationDefinition","operation":"query","name":{"kind":"Name","value":"ListCampaigns"},"variableDefinitions":[{"kind":"VariableDefinition","variable":{"kind":"Variable","name":{"kind":"Name","value":"org"}},"type":{"kind":"NonNullType","type":{"kind":"NamedType","name":{"kind":"Name","value":"String"}}}}],"selectionSet":{"kind":"SelectionSet","selections":[{"kind":"Field","name":{"kind":"Name","value":"org"},"arguments":[{"kind":"Argument","name":{"kind":"Name","value":"name"},"value":{"kind":"Variable","name":{"kind":"Name","value":"org"}}}],"selectionSet":{"kind":"SelectionSet","selections":[{"kind":"Field","name":{"kind":"Name","value":"campaigns"},"selectionSet":{"kind":"SelectionSet","selections":[{"kind":"FragmentSpread","name":{"kind":"Name","value":"campaignFields"}},{"kind":"FragmentSpread","name":{"kind":"Name","value":"campaignPrivateFields"}},{"kind":"Field","name":{"kind":"Name","value":"org"},"selectionSet":{"kind":"SelectionSet","selections":[{"kind":"FragmentSpread","name":{"kind":"Name","value":"orgIds"}}]}}]}}]}}]}},...CampaignFields.definitions,...CampaignPrivateFields.definitions,...OrgIds.definitions]} as unknown as DocumentNode<ListCampaigns, ListCampaignsVariables>;
export const ListActionPagesDocument = {"kind":"Document","definitions":[{"kind":"OperationDefinition","operation":"query","name":{"kind":"Name","value":"ListActionPages"},"variableDefinitions":[{"kind":"VariableDefinition","variable":{"kind":"Variable","name":{"kind":"Name","value":"org"}},"type":{"kind":"NonNullType","type":{"kind":"NamedType","name":{"kind":"Name","value":"String"}}}}],"selectionSet":{"kind":"SelectionSet","selections":[{"kind":"Field","name":{"kind":"Name","value":"org"},"arguments":[{"kind":"Argument","name":{"kind":"Name","value":"name"},"value":{"kind":"Variable","name":{"kind":"Name","value":"org"}}}],"selectionSet":{"kind":"SelectionSet","selections":[{"kind":"Field","name":{"kind":"Name","value":"actionPages"},"selectionSet":{"kind":"SelectionSet","selections":[{"kind":"FragmentSpread","name":{"kind":"Name","value":"actionPageOwners"}},{"kind":"FragmentSpread","name":{"kind":"Name","value":"actionPagePrivateFields"}}]}}]}}]}},...ActionPageOwners.definitions,...ActionPagePrivateFields.definitions]} as unknown as DocumentNode<ListActionPages, ListActionPagesVariables>;
export const GetActionPageDocument = {"kind":"Document","definitions":[{"kind":"OperationDefinition","operation":"query","name":{"kind":"Name","value":"GetActionPage"},"variableDefinitions":[{"kind":"VariableDefinition","variable":{"kind":"Variable","name":{"kind":"Name","value":"org"}},"type":{"kind":"NonNullType","type":{"kind":"NamedType","name":{"kind":"Name","value":"String"}}}},{"kind":"VariableDefinition","variable":{"kind":"Variable","name":{"kind":"Name","value":"id"}},"type":{"kind":"NamedType","name":{"kind":"Name","value":"Int"}}},{"kind":"VariableDefinition","variable":{"kind":"Variable","name":{"kind":"Name","value":"name"}},"type":{"kind":"NamedType","name":{"kind":"Name","value":"String"}}}],"selectionSet":{"kind":"SelectionSet","selections":[{"kind":"Field","name":{"kind":"Name","value":"org"},"arguments":[{"kind":"Argument","name":{"kind":"Name","value":"name"},"value":{"kind":"Variable","name":{"kind":"Name","value":"org"}}}],"selectionSet":{"kind":"SelectionSet","selections":[{"kind":"Field","name":{"kind":"Name","value":"name"}},{"kind":"Field","name":{"kind":"Name","value":"title"}},{"kind":"Field","name":{"kind":"Name","value":"actionPage"},"arguments":[{"kind":"Argument","name":{"kind":"Name","value":"id"},"value":{"kind":"Variable","name":{"kind":"Name","value":"id"}}},{"kind":"Argument","name":{"kind":"Name","value":"name"},"value":{"kind":"Variable","name":{"kind":"Name","value":"name"}}}],"selectionSet":{"kind":"SelectionSet","selections":[{"kind":"FragmentSpread","name":{"kind":"Name","value":"actionPageOwners"}},{"kind":"FragmentSpread","name":{"kind":"Name","value":"actionPagePrivateFields"}},{"kind":"Field","name":{"kind":"Name","value":"campaign"},"selectionSet":{"kind":"SelectionSet","selections":[{"kind":"FragmentSpread","name":{"kind":"Name","value":"campaignFields"}},{"kind":"FragmentSpread","name":{"kind":"Name","value":"campaignPrivateFields"}}]}}]}}]}}]}},...ActionPageOwners.definitions,...ActionPagePrivateFields.definitions,...CampaignFields.definitions,...CampaignPrivateFields.definitions]} as unknown as DocumentNode<GetActionPage, GetActionPageVariables>;
export const GetPublicActionPageDocument = {"kind":"Document","definitions":[{"kind":"OperationDefinition","operation":"query","name":{"kind":"Name","value":"GetPublicActionPage"},"variableDefinitions":[{"kind":"VariableDefinition","variable":{"kind":"Variable","name":{"kind":"Name","value":"name"}},"type":{"kind":"NamedType","name":{"kind":"Name","value":"String"}}},{"kind":"VariableDefinition","variable":{"kind":"Variable","name":{"kind":"Name","value":"id"}},"type":{"kind":"NamedType","name":{"kind":"Name","value":"Int"}}}],"selectionSet":{"kind":"SelectionSet","selections":[{"kind":"Field","name":{"kind":"Name","value":"actionPage"},"arguments":[{"kind":"Argument","name":{"kind":"Name","value":"name"},"value":{"kind":"Variable","name":{"kind":"Name","value":"name"}}},{"kind":"Argument","name":{"kind":"Name","value":"id"},"value":{"kind":"Variable","name":{"kind":"Name","value":"id"}}}],"selectionSet":{"kind":"SelectionSet","selections":[{"kind":"FragmentSpread","name":{"kind":"Name","value":"actionPageOwners"}}]}}]}},...ActionPageOwners.definitions]} as unknown as DocumentNode<GetPublicActionPage, GetPublicActionPageVariables>;
export const ListActionPagesByCampaignDocument = {"kind":"Document","definitions":[{"kind":"OperationDefinition","operation":"query","name":{"kind":"Name","value":"ListActionPagesByCampaign"},"variableDefinitions":[{"kind":"VariableDefinition","variable":{"kind":"Variable","name":{"kind":"Name","value":"org"}},"type":{"kind":"NonNullType","type":{"kind":"NamedType","name":{"kind":"Name","value":"String"}}}},{"kind":"VariableDefinition","variable":{"kind":"Variable","name":{"kind":"Name","value":"campaignId"}},"type":{"kind":"NonNullType","type":{"kind":"NamedType","name":{"kind":"Name","value":"Int"}}}}],"selectionSet":{"kind":"SelectionSet","selections":[{"kind":"Field","name":{"kind":"Name","value":"org"},"arguments":[{"kind":"Argument","name":{"kind":"Name","value":"name"},"value":{"kind":"Variable","name":{"kind":"Name","value":"org"}}}],"selectionSet":{"kind":"SelectionSet","selections":[{"kind":"Field","name":{"kind":"Name","value":"name"}},{"kind":"Field","name":{"kind":"Name","value":"title"}},{"kind":"Field","name":{"kind":"Name","value":"actionPages"},"arguments":[{"kind":"Argument","name":{"kind":"Name","value":"select"},"value":{"kind":"ObjectValue","fields":[{"kind":"ObjectField","name":{"kind":"Name","value":"campaignId"},"value":{"kind":"Variable","name":{"kind":"Name","value":"campaignId"}}}]}}],"selectionSet":{"kind":"SelectionSet","selections":[{"kind":"FragmentSpread","name":{"kind":"Name","value":"actionPageFields"}},{"kind":"FragmentSpread","name":{"kind":"Name","value":"actionPagePrivateFields"}},{"kind":"Field","name":{"kind":"Name","value":"campaign"},"selectionSet":{"kind":"SelectionSet","selections":[{"kind":"FragmentSpread","name":{"kind":"Name","value":"campaignFields"}}]}}]}}]}}]}},...ActionPageFields.definitions,...ActionPagePrivateFields.definitions,...CampaignFields.definitions]} as unknown as DocumentNode<ListActionPagesByCampaign, ListActionPagesByCampaignVariables>;
export const UpdateActionPageDocument = {"kind":"Document","definitions":[{"kind":"OperationDefinition","operation":"mutation","name":{"kind":"Name","value":"UpdateActionPage"},"variableDefinitions":[{"kind":"VariableDefinition","variable":{"kind":"Variable","name":{"kind":"Name","value":"id"}},"type":{"kind":"NonNullType","type":{"kind":"NamedType","name":{"kind":"Name","value":"Int"}}}},{"kind":"VariableDefinition","variable":{"kind":"Variable","name":{"kind":"Name","value":"actionPage"}},"type":{"kind":"NonNullType","type":{"kind":"NamedType","name":{"kind":"Name","value":"ActionPageInput"}}}}],"selectionSet":{"kind":"SelectionSet","selections":[{"kind":"Field","name":{"kind":"Name","value":"updateActionPage"},"arguments":[{"kind":"Argument","name":{"kind":"Name","value":"id"},"value":{"kind":"Variable","name":{"kind":"Name","value":"id"}}},{"kind":"Argument","name":{"kind":"Name","value":"input"},"value":{"kind":"Variable","name":{"kind":"Name","value":"actionPage"}}}],"selectionSet":{"kind":"SelectionSet","selections":[{"kind":"Field","name":{"kind":"Name","value":"id"}}]}}]}}]} as unknown as DocumentNode<UpdateActionPage, UpdateActionPageVariables>;
export const PubListCampaignDocument = {"kind":"Document","definitions":[{"kind":"OperationDefinition","operation":"query","name":{"kind":"Name","value":"PubListCampaign"},"variableDefinitions":[{"kind":"VariableDefinition","variable":{"kind":"Variable","name":{"kind":"Name","value":"name"}},"type":{"kind":"NonNullType","type":{"kind":"NamedType","name":{"kind":"Name","value":"String"}}}}],"selectionSet":{"kind":"SelectionSet","selections":[{"kind":"Field","name":{"kind":"Name","value":"campaigns"},"arguments":[{"kind":"Argument","name":{"kind":"Name","value":"name"},"value":{"kind":"Variable","name":{"kind":"Name","value":"name"}}}],"selectionSet":{"kind":"SelectionSet","selections":[{"kind":"FragmentSpread","name":{"kind":"Name","value":"campaignFields"}}]}}]}},...CampaignFields.definitions]} as unknown as DocumentNode<PubListCampaign, PubListCampaignVariables>;
export const ExportCampaignActionsDocument = {"kind":"Document","definitions":[{"kind":"OperationDefinition","operation":"query","name":{"kind":"Name","value":"ExportCampaignActions"},"variableDefinitions":[{"kind":"VariableDefinition","variable":{"kind":"Variable","name":{"kind":"Name","value":"org"}},"type":{"kind":"NonNullType","type":{"kind":"NamedType","name":{"kind":"Name","value":"String"}}}},{"kind":"VariableDefinition","variable":{"kind":"Variable","name":{"kind":"Name","value":"campaignId"}},"type":{"kind":"NamedType","name":{"kind":"Name","value":"Int"}}},{"kind":"VariableDefinition","variable":{"kind":"Variable","name":{"kind":"Name","value":"campaignName"}},"type":{"kind":"NamedType","name":{"kind":"Name","value":"String"}}},{"kind":"VariableDefinition","variable":{"kind":"Variable","name":{"kind":"Name","value":"start"}},"type":{"kind":"NamedType","name":{"kind":"Name","value":"Int"}}},{"kind":"VariableDefinition","variable":{"kind":"Variable","name":{"kind":"Name","value":"after"}},"type":{"kind":"NamedType","name":{"kind":"Name","value":"DateTime"}}},{"kind":"VariableDefinition","variable":{"kind":"Variable","name":{"kind":"Name","value":"limit"}},"type":{"kind":"NamedType","name":{"kind":"Name","value":"Int"}}},{"kind":"VariableDefinition","variable":{"kind":"Variable","name":{"kind":"Name","value":"onlyOptIn"}},"type":{"kind":"NamedType","name":{"kind":"Name","value":"Boolean"}}}],"selectionSet":{"kind":"SelectionSet","selections":[{"kind":"Field","name":{"kind":"Name","value":"exportActions"},"arguments":[{"kind":"Argument","name":{"kind":"Name","value":"orgName"},"value":{"kind":"Variable","name":{"kind":"Name","value":"org"}}},{"kind":"Argument","name":{"kind":"Name","value":"campaignId"},"value":{"kind":"Variable","name":{"kind":"Name","value":"campaignId"}}},{"kind":"Argument","name":{"kind":"Name","value":"campaignName"},"value":{"kind":"Variable","name":{"kind":"Name","value":"campaignName"}}},{"kind":"Argument","name":{"kind":"Name","value":"start"},"value":{"kind":"Variable","name":{"kind":"Name","value":"start"}}},{"kind":"Argument","name":{"kind":"Name","value":"after"},"value":{"kind":"Variable","name":{"kind":"Name","value":"after"}}},{"kind":"Argument","name":{"kind":"Name","value":"limit"},"value":{"kind":"Variable","name":{"kind":"Name","value":"limit"}}},{"kind":"Argument","name":{"kind":"Name","value":"onlyOptIn"},"value":{"kind":"Variable","name":{"kind":"Name","value":"onlyOptIn"}}}],"selectionSet":{"kind":"SelectionSet","selections":[{"kind":"FragmentSpread","name":{"kind":"Name","value":"actionExport"}},{"kind":"Field","name":{"kind":"Name","value":"actionPage"},"selectionSet":{"kind":"SelectionSet","selections":[{"kind":"FragmentSpread","name":{"kind":"Name","value":"actionPageIds"}}]}}]}}]}},...ActionExport.definitions,...ActionPageIds.definitions]} as unknown as DocumentNode<ExportCampaignActions, ExportCampaignActionsVariables>;
export const ExportOrgActionsDocument = {"kind":"Document","definitions":[{"kind":"OperationDefinition","operation":"query","name":{"kind":"Name","value":"ExportOrgActions"},"variableDefinitions":[{"kind":"VariableDefinition","variable":{"kind":"Variable","name":{"kind":"Name","value":"org"}},"type":{"kind":"NonNullType","type":{"kind":"NamedType","name":{"kind":"Name","value":"String"}}}},{"kind":"VariableDefinition","variable":{"kind":"Variable","name":{"kind":"Name","value":"start"}},"type":{"kind":"NamedType","name":{"kind":"Name","value":"Int"}}},{"kind":"VariableDefinition","variable":{"kind":"Variable","name":{"kind":"Name","value":"after"}},"type":{"kind":"NamedType","name":{"kind":"Name","value":"DateTime"}}},{"kind":"VariableDefinition","variable":{"kind":"Variable","name":{"kind":"Name","value":"limit"}},"type":{"kind":"NamedType","name":{"kind":"Name","value":"Int"}}},{"kind":"VariableDefinition","variable":{"kind":"Variable","name":{"kind":"Name","value":"onlyOptIn"}},"type":{"kind":"NamedType","name":{"kind":"Name","value":"Boolean"}}}],"selectionSet":{"kind":"SelectionSet","selections":[{"kind":"Field","name":{"kind":"Name","value":"exportActions"},"arguments":[{"kind":"Argument","name":{"kind":"Name","value":"orgName"},"value":{"kind":"Variable","name":{"kind":"Name","value":"org"}}},{"kind":"Argument","name":{"kind":"Name","value":"start"},"value":{"kind":"Variable","name":{"kind":"Name","value":"start"}}},{"kind":"Argument","name":{"kind":"Name","value":"after"},"value":{"kind":"Variable","name":{"kind":"Name","value":"after"}}},{"kind":"Argument","name":{"kind":"Name","value":"limit"},"value":{"kind":"Variable","name":{"kind":"Name","value":"limit"}}},{"kind":"Argument","name":{"kind":"Name","value":"onlyOptIn"},"value":{"kind":"Variable","name":{"kind":"Name","value":"onlyOptIn"}}}],"selectionSet":{"kind":"SelectionSet","selections":[{"kind":"FragmentSpread","name":{"kind":"Name","value":"actionExport"}},{"kind":"Field","name":{"kind":"Name","value":"actionPage"},"selectionSet":{"kind":"SelectionSet","selections":[{"kind":"FragmentSpread","name":{"kind":"Name","value":"actionPageIds"}}]}},{"kind":"Field","name":{"kind":"Name","value":"campaign"},"selectionSet":{"kind":"SelectionSet","selections":[{"kind":"FragmentSpread","name":{"kind":"Name","value":"campaignExportIds"}}]}}]}}]}},...ActionExport.definitions,...ActionPageIds.definitions,...CampaignExportIds.definitions]} as unknown as DocumentNode<ExportOrgActions, ExportOrgActionsVariables>;
export const CopyActionPageDocument = {"kind":"Document","definitions":[{"kind":"OperationDefinition","operation":"mutation","name":{"kind":"Name","value":"CopyActionPage"},"variableDefinitions":[{"kind":"VariableDefinition","variable":{"kind":"Variable","name":{"kind":"Name","value":"fromName"}},"type":{"kind":"NonNullType","type":{"kind":"NamedType","name":{"kind":"Name","value":"String"}}}},{"kind":"VariableDefinition","variable":{"kind":"Variable","name":{"kind":"Name","value":"toOrg"}},"type":{"kind":"NonNullType","type":{"kind":"NamedType","name":{"kind":"Name","value":"String"}}}},{"kind":"VariableDefinition","variable":{"kind":"Variable","name":{"kind":"Name","value":"toName"}},"type":{"kind":"NonNullType","type":{"kind":"NamedType","name":{"kind":"Name","value":"String"}}}}],"selectionSet":{"kind":"SelectionSet","selections":[{"kind":"Field","name":{"kind":"Name","value":"copyActionPage"},"arguments":[{"kind":"Argument","name":{"kind":"Name","value":"fromName"},"value":{"kind":"Variable","name":{"kind":"Name","value":"fromName"}}},{"kind":"Argument","name":{"kind":"Name","value":"name"},"value":{"kind":"Variable","name":{"kind":"Name","value":"toName"}}},{"kind":"Argument","name":{"kind":"Name","value":"orgName"},"value":{"kind":"Variable","name":{"kind":"Name","value":"toOrg"}}}],"selectionSet":{"kind":"SelectionSet","selections":[{"kind":"FragmentSpread","name":{"kind":"Name","value":"actionPageFields"}},{"kind":"FragmentSpread","name":{"kind":"Name","value":"actionPagePrivateFields"}},{"kind":"Field","name":{"kind":"Name","value":"campaign"},"selectionSet":{"kind":"SelectionSet","selections":[{"kind":"FragmentSpread","name":{"kind":"Name","value":"campaignFields"}}]}}]}}]}},...ActionPageFields.definitions,...ActionPagePrivateFields.definitions,...CampaignFields.definitions]} as unknown as DocumentNode<CopyActionPage, CopyActionPageVariables>;
export const CopyCampaignActionPageDocument = {"kind":"Document","definitions":[{"kind":"OperationDefinition","operation":"mutation","name":{"kind":"Name","value":"CopyCampaignActionPage"},"variableDefinitions":[{"kind":"VariableDefinition","variable":{"kind":"Variable","name":{"kind":"Name","value":"fromCampaign"}},"type":{"kind":"NonNullType","type":{"kind":"NamedType","name":{"kind":"Name","value":"String"}}}},{"kind":"VariableDefinition","variable":{"kind":"Variable","name":{"kind":"Name","value":"toOrg"}},"type":{"kind":"NonNullType","type":{"kind":"NamedType","name":{"kind":"Name","value":"String"}}}},{"kind":"VariableDefinition","variable":{"kind":"Variable","name":{"kind":"Name","value":"toName"}},"type":{"kind":"NonNullType","type":{"kind":"NamedType","name":{"kind":"Name","value":"String"}}}}],"selectionSet":{"kind":"SelectionSet","selections":[{"kind":"Field","name":{"kind":"Name","value":"copyCampaignActionPage"},"arguments":[{"kind":"Argument","name":{"kind":"Name","value":"fromCampaignName"},"value":{"kind":"Variable","name":{"kind":"Name","value":"fromCampaign"}}},{"kind":"Argument","name":{"kind":"Name","value":"name"},"value":{"kind":"Variable","name":{"kind":"Name","value":"toName"}}},{"kind":"Argument","name":{"kind":"Name","value":"orgName"},"value":{"kind":"Variable","name":{"kind":"Name","value":"toOrg"}}}],"selectionSet":{"kind":"SelectionSet","selections":[{"kind":"FragmentSpread","name":{"kind":"Name","value":"actionPageFields"}},{"kind":"FragmentSpread","name":{"kind":"Name","value":"actionPagePrivateFields"}},{"kind":"Field","name":{"kind":"Name","value":"campaign"},"selectionSet":{"kind":"SelectionSet","selections":[{"kind":"FragmentSpread","name":{"kind":"Name","value":"campaignIds"}}]}}]}}]}},...ActionPageFields.definitions,...ActionPagePrivateFields.definitions,...CampaignIds.definitions]} as unknown as DocumentNode<CopyCampaignActionPage, CopyCampaignActionPageVariables>;
export const JoinOrgDocument = {"kind":"Document","definitions":[{"kind":"OperationDefinition","operation":"mutation","name":{"kind":"Name","value":"JoinOrg"},"variableDefinitions":[{"kind":"VariableDefinition","variable":{"kind":"Variable","name":{"kind":"Name","value":"orgName"}},"type":{"kind":"NonNullType","type":{"kind":"NamedType","name":{"kind":"Name","value":"String"}}}}],"selectionSet":{"kind":"SelectionSet","selections":[{"kind":"Field","name":{"kind":"Name","value":"joinOrg"},"arguments":[{"kind":"Argument","name":{"kind":"Name","value":"name"},"value":{"kind":"Variable","name":{"kind":"Name","value":"orgName"}}}],"selectionSet":{"kind":"SelectionSet","selections":[{"kind":"Field","name":{"kind":"Name","value":"status"}}]}}]}}]} as unknown as DocumentNode<JoinOrg, JoinOrgVariables>;
export const UpsertCampaignDocument = {"kind":"Document","definitions":[{"kind":"OperationDefinition","operation":"mutation","name":{"kind":"Name","value":"UpsertCampaign"},"variableDefinitions":[{"kind":"VariableDefinition","variable":{"kind":"Variable","name":{"kind":"Name","value":"org"}},"type":{"kind":"NonNullType","type":{"kind":"NamedType","name":{"kind":"Name","value":"String"}}}},{"kind":"VariableDefinition","variable":{"kind":"Variable","name":{"kind":"Name","value":"campaign"}},"type":{"kind":"NonNullType","type":{"kind":"NamedType","name":{"kind":"Name","value":"CampaignInput"}}}}],"selectionSet":{"kind":"SelectionSet","selections":[{"kind":"Field","name":{"kind":"Name","value":"upsertCampaign"},"arguments":[{"kind":"Argument","name":{"kind":"Name","value":"orgName"},"value":{"kind":"Variable","name":{"kind":"Name","value":"org"}}},{"kind":"Argument","name":{"kind":"Name","value":"input"},"value":{"kind":"Variable","name":{"kind":"Name","value":"campaign"}}}],"selectionSet":{"kind":"SelectionSet","selections":[{"kind":"Field","name":{"kind":"Name","value":"id"}}]}}]}}]} as unknown as DocumentNode<UpsertCampaign, UpsertCampaignVariables>;
export const ListKeysDocument = {"kind":"Document","definitions":[{"kind":"OperationDefinition","operation":"query","name":{"kind":"Name","value":"ListKeys"},"variableDefinitions":[{"kind":"VariableDefinition","variable":{"kind":"Variable","name":{"kind":"Name","value":"org"}},"type":{"kind":"NonNullType","type":{"kind":"NamedType","name":{"kind":"Name","value":"String"}}}}],"selectionSet":{"kind":"SelectionSet","selections":[{"kind":"Field","name":{"kind":"Name","value":"org"},"arguments":[{"kind":"Argument","name":{"kind":"Name","value":"name"},"value":{"kind":"Variable","name":{"kind":"Name","value":"org"}}}],"selectionSet":{"kind":"SelectionSet","selections":[{"kind":"Field","name":{"kind":"Name","value":"keys"},"selectionSet":{"kind":"SelectionSet","selections":[{"kind":"FragmentSpread","name":{"kind":"Name","value":"keyFields"}}]}}]}}]}},...KeyFields.definitions]} as unknown as DocumentNode<ListKeys, ListKeysVariables>;
export const GenerateKeyDocument = {"kind":"Document","definitions":[{"kind":"OperationDefinition","operation":"mutation","name":{"kind":"Name","value":"GenerateKey"},"variableDefinitions":[{"kind":"VariableDefinition","variable":{"kind":"Variable","name":{"kind":"Name","value":"org"}},"type":{"kind":"NonNullType","type":{"kind":"NamedType","name":{"kind":"Name","value":"String"}}}},{"kind":"VariableDefinition","variable":{"kind":"Variable","name":{"kind":"Name","value":"input"}},"type":{"kind":"NonNullType","type":{"kind":"NamedType","name":{"kind":"Name","value":"GenKeyInput"}}}}],"selectionSet":{"kind":"SelectionSet","selections":[{"kind":"Field","name":{"kind":"Name","value":"generateKey"},"arguments":[{"kind":"Argument","name":{"kind":"Name","value":"orgName"},"value":{"kind":"Variable","name":{"kind":"Name","value":"org"}}},{"kind":"Argument","name":{"kind":"Name","value":"input"},"value":{"kind":"Variable","name":{"kind":"Name","value":"input"}}}],"selectionSet":{"kind":"SelectionSet","selections":[{"kind":"Field","name":{"kind":"Name","value":"id"}},{"kind":"Field","name":{"kind":"Name","value":"name"}},{"kind":"Field","name":{"kind":"Name","value":"public"}},{"kind":"Field","name":{"kind":"Name","value":"private"}},{"kind":"Field","name":{"kind":"Name","value":"active"}},{"kind":"Field","name":{"kind":"Name","value":"expired"}},{"kind":"Field","name":{"kind":"Name","value":"expiredAt"}}]}}]}}]} as unknown as DocumentNode<GenerateKey, GenerateKeyVariables>;
export const AddKeyDocument = {"kind":"Document","definitions":[{"kind":"OperationDefinition","operation":"mutation","name":{"kind":"Name","value":"AddKey"},"variableDefinitions":[{"kind":"VariableDefinition","variable":{"kind":"Variable","name":{"kind":"Name","value":"org"}},"type":{"kind":"NonNullType","type":{"kind":"NamedType","name":{"kind":"Name","value":"String"}}}},{"kind":"VariableDefinition","variable":{"kind":"Variable","name":{"kind":"Name","value":"input"}},"type":{"kind":"NonNullType","type":{"kind":"NamedType","name":{"kind":"Name","value":"AddKeyInput"}}}}],"selectionSet":{"kind":"SelectionSet","selections":[{"kind":"Field","name":{"kind":"Name","value":"addKey"},"arguments":[{"kind":"Argument","name":{"kind":"Name","value":"orgName"},"value":{"kind":"Variable","name":{"kind":"Name","value":"org"}}},{"kind":"Argument","name":{"kind":"Name","value":"input"},"value":{"kind":"Variable","name":{"kind":"Name","value":"input"}}}],"selectionSet":{"kind":"SelectionSet","selections":[{"kind":"Field","name":{"kind":"Name","value":"id"}},{"kind":"Field","name":{"kind":"Name","value":"name"}},{"kind":"Field","name":{"kind":"Name","value":"public"}},{"kind":"Field","name":{"kind":"Name","value":"active"}},{"kind":"Field","name":{"kind":"Name","value":"expired"}},{"kind":"Field","name":{"kind":"Name","value":"expiredAt"}}]}}]}}]} as unknown as DocumentNode<AddKey, AddKeyVariables>;
export const ActivateKeyDocument = {"kind":"Document","definitions":[{"kind":"OperationDefinition","operation":"mutation","name":{"kind":"Name","value":"ActivateKey"},"variableDefinitions":[{"kind":"VariableDefinition","variable":{"kind":"Variable","name":{"kind":"Name","value":"org"}},"type":{"kind":"NonNullType","type":{"kind":"NamedType","name":{"kind":"Name","value":"String"}}}},{"kind":"VariableDefinition","variable":{"kind":"Variable","name":{"kind":"Name","value":"id"}},"type":{"kind":"NonNullType","type":{"kind":"NamedType","name":{"kind":"Name","value":"Int"}}}}],"selectionSet":{"kind":"SelectionSet","selections":[{"kind":"Field","name":{"kind":"Name","value":"activateKey"},"arguments":[{"kind":"Argument","name":{"kind":"Name","value":"orgName"},"value":{"kind":"Variable","name":{"kind":"Name","value":"org"}}},{"kind":"Argument","name":{"kind":"Name","value":"id"},"value":{"kind":"Variable","name":{"kind":"Name","value":"id"}}}],"selectionSet":{"kind":"SelectionSet","selections":[{"kind":"Field","name":{"kind":"Name","value":"status"}}]}}]}}]} as unknown as DocumentNode<ActivateKey, ActivateKeyVariables>;
export const AddOrgDocument = {"kind":"Document","definitions":[{"kind":"OperationDefinition","operation":"mutation","name":{"kind":"Name","value":"AddOrg"},"variableDefinitions":[{"kind":"VariableDefinition","variable":{"kind":"Variable","name":{"kind":"Name","value":"org"}},"type":{"kind":"NonNullType","type":{"kind":"NamedType","name":{"kind":"Name","value":"OrgInput"}}}}],"selectionSet":{"kind":"SelectionSet","selections":[{"kind":"Field","name":{"kind":"Name","value":"addOrg"},"arguments":[{"kind":"Argument","name":{"kind":"Name","value":"input"},"value":{"kind":"Variable","name":{"kind":"Name","value":"org"}}}],"selectionSet":{"kind":"SelectionSet","selections":[{"kind":"FragmentSpread","name":{"kind":"Name","value":"orgIds"}}]}}]}},...OrgIds.definitions]} as unknown as DocumentNode<AddOrg, AddOrgVariables>;
export const UpdateOrgDocument = {"kind":"Document","definitions":[{"kind":"OperationDefinition","operation":"mutation","name":{"kind":"Name","value":"UpdateOrg"},"variableDefinitions":[{"kind":"VariableDefinition","variable":{"kind":"Variable","name":{"kind":"Name","value":"orgName"}},"type":{"kind":"NonNullType","type":{"kind":"NamedType","name":{"kind":"Name","value":"String"}}}},{"kind":"VariableDefinition","variable":{"kind":"Variable","name":{"kind":"Name","value":"org"}},"type":{"kind":"NonNullType","type":{"kind":"NamedType","name":{"kind":"Name","value":"OrgInput"}}}}],"selectionSet":{"kind":"SelectionSet","selections":[{"kind":"Field","name":{"kind":"Name","value":"updateOrg"},"arguments":[{"kind":"Argument","name":{"kind":"Name","value":"name"},"value":{"kind":"Variable","name":{"kind":"Name","value":"orgName"}}},{"kind":"Argument","name":{"kind":"Name","value":"input"},"value":{"kind":"Variable","name":{"kind":"Name","value":"org"}}}],"selectionSet":{"kind":"SelectionSet","selections":[{"kind":"FragmentSpread","name":{"kind":"Name","value":"orgFields"}},{"kind":"FragmentSpread","name":{"kind":"Name","value":"orgPrivateFields"}}]}}]}},...OrgFields.definitions,...OrgPrivateFields.definitions]} as unknown as DocumentNode<UpdateOrg, UpdateOrgVariables>;
export const ActionPageUpsertedDocument = {"kind":"Document","definitions":[{"kind":"OperationDefinition","operation":"subscription","name":{"kind":"Name","value":"ActionPageUpserted"},"variableDefinitions":[{"kind":"VariableDefinition","variable":{"kind":"Variable","name":{"kind":"Name","value":"org"}},"type":{"kind":"NamedType","name":{"kind":"Name","value":"String"}}}],"selectionSet":{"kind":"SelectionSet","selections":[{"kind":"Field","name":{"kind":"Name","value":"actionPageUpserted"},"arguments":[{"kind":"Argument","name":{"kind":"Name","value":"orgName"},"value":{"kind":"Variable","name":{"kind":"Name","value":"org"}}}],"selectionSet":{"kind":"SelectionSet","selections":[{"kind":"FragmentSpread","name":{"kind":"Name","value":"actionPageOwners"}},{"kind":"FragmentSpread","name":{"kind":"Name","value":"actionPagePrivateFields"}}]}}]}},...ActionPageOwners.definitions,...ActionPagePrivateFields.definitions]} as unknown as DocumentNode<ActionPageUpserted, ActionPageUpsertedVariables>;
export const CurrentUserOrgsDocument = {"kind":"Document","definitions":[{"kind":"OperationDefinition","operation":"query","name":{"kind":"Name","value":"CurrentUserOrgs"},"selectionSet":{"kind":"SelectionSet","selections":[{"kind":"Field","name":{"kind":"Name","value":"currentUser"},"selectionSet":{"kind":"SelectionSet","selections":[{"kind":"Field","name":{"kind":"Name","value":"id"}},{"kind":"Field","name":{"kind":"Name","value":"email"}},{"kind":"Field","name":{"kind":"Name","value":"roles"},"selectionSet":{"kind":"SelectionSet","selections":[{"kind":"Field","name":{"kind":"Name","value":"role"}},{"kind":"Field","name":{"kind":"Name","value":"org"},"selectionSet":{"kind":"SelectionSet","selections":[{"kind":"FragmentSpread","name":{"kind":"Name","value":"orgIds"}}]}}]}}]}}]}},...OrgIds.definitions]} as unknown as DocumentNode<CurrentUserOrgs, CurrentUserOrgsVariables>;
export const DashOrgOverviewDocument = {"kind":"Document","definitions":[{"kind":"OperationDefinition","operation":"query","name":{"kind":"Name","value":"DashOrgOverview"},"variableDefinitions":[{"kind":"VariableDefinition","variable":{"kind":"Variable","name":{"kind":"Name","value":"org"}},"type":{"kind":"NonNullType","type":{"kind":"NamedType","name":{"kind":"Name","value":"String"}}}}],"selectionSet":{"kind":"SelectionSet","selections":[{"kind":"Field","name":{"kind":"Name","value":"org"},"arguments":[{"kind":"Argument","name":{"kind":"Name","value":"name"},"value":{"kind":"Variable","name":{"kind":"Name","value":"org"}}}],"selectionSet":{"kind":"SelectionSet","selections":[{"kind":"Field","name":{"kind":"Name","value":"name"}},{"kind":"Field","name":{"kind":"Name","value":"title"}},{"kind":"FragmentSpread","name":{"kind":"Name","value":"orgPrivateFields"}},{"kind":"InlineFragment","typeCondition":{"kind":"NamedType","name":{"kind":"Name","value":"PrivateOrg"}},"selectionSet":{"kind":"SelectionSet","selections":[{"kind":"Field","name":{"kind":"Name","value":"campaigns"},"selectionSet":{"kind":"SelectionSet","selections":[{"kind":"FragmentSpread","name":{"kind":"Name","value":"campaignFields"}},{"kind":"FragmentSpread","name":{"kind":"Name","value":"campaignAllStats"}},{"kind":"Field","name":{"kind":"Name","value":"org"},"selectionSet":{"kind":"SelectionSet","selections":[{"kind":"FragmentSpread","name":{"kind":"Name","value":"orgIds"}}]}}]}}]}}]}}]}},...OrgPrivateFields.definitions,...CampaignFields.definitions,...CampaignAllStats.definitions,...OrgIds.definitions]} as unknown as DocumentNode<DashOrgOverview, DashOrgOverviewVariables>;
export const GetOrgDocument = {"kind":"Document","definitions":[{"kind":"OperationDefinition","operation":"query","name":{"kind":"Name","value":"GetOrg"},"variableDefinitions":[{"kind":"VariableDefinition","variable":{"kind":"Variable","name":{"kind":"Name","value":"org"}},"type":{"kind":"NonNullType","type":{"kind":"NamedType","name":{"kind":"Name","value":"String"}}}}],"selectionSet":{"kind":"SelectionSet","selections":[{"kind":"Field","name":{"kind":"Name","value":"org"},"arguments":[{"kind":"Argument","name":{"kind":"Name","value":"name"},"value":{"kind":"Variable","name":{"kind":"Name","value":"org"}}}],"selectionSet":{"kind":"SelectionSet","selections":[{"kind":"FragmentSpread","name":{"kind":"Name","value":"orgFields"}},{"kind":"FragmentSpread","name":{"kind":"Name","value":"orgPrivateFields"}},{"kind":"Field","name":{"kind":"Name","value":"keys"},"arguments":[{"kind":"Argument","name":{"kind":"Name","value":"select"},"value":{"kind":"ObjectValue","fields":[{"kind":"ObjectField","name":{"kind":"Name","value":"active"},"value":{"kind":"BooleanValue","value":true}}]}}],"selectionSet":{"kind":"SelectionSet","selections":[{"kind":"FragmentSpread","name":{"kind":"Name","value":"keyFields"}}]}},{"kind":"Field","name":{"kind":"Name","value":"services"},"selectionSet":{"kind":"SelectionSet","selections":[{"kind":"FragmentSpread","name":{"kind":"Name","value":"serviceFields"}}]}}]}}]}},...OrgFields.definitions,...OrgPrivateFields.definitions,...KeyFields.definitions,...ServiceFields.definitions]} as unknown as DocumentNode<GetOrg, GetOrgVariables>;
export const GetOrgAttrsDocument = {"kind":"Document","definitions":[{"kind":"OperationDefinition","operation":"query","name":{"kind":"Name","value":"GetOrgAttrs"},"variableDefinitions":[{"kind":"VariableDefinition","variable":{"kind":"Variable","name":{"kind":"Name","value":"org"}},"type":{"kind":"NonNullType","type":{"kind":"NamedType","name":{"kind":"Name","value":"String"}}}}],"selectionSet":{"kind":"SelectionSet","selections":[{"kind":"Field","name":{"kind":"Name","value":"org"},"arguments":[{"kind":"Argument","name":{"kind":"Name","value":"name"},"value":{"kind":"Variable","name":{"kind":"Name","value":"org"}}}],"selectionSet":{"kind":"SelectionSet","selections":[{"kind":"FragmentSpread","name":{"kind":"Name","value":"orgFields"}},{"kind":"FragmentSpread","name":{"kind":"Name","value":"orgPrivateFields"}}]}}]}},...OrgFields.definitions,...OrgPrivateFields.definitions]} as unknown as DocumentNode<GetOrgAttrs, GetOrgAttrsVariables>;
export const LaunchActionPageDocument = {"kind":"Document","definitions":[{"kind":"OperationDefinition","operation":"mutation","name":{"kind":"Name","value":"launchActionPage"},"variableDefinitions":[{"kind":"VariableDefinition","variable":{"kind":"Variable","name":{"kind":"Name","value":"name"}},"type":{"kind":"NonNullType","type":{"kind":"NamedType","name":{"kind":"Name","value":"String"}}}}],"selectionSet":{"kind":"SelectionSet","selections":[{"kind":"Field","name":{"kind":"Name","value":"launchActionPage"},"arguments":[{"kind":"Argument","name":{"kind":"Name","value":"name"},"value":{"kind":"Variable","name":{"kind":"Name","value":"name"}}}],"selectionSet":{"kind":"SelectionSet","selections":[{"kind":"Field","name":{"kind":"Name","value":"status"}}]}}]}}]} as unknown as DocumentNode<LaunchActionPage, LaunchActionPageVariables>;
export const AcceptLaunchRequestDocument = {"kind":"Document","definitions":[{"kind":"OperationDefinition","operation":"mutation","name":{"kind":"Name","value":"acceptLaunchRequest"},"variableDefinitions":[{"kind":"VariableDefinition","variable":{"kind":"Variable","name":{"kind":"Name","value":"org"}},"type":{"kind":"NonNullType","type":{"kind":"NamedType","name":{"kind":"Name","value":"String"}}}},{"kind":"VariableDefinition","variable":{"kind":"Variable","name":{"kind":"Name","value":"confirm"}},"type":{"kind":"NonNullType","type":{"kind":"NamedType","name":{"kind":"Name","value":"ConfirmInput"}}}}],"selectionSet":{"kind":"SelectionSet","selections":[{"kind":"Field","name":{"kind":"Name","value":"acceptOrgConfirm"},"arguments":[{"kind":"Argument","name":{"kind":"Name","value":"name"},"value":{"kind":"Variable","name":{"kind":"Name","value":"org"}}},{"kind":"Argument","name":{"kind":"Name","value":"confirm"},"value":{"kind":"Variable","name":{"kind":"Name","value":"confirm"}}}],"selectionSet":{"kind":"SelectionSet","selections":[{"kind":"Field","name":{"kind":"Name","value":"status"}},{"kind":"Field","name":{"kind":"Name","value":"actionPage"},"selectionSet":{"kind":"SelectionSet","selections":[{"kind":"FragmentSpread","name":{"kind":"Name","value":"actionPageFields"}}]}}]}}]}},...ActionPageFields.definitions]} as unknown as DocumentNode<AcceptLaunchRequest, AcceptLaunchRequestVariables>;
export const RejectLaunchRequestDocument = {"kind":"Document","definitions":[{"kind":"OperationDefinition","operation":"mutation","name":{"kind":"Name","value":"rejectLaunchRequest"},"variableDefinitions":[{"kind":"VariableDefinition","variable":{"kind":"Variable","name":{"kind":"Name","value":"org"}},"type":{"kind":"NonNullType","type":{"kind":"NamedType","name":{"kind":"Name","value":"String"}}}},{"kind":"VariableDefinition","variable":{"kind":"Variable","name":{"kind":"Name","value":"confirm"}},"type":{"kind":"NonNullType","type":{"kind":"NamedType","name":{"kind":"Name","value":"ConfirmInput"}}}}],"selectionSet":{"kind":"SelectionSet","selections":[{"kind":"Field","name":{"kind":"Name","value":"rejectOrgConfirm"},"arguments":[{"kind":"Argument","name":{"kind":"Name","value":"name"},"value":{"kind":"Variable","name":{"kind":"Name","value":"org"}}},{"kind":"Argument","name":{"kind":"Name","value":"confirm"},"value":{"kind":"Variable","name":{"kind":"Name","value":"confirm"}}}],"selectionSet":{"kind":"SelectionSet","selections":[{"kind":"Field","name":{"kind":"Name","value":"status"}}]}}]}}]} as unknown as DocumentNode<RejectLaunchRequest, RejectLaunchRequestVariables>;
export type CampaignOverview = (
  { __typename?: 'PrivateCampaign' }
  & { org: (
    { __typename?: 'PrivateOrg' }
    & OrgIds_PrivateOrg_
  ) | (
    { __typename?: 'PublicOrg' }
    & OrgIds_PublicOrg_
  ) }
  & CampaignFields_PrivateCampaign_
  & CampaignPrivateFields
  & CampaignAllStats_PrivateCampaign_
  & CampaignPartnerships
);

export type GetCampaignVariables = Exact<{
  org: Scalars['String'];
  id: Scalars['Int'];
}>;


export type GetCampaign = (
  { __typename?: 'RootQueryType' }
  & { org: (
    { __typename?: 'PrivateOrg' }
    & { campaign: (
      { __typename?: 'PrivateCampaign' }
      & { org: (
        { __typename?: 'PrivateOrg' }
        & OrgIds_PrivateOrg_
      ) | (
        { __typename?: 'PublicOrg' }
        & OrgIds_PublicOrg_
      ) }
      & CampaignFields_PrivateCampaign_
      & CampaignPrivateFields
      & CampaignAllStats_PrivateCampaign_
      & CampaignPartnerships
    ) | (
      { __typename?: 'PublicCampaign' }
      & { org: (
        { __typename?: 'PrivateOrg' }
        & OrgIds_PrivateOrg_
      ) | (
        { __typename?: 'PublicOrg' }
        & OrgIds_PublicOrg_
      ) }
      & CampaignFields_PublicCampaign_
      & CampaignAllStats_PublicCampaign_
    ) }
  ) }
);

export type FindPublicCampaignVariables = Exact<{
  name?: Maybe<Scalars['String']>;
  title?: Maybe<Scalars['String']>;
}>;


export type FindPublicCampaign = (
  { __typename?: 'RootQueryType' }
  & { campaigns: Array<(
    { __typename?: 'PrivateCampaign' }
    & { org: (
      { __typename?: 'PrivateOrg' }
      & OrgIds_PrivateOrg_
    ) | (
      { __typename?: 'PublicOrg' }
      & OrgIds_PublicOrg_
    ) }
    & CampaignFields_PrivateCampaign_
  ) | (
    { __typename?: 'PublicCampaign' }
    & { org: (
      { __typename?: 'PrivateOrg' }
      & OrgIds_PrivateOrg_
    ) | (
      { __typename?: 'PublicOrg' }
      & OrgIds_PublicOrg_
    ) }
    & CampaignFields_PublicCampaign_
  )> }
);

export type ListCampaignsVariables = Exact<{
  org: Scalars['String'];
}>;


export type ListCampaigns = (
  { __typename?: 'RootQueryType' }
  & { org: (
    { __typename?: 'PrivateOrg' }
    & { campaigns: Array<(
      { __typename?: 'PrivateCampaign' }
      & { org: (
        { __typename?: 'PrivateOrg' }
        & OrgIds_PrivateOrg_
      ) | (
        { __typename?: 'PublicOrg' }
        & OrgIds_PublicOrg_
      ) }
      & CampaignFields_PrivateCampaign_
      & CampaignPrivateFields
    ) | (
      { __typename?: 'PublicCampaign' }
      & { org: (
        { __typename?: 'PrivateOrg' }
        & OrgIds_PrivateOrg_
      ) | (
        { __typename?: 'PublicOrg' }
        & OrgIds_PublicOrg_
      ) }
      & CampaignFields_PublicCampaign_
    )> }
  ) }
);

type ActionPageOwners_PrivateActionPage_ = (
  { __typename?: 'PrivateActionPage' }
  & { campaign: (
    { __typename?: 'PrivateCampaign' }
    & { org: (
      { __typename?: 'PrivateOrg' }
      & OrgIds_PrivateOrg_
    ) | (
      { __typename?: 'PublicOrg' }
      & OrgIds_PublicOrg_
    ) }
    & CampaignIds_PrivateCampaign_
  ) | (
    { __typename?: 'PublicCampaign' }
    & { org: (
      { __typename?: 'PrivateOrg' }
      & OrgIds_PrivateOrg_
    ) | (
      { __typename?: 'PublicOrg' }
      & OrgIds_PublicOrg_
    ) }
    & CampaignIds_PublicCampaign_
  ), org: (
    { __typename?: 'PrivateOrg' }
    & OrgIds_PrivateOrg_
  ) | (
    { __typename?: 'PublicOrg' }
    & OrgIds_PublicOrg_
  ) }
  & ActionPageFields_PrivateActionPage_
);

type ActionPageOwners_PublicActionPage_ = (
  { __typename?: 'PublicActionPage' }
  & { campaign: (
    { __typename?: 'PrivateCampaign' }
    & { org: (
      { __typename?: 'PrivateOrg' }
      & OrgIds_PrivateOrg_
    ) | (
      { __typename?: 'PublicOrg' }
      & OrgIds_PublicOrg_
    ) }
    & CampaignIds_PrivateCampaign_
  ) | (
    { __typename?: 'PublicCampaign' }
    & { org: (
      { __typename?: 'PrivateOrg' }
      & OrgIds_PrivateOrg_
    ) | (
      { __typename?: 'PublicOrg' }
      & OrgIds_PublicOrg_
    ) }
    & CampaignIds_PublicCampaign_
  ), org: (
    { __typename?: 'PrivateOrg' }
    & OrgIds_PrivateOrg_
  ) | (
    { __typename?: 'PublicOrg' }
    & OrgIds_PublicOrg_
  ) }
  & ActionPageFields_PublicActionPage_
);

export type ActionPageOwners = ActionPageOwners_PrivateActionPage_ | ActionPageOwners_PublicActionPage_;

export type ListActionPagesVariables = Exact<{
  org: Scalars['String'];
}>;


export type ListActionPages = (
  { __typename?: 'RootQueryType' }
  & { org: (
    { __typename?: 'PrivateOrg' }
    & { actionPages: Array<(
      { __typename?: 'PrivateActionPage' }
      & ActionPageOwners_PrivateActionPage_
      & ActionPagePrivateFields
    ) | (
      { __typename?: 'PublicActionPage' }
      & ActionPageOwners_PublicActionPage_
    )> }
  ) }
);

export type GetActionPageVariables = Exact<{
  org: Scalars['String'];
  id?: Maybe<Scalars['Int']>;
  name?: Maybe<Scalars['String']>;
}>;


export type GetActionPage = (
  { __typename?: 'RootQueryType' }
  & { org: (
    { __typename?: 'PrivateOrg' }
    & Pick<PrivateOrg, 'name' | 'title'>
    & { actionPage: (
      { __typename?: 'PrivateActionPage' }
      & { campaign: (
        { __typename?: 'PrivateCampaign' }
        & CampaignFields_PrivateCampaign_
        & CampaignPrivateFields
      ) | (
        { __typename?: 'PublicCampaign' }
        & CampaignFields_PublicCampaign_
      ) }
      & ActionPageOwners_PrivateActionPage_
      & ActionPagePrivateFields
    ) | (
      { __typename?: 'PublicActionPage' }
      & { campaign: (
        { __typename?: 'PrivateCampaign' }
        & CampaignFields_PrivateCampaign_
        & CampaignPrivateFields
      ) | (
        { __typename?: 'PublicCampaign' }
        & CampaignFields_PublicCampaign_
      ) }
      & ActionPageOwners_PublicActionPage_
    ) }
  ) }
);

export type GetPublicActionPageVariables = Exact<{
  name?: Maybe<Scalars['String']>;
  id?: Maybe<Scalars['Int']>;
}>;


export type GetPublicActionPage = (
  { __typename?: 'RootQueryType' }
  & { actionPage: (
    { __typename?: 'PrivateActionPage' }
    & ActionPageOwners_PrivateActionPage_
  ) | (
    { __typename?: 'PublicActionPage' }
    & ActionPageOwners_PublicActionPage_
  ) }
);

export type ListActionPagesByCampaignVariables = Exact<{
  org: Scalars['String'];
  campaignId: Scalars['Int'];
}>;


export type ListActionPagesByCampaign = (
  { __typename?: 'RootQueryType' }
  & { org: (
    { __typename?: 'PrivateOrg' }
    & Pick<PrivateOrg, 'name' | 'title'>
    & { actionPages: Array<(
      { __typename?: 'PrivateActionPage' }
      & { campaign: (
        { __typename?: 'PrivateCampaign' }
        & CampaignFields_PrivateCampaign_
      ) | (
        { __typename?: 'PublicCampaign' }
        & CampaignFields_PublicCampaign_
      ) }
      & ActionPageFields_PrivateActionPage_
      & ActionPagePrivateFields
    ) | (
      { __typename?: 'PublicActionPage' }
      & { campaign: (
        { __typename?: 'PrivateCampaign' }
        & CampaignFields_PrivateCampaign_
      ) | (
        { __typename?: 'PublicCampaign' }
        & CampaignFields_PublicCampaign_
      ) }
      & ActionPageFields_PublicActionPage_
    )> }
  ) }
);

export type UpdateActionPageVariables = Exact<{
  id: Scalars['Int'];
  actionPage: ActionPageInput;
}>;


export type UpdateActionPage = (
  { __typename?: 'RootMutationType' }
  & { updateActionPage: (
    { __typename?: 'PrivateActionPage' }
    & Pick<PrivateActionPage, 'id'>
  ) | (
    { __typename?: 'PublicActionPage' }
    & Pick<PublicActionPage, 'id'>
  ) }
);

export type PubListCampaignVariables = Exact<{
  name: Scalars['String'];
}>;


export type PubListCampaign = (
  { __typename?: 'RootQueryType' }
  & { campaigns: Array<(
    { __typename?: 'PrivateCampaign' }
    & CampaignFields_PrivateCampaign_
  ) | (
    { __typename?: 'PublicCampaign' }
    & CampaignFields_PublicCampaign_
  )> }
);

export type ExportCampaignActionsVariables = Exact<{
  org: Scalars['String'];
  campaignId?: Maybe<Scalars['Int']>;
  campaignName?: Maybe<Scalars['String']>;
  start?: Maybe<Scalars['Int']>;
  after?: Maybe<Scalars['DateTime']>;
  limit?: Maybe<Scalars['Int']>;
  onlyOptIn?: Maybe<Scalars['Boolean']>;
}>;


export type ExportCampaignActions = (
  { __typename?: 'RootQueryType' }
  & { exportActions: Array<Maybe<(
    { __typename?: 'Action' }
    & { actionPage: (
      { __typename?: 'PrivateActionPage' }
      & ActionPageIds_PrivateActionPage_
    ) | (
      { __typename?: 'PublicActionPage' }
      & ActionPageIds_PublicActionPage_
    ) }
    & ActionExport
  )>> }
);

export type ExportOrgActionsVariables = Exact<{
  org: Scalars['String'];
  start?: Maybe<Scalars['Int']>;
  after?: Maybe<Scalars['DateTime']>;
  limit?: Maybe<Scalars['Int']>;
  onlyOptIn?: Maybe<Scalars['Boolean']>;
}>;


export type ExportOrgActions = (
  { __typename?: 'RootQueryType' }
  & { exportActions: Array<Maybe<(
    { __typename?: 'Action' }
    & { actionPage: (
      { __typename?: 'PrivateActionPage' }
      & ActionPageIds_PrivateActionPage_
    ) | (
      { __typename?: 'PublicActionPage' }
      & ActionPageIds_PublicActionPage_
    ), campaign: (
      { __typename?: 'PrivateCampaign' }
      & CampaignExportIds_PrivateCampaign_
    ) | (
      { __typename?: 'PublicCampaign' }
      & CampaignExportIds_PublicCampaign_
    ) }
    & ActionExport
  )>> }
);

export type CopyActionPageVariables = Exact<{
  fromName: Scalars['String'];
  toOrg: Scalars['String'];
  toName: Scalars['String'];
}>;


export type CopyActionPage = (
  { __typename?: 'RootMutationType' }
  & { copyActionPage: (
    { __typename?: 'PrivateActionPage' }
    & { campaign: (
      { __typename?: 'PrivateCampaign' }
      & CampaignFields_PrivateCampaign_
    ) | (
      { __typename?: 'PublicCampaign' }
      & CampaignFields_PublicCampaign_
    ) }
    & ActionPageFields_PrivateActionPage_
    & ActionPagePrivateFields
  ) | (
    { __typename?: 'PublicActionPage' }
    & { campaign: (
      { __typename?: 'PrivateCampaign' }
      & CampaignFields_PrivateCampaign_
    ) | (
      { __typename?: 'PublicCampaign' }
      & CampaignFields_PublicCampaign_
    ) }
    & ActionPageFields_PublicActionPage_
  ) }
);

export type CopyCampaignActionPageVariables = Exact<{
  fromCampaign: Scalars['String'];
  toOrg: Scalars['String'];
  toName: Scalars['String'];
}>;


export type CopyCampaignActionPage = (
  { __typename?: 'RootMutationType' }
  & { copyCampaignActionPage: (
    { __typename?: 'PrivateActionPage' }
    & { campaign: (
      { __typename?: 'PrivateCampaign' }
      & CampaignIds_PrivateCampaign_
    ) | (
      { __typename?: 'PublicCampaign' }
      & CampaignIds_PublicCampaign_
    ) }
    & ActionPageFields_PrivateActionPage_
    & ActionPagePrivateFields
  ) | (
    { __typename?: 'PublicActionPage' }
    & { campaign: (
      { __typename?: 'PrivateCampaign' }
      & CampaignIds_PrivateCampaign_
    ) | (
      { __typename?: 'PublicCampaign' }
      & CampaignIds_PublicCampaign_
    ) }
    & ActionPageFields_PublicActionPage_
  ) }
);

export type JoinOrgVariables = Exact<{
  orgName: Scalars['String'];
}>;


export type JoinOrg = (
  { __typename?: 'RootMutationType' }
  & { joinOrg: (
    { __typename?: 'JoinOrgResult' }
    & Pick<JoinOrgResult, 'status'>
  ) }
);

export type UpsertCampaignVariables = Exact<{
  org: Scalars['String'];
  campaign: CampaignInput;
}>;


export type UpsertCampaign = (
  { __typename?: 'RootMutationType' }
  & { upsertCampaign: (
    { __typename?: 'PrivateCampaign' }
    & Pick<PrivateCampaign, 'id'>
  ) | (
    { __typename?: 'PublicCampaign' }
    & Pick<PublicCampaign, 'id'>
  ) }
);

export type ListKeysVariables = Exact<{
  org: Scalars['String'];
}>;


export type ListKeys = (
  { __typename?: 'RootQueryType' }
  & { org: (
    { __typename?: 'PrivateOrg' }
    & { keys: Array<(
      { __typename?: 'Key' }
      & KeyFields
    )> }
  ) }
);

export type GenerateKeyVariables = Exact<{
  org: Scalars['String'];
  input: GenKeyInput;
}>;


export type GenerateKey = (
  { __typename?: 'RootMutationType' }
  & { generateKey: (
    { __typename?: 'KeyWithPrivate' }
    & Pick<KeyWithPrivate, 'id' | 'name' | 'public' | 'private' | 'active' | 'expired' | 'expiredAt'>
  ) }
);

export type AddKeyVariables = Exact<{
  org: Scalars['String'];
  input: AddKeyInput;
}>;


export type AddKey = (
  { __typename?: 'RootMutationType' }
  & { addKey: (
    { __typename?: 'Key' }
    & Pick<Key, 'id' | 'name' | 'public' | 'active' | 'expired' | 'expiredAt'>
  ) }
);

export type ActivateKeyVariables = Exact<{
  org: Scalars['String'];
  id: Scalars['Int'];
}>;


export type ActivateKey = (
  { __typename?: 'RootMutationType' }
  & { activateKey: (
    { __typename?: 'ActivateKeyResult' }
    & Pick<ActivateKeyResult, 'status'>
  ) }
);

export type AddOrgVariables = Exact<{
  org: OrgInput;
}>;


export type AddOrg = (
  { __typename?: 'RootMutationType' }
  & { addOrg: (
    { __typename?: 'PrivateOrg' }
    & OrgIds_PrivateOrg_
  ) | (
    { __typename?: 'PublicOrg' }
    & OrgIds_PublicOrg_
  ) }
);

export type UpdateOrgVariables = Exact<{
  orgName: Scalars['String'];
  org: OrgInput;
}>;


export type UpdateOrg = (
  { __typename?: 'RootMutationType' }
  & { updateOrg: (
    { __typename?: 'PrivateOrg' }
    & OrgFields_PrivateOrg_
    & OrgPrivateFields
  ) | (
    { __typename?: 'PublicOrg' }
    & OrgFields_PublicOrg_
  ) }
);

export type ActionPageUpsertedVariables = Exact<{
  org?: Maybe<Scalars['String']>;
}>;


export type ActionPageUpserted = (
  { __typename?: 'RootSubscriptionType' }
  & { actionPageUpserted: (
    { __typename?: 'PrivateActionPage' }
    & ActionPageOwners_PrivateActionPage_
    & ActionPagePrivateFields
  ) | (
    { __typename?: 'PublicActionPage' }
    & ActionPageOwners_PublicActionPage_
  ) }
);

export type CurrentUserOrgsVariables = Exact<{ [key: string]: never; }>;


export type CurrentUserOrgs = (
  { __typename?: 'RootQueryType' }
  & { currentUser: (
    { __typename?: 'User' }
    & Pick<User, 'id' | 'email'>
    & { roles: Array<(
      { __typename?: 'UserRole' }
      & Pick<UserRole, 'role'>
      & { org: (
        { __typename?: 'PrivateOrg' }
        & OrgIds_PrivateOrg_
      ) | (
        { __typename?: 'PublicOrg' }
        & OrgIds_PublicOrg_
      ) }
    )> }
  ) }
);

export type DashOrgOverviewVariables = Exact<{
  org: Scalars['String'];
}>;


export type DashOrgOverview = (
  { __typename?: 'RootQueryType' }
  & { org: (
    { __typename?: 'PrivateOrg' }
    & Pick<PrivateOrg, 'name' | 'title'>
    & { campaigns: Array<(
      { __typename?: 'PrivateCampaign' }
      & { org: (
        { __typename?: 'PrivateOrg' }
        & OrgIds_PrivateOrg_
      ) | (
        { __typename?: 'PublicOrg' }
        & OrgIds_PublicOrg_
      ) }
      & CampaignFields_PrivateCampaign_
      & CampaignAllStats_PrivateCampaign_
    ) | (
      { __typename?: 'PublicCampaign' }
      & { org: (
        { __typename?: 'PrivateOrg' }
        & OrgIds_PrivateOrg_
      ) | (
        { __typename?: 'PublicOrg' }
        & OrgIds_PublicOrg_
      ) }
      & CampaignFields_PublicCampaign_
      & CampaignAllStats_PublicCampaign_
    )> }
    & OrgPrivateFields
  ) }
);

export type GetOrgVariables = Exact<{
  org: Scalars['String'];
}>;


export type GetOrg = (
  { __typename?: 'RootQueryType' }
  & { org: (
    { __typename?: 'PrivateOrg' }
    & { keys: Array<(
      { __typename?: 'Key' }
      & KeyFields
    )>, services: Array<Maybe<(
      { __typename?: 'Service' }
      & ServiceFields
    )>> }
    & OrgFields_PrivateOrg_
    & OrgPrivateFields
  ) }
);

export type GetOrgAttrsVariables = Exact<{
  org: Scalars['String'];
}>;


export type GetOrgAttrs = (
  { __typename?: 'RootQueryType' }
  & { org: (
    { __typename?: 'PrivateOrg' }
    & OrgFields_PrivateOrg_
    & OrgPrivateFields
  ) }
);

export type LaunchActionPageVariables = Exact<{
  name: Scalars['String'];
}>;


export type LaunchActionPage = (
  { __typename?: 'RootMutationType' }
  & { launchActionPage: (
    { __typename?: 'LaunchActionPageResult' }
    & Pick<LaunchActionPageResult, 'status'>
  ) }
);

export type AcceptLaunchRequestVariables = Exact<{
  org: Scalars['String'];
  confirm: ConfirmInput;
}>;


export type AcceptLaunchRequest = (
  { __typename?: 'RootMutationType' }
  & { acceptOrgConfirm: (
    { __typename?: 'ConfirmResult' }
    & Pick<ConfirmResult, 'status'>
    & { actionPage: Maybe<(
      { __typename?: 'PrivateActionPage' }
      & ActionPageFields_PrivateActionPage_
    ) | (
      { __typename?: 'PublicActionPage' }
      & ActionPageFields_PublicActionPage_
    )> }
  ) }
);

export type RejectLaunchRequestVariables = Exact<{
  org: Scalars['String'];
  confirm: ConfirmInput;
}>;


export type RejectLaunchRequest = (
  { __typename?: 'RootMutationType' }
  & { rejectOrgConfirm: (
    { __typename?: 'ConfirmResult' }
    & Pick<ConfirmResult, 'status'>
  ) }
);

type OrgIds_PrivateOrg_ = (
  { __typename: 'PrivateOrg' }
  & Pick<PrivateOrg, 'id' | 'name' | 'title'>
);

type OrgIds_PublicOrg_ = (
  { __typename: 'PublicOrg' }
  & Pick<PublicOrg, 'name' | 'title'>
);

export type OrgIds = OrgIds_PrivateOrg_ | OrgIds_PublicOrg_;

type CampaignIds_PrivateCampaign_ = (
  { __typename: 'PrivateCampaign' }
  & Pick<PrivateCampaign, 'id' | 'externalId' | 'name' | 'title'>
);

type CampaignIds_PublicCampaign_ = (
  { __typename: 'PublicCampaign' }
  & Pick<PublicCampaign, 'id' | 'externalId' | 'name' | 'title'>
);

export type CampaignIds = CampaignIds_PrivateCampaign_ | CampaignIds_PublicCampaign_;

type CampaignExportIds_PrivateCampaign_ = (
  { __typename: 'PrivateCampaign' }
  & Pick<PrivateCampaign, 'name' | 'externalId'>
);

type CampaignExportIds_PublicCampaign_ = (
  { __typename: 'PublicCampaign' }
  & Pick<PublicCampaign, 'name' | 'externalId'>
);

export type CampaignExportIds = CampaignExportIds_PrivateCampaign_ | CampaignExportIds_PublicCampaign_;

type CampaignFields_PrivateCampaign_ = (
  { __typename: 'PrivateCampaign' }
  & Pick<PrivateCampaign, 'id' | 'externalId' | 'name' | 'title' | 'contactSchema' | 'config'>
);

type CampaignFields_PublicCampaign_ = (
  { __typename: 'PublicCampaign' }
  & Pick<PublicCampaign, 'id' | 'externalId' | 'name' | 'title' | 'contactSchema' | 'config'>
);

export type CampaignFields = CampaignFields_PrivateCampaign_ | CampaignFields_PublicCampaign_;

export type CampaignPrivateFields = (
  { __typename: 'PrivateCampaign' }
  & Pick<PrivateCampaign, 'forceDelivery'>
);

type CampaignAllStats_PrivateCampaign_ = (
  { __typename?: 'PrivateCampaign' }
  & { stats: (
    { __typename?: 'CampaignStats' }
    & Pick<CampaignStats, 'supporterCount'>
    & { supporterCountByOrg: Array<(
      { __typename?: 'OrgCount' }
      & Pick<OrgCount, 'count'>
      & { org: (
        { __typename?: 'PrivateOrg' }
        & Pick<PrivateOrg, 'name' | 'title'>
      ) | (
        { __typename?: 'PublicOrg' }
        & Pick<PublicOrg, 'name' | 'title'>
      ) }
    )>, actionCount: Array<(
      { __typename?: 'ActionTypeCount' }
      & Pick<ActionTypeCount, 'actionType' | 'count'>
    )> }
  ) }
);

type CampaignAllStats_PublicCampaign_ = (
  { __typename?: 'PublicCampaign' }
  & { stats: (
    { __typename?: 'CampaignStats' }
    & Pick<CampaignStats, 'supporterCount'>
    & { supporterCountByOrg: Array<(
      { __typename?: 'OrgCount' }
      & Pick<OrgCount, 'count'>
      & { org: (
        { __typename?: 'PrivateOrg' }
        & Pick<PrivateOrg, 'name' | 'title'>
      ) | (
        { __typename?: 'PublicOrg' }
        & Pick<PublicOrg, 'name' | 'title'>
      ) }
    )>, actionCount: Array<(
      { __typename?: 'ActionTypeCount' }
      & Pick<ActionTypeCount, 'actionType' | 'count'>
    )> }
  ) }
);

export type CampaignAllStats = CampaignAllStats_PrivateCampaign_ | CampaignAllStats_PublicCampaign_;

export type CampaignPartnerships = (
  { __typename: 'PrivateCampaign' }
  & { partnerships: Maybe<Array<(
    { __typename?: 'Partnership' }
    & { org: (
      { __typename?: 'PrivateOrg' }
      & OrgIds_PrivateOrg_
    ) | (
      { __typename?: 'PublicOrg' }
      & OrgIds_PublicOrg_
    ), actionPages: Array<(
      { __typename?: 'PrivateActionPage' }
      & ActionPageFields_PrivateActionPage_
    ) | (
      { __typename?: 'PublicActionPage' }
      & ActionPageFields_PublicActionPage_
    )>, launchRequests: Array<(
      { __typename?: 'Confirm' }
      & Pick<Confirm, 'code' | 'email' | 'objectId'>
    )> }
  )>> }
);

type ActionPageIds_PrivateActionPage_ = (
  { __typename?: 'PrivateActionPage' }
  & Pick<PrivateActionPage, 'id' | 'name' | 'locale'>
);

type ActionPageIds_PublicActionPage_ = (
  { __typename?: 'PublicActionPage' }
  & Pick<PublicActionPage, 'id' | 'name' | 'locale'>
);

export type ActionPageIds = ActionPageIds_PrivateActionPage_ | ActionPageIds_PublicActionPage_;

type ActionPageFields_PrivateActionPage_ = (
  { __typename: 'PrivateActionPage' }
  & Pick<PrivateActionPage, 'id' | 'name' | 'locale' | 'config' | 'live' | 'journey' | 'thankYouTemplateRef'>
);

type ActionPageFields_PublicActionPage_ = (
  { __typename: 'PublicActionPage' }
  & Pick<PublicActionPage, 'id' | 'name' | 'locale' | 'config' | 'live' | 'journey' | 'thankYouTemplateRef'>
);

export type ActionPageFields = ActionPageFields_PrivateActionPage_ | ActionPageFields_PublicActionPage_;

export type ActionPagePrivateFields = (
  { __typename: 'PrivateActionPage' }
  & Pick<PrivateActionPage, 'extraSupporters' | 'delivery'>
);

type OrgFields_PrivateOrg_ = (
  { __typename: 'PrivateOrg' }
  & Pick<PrivateOrg, 'name' | 'title'>
);

type OrgFields_PublicOrg_ = (
  { __typename: 'PublicOrg' }
  & Pick<PublicOrg, 'name' | 'title'>
);

export type OrgFields = OrgFields_PrivateOrg_ | OrgFields_PublicOrg_;

export type OrgPrivateFields = (
  { __typename: 'PrivateOrg' }
  & Pick<PrivateOrg, 'config'>
  & { personalData: (
    { __typename?: 'PersonalData' }
    & Pick<PersonalData, 'contactSchema' | 'emailOptIn' | 'emailOptInTemplate'>
  ) }
);

export type KeyFields = (
  { __typename?: 'Key' }
  & Pick<Key, 'id' | 'name' | 'public' | 'active' | 'expired' | 'expiredAt'>
);

export type ServiceFields = (
  { __typename?: 'Service' }
  & Pick<Service, 'id' | 'name' | 'host' | 'user' | 'path'>
);

export type ContactExport = (
  { __typename?: 'Contact' }
  & Pick<Contact, 'contactRef' | 'payload' | 'nonce'>
  & { publicKey: Maybe<(
    { __typename?: 'KeyIds' }
    & Pick<KeyIds, 'id' | 'public'>
  )>, signKey: Maybe<(
    { __typename?: 'KeyIds' }
    & Pick<KeyIds, 'id' | 'public'>
  )> }
);

export type ActionExport = (
  { __typename?: 'Action' }
  & Pick<Action, 'actionId' | 'actionType' | 'createdAt'>
  & { contact: (
    { __typename?: 'Contact' }
    & ContactExport
  ), fields: Array<(
    { __typename?: 'CustomField' }
    & Pick<CustomField, 'key' | 'value'>
  )>, tracking: Maybe<(
    { __typename?: 'Tracking' }
    & Pick<Tracking, 'source' | 'medium' | 'campaign' | 'content'>
  )>, privacy: (
    { __typename?: 'Consent' }
    & Pick<Consent, 'optIn' | 'givenAt'>
  ) }
);


export type ObjectFieldTypes = {
    [key: string]: { [key: string]: string | string[] }
};

export type OpTypes = {
    [key: string]: string | string[]
};

export type ScalarLocations = {
 scalars: string[],
 inputObjectFieldTypes: ObjectFieldTypes;
 outputObjectFieldTypes: ObjectFieldTypes;
 operationMap: OpTypes;
};

export const scalarLocations : ScalarLocations = {
  "inputObjectFieldTypes": {
    "ActionInput": {
      "fields": "CustomFieldInput",
      "donation": "DonationActionInput"
    },
    "ActionPageInput": {
      "config": "Json"
    },
    "CampaignInput": {
      "config": "Json",
      "actionPages": "ActionPageInput"
    },
    "ContactInput": {
      "address": "AddressInput",
      "nationality": "NationalityInput"
    },
    "DonationActionInput": {
      "payload": "Json"
    },
    "OrgInput": {
      "config": "Json"
    }
  },
  "outputObjectFieldTypes": {
    "Action": {
      "contact": "Contact",
      "fields": "CustomField",
      "tracking": "Tracking",
      "campaign": [
        "PrivateCampaign",
        "PublicCampaign"
      ],
      "actionPage": [
        "PrivateActionPage",
        "PublicActionPage"
      ],
      "privacy": "Consent",
      "donation": "Donation"
    },
    "ActionCustomFields": {
      "fields": "CustomField"
    },
    "CampaignStats": {
      "supporterCountByArea": "AreaCount",
      "supporterCountByOrg": "OrgCount",
      "actionCount": "ActionTypeCount"
    },
    "ConfirmResult": {
      "actionPage": [
        "PrivateActionPage",
        "PublicActionPage"
      ],
      "campaign": [
        "PrivateCampaign",
        "PublicCampaign"
      ],
      "org": [
        "PrivateOrg",
        "PublicOrg"
      ]
    },
    "Contact": {
      "publicKey": "KeyIds",
      "signKey": "KeyIds"
    },
    "Donation": {
      "payload": "Json"
    },
    "JoinOrgResult": {
      "org": [
        "PrivateOrg",
        "PublicOrg"
      ]
    },
    "OrgCount": {
      "org": [
        "PrivateOrg",
        "PublicOrg"
      ]
    },
    "Partnership": {
      "org": [
        "PrivateOrg",
        "PublicOrg"
      ],
      "actionPages": [
        "PrivateActionPage",
        "PublicActionPage"
      ],
      "launchRequests": "Confirm"
    },
    "PrivateActionPage": {
      "config": "Json",
      "campaign": [
        "PrivateCampaign",
        "PublicCampaign"
      ],
      "org": [
        "PrivateOrg",
        "PublicOrg"
      ]
    },
    "PrivateCampaign": {
      "config": "Json",
      "stats": "CampaignStats",
      "org": [
        "PrivateOrg",
        "PublicOrg"
      ],
      "actions": "PublicActionsResult",
      "partnerships": "Partnership"
    },
    "PrivateOrg": {
      "config": "Json",
      "personalData": "PersonalData",
      "keys": "Key",
      "key": "Key",
      "services": "Service",
      "users": "OrgUser",
      "campaigns": [
        "PrivateCampaign",
        "PublicCampaign"
      ],
      "actionPages": [
        "PrivateActionPage",
        "PublicActionPage"
      ],
      "actionPage": [
        "PrivateActionPage",
        "PublicActionPage"
      ],
      "campaign": [
        "PrivateCampaign",
        "PublicCampaign"
      ]
    },
    "PublicActionPage": {
      "config": "Json",
      "campaign": [
        "PrivateCampaign",
        "PublicCampaign"
      ],
      "org": [
        "PrivateOrg",
        "PublicOrg"
      ]
    },
    "PublicActionsResult": {
      "list": "ActionCustomFields"
    },
    "PublicCampaign": {
      "config": "Json",
      "stats": "CampaignStats",
      "org": [
        "PrivateOrg",
        "PublicOrg"
      ],
      "actions": "PublicActionsResult"
    },
    "RootSubscriptionType": {
      "actionPageUpserted": [
        "PrivateActionPage",
        "PublicActionPage"
      ]
    },
    "User": {
      "roles": "UserRole"
    },
    "UserRole": {
      "org": [
        "PrivateOrg",
        "PublicOrg"
      ]
    }
  },
  "operationMap": {
    "upsertCampaign": [
      "PrivateCampaign",
      "PublicCampaign"
    ],
    "updateActionPage": [
      "PrivateActionPage",
      "PublicActionPage"
    ],
    "copyActionPage": [
      "PrivateActionPage",
      "PublicActionPage"
    ],
    "copyCampaignActionPage": [
      "PrivateActionPage",
      "PublicActionPage"
    ],
    "launchActionPage": "LaunchActionPageResult",
    "addAction": "ContactReference",
    "addActionContact": "ContactReference",
    "linkActions": "ContactReference",
    "addOrgUser": "ChangeUserStatus",
    "updateOrgUser": "ChangeUserStatus",
    "deleteOrgUser": "DeleteUserResult",
    "addOrg": [
      "PrivateOrg",
      "PublicOrg"
    ],
    "updateOrg": [
      "PrivateOrg",
      "PublicOrg"
    ],
    "joinOrg": "JoinOrgResult",
    "generateKey": "KeyWithPrivate",
    "addKey": "Key",
    "activateKey": "ActivateKeyResult",
    "addStripePaymentIntent": "Json",
    "addStripeSubscription": "Json",
    "addStripeObject": "Json",
    "acceptOrgConfirm": "ConfirmResult",
    "rejectOrgConfirm": "ConfirmResult",
    "campaigns": [
      "PrivateCampaign",
      "PublicCampaign"
    ],
    "actionPage": [
      "PrivateActionPage",
      "PublicActionPage"
    ],
    "exportActions": "Action",
    "currentUser": "User",
    "org": "PrivateOrg"
  },
  "scalars": [
    "Json"
  ]
};
