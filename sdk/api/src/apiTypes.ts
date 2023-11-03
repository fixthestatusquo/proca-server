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
  Json: any;
  /**
   * The `Naive DateTime` scalar type represents a naive date and time without
   * timezone. The DateTime appears in a JSON response as an ISO8601 formatted
   * string.
   */
  NaiveDateTime: any;
};

export type Action = {
  /** Id of action */
  actionId: Scalars['Int'];
  /** Timestamp of creation */
  createdAt: Scalars['NaiveDateTime'];
  /** Action type */
  actionType: Scalars['String'];
  /** supporter contact data */
  contact: Contact;
  /** Action custom fields (as stringified JSON) */
  customFields: Scalars['Json'];
  /**
   * Deprecated, use customFields
   * @deprecated use custom_fields
   */
  fields: Array<CustomField>;
  /** UTM codes */
  tracking: Maybe<Tracking>;
  /** Campaign this action was collected in */
  campaign: Campaign;
  /** Action page this action was collected at */
  actionPage: ActionPage;
  /** Consents, privacy data of this action */
  privacy: Consent;
  /** Donation specific data */
  donation: Maybe<Donation>;
};

export type ActionCustomFields = {
  /** id of action */
  actionId: Scalars['Int'];
  /** type of action */
  actionType: Scalars['String'];
  /** creation timestamp */
  insertedAt: Scalars['NaiveDateTime'];
  /** area of supporter that did the action */
  area: Maybe<Scalars['String']>;
  /** custom fields as stringified json */
  customFields: Scalars['Json'];
  /** @deprecated use custom_fields */
  fields: Array<CustomField>;
};

/** Custom field added to action. For signature it can be contact, for mail it can be subject and body */
export type ActionInput = {
  /** Action Type */
  actionType: Scalars['String'];
  /** Custom fields added to action */
  customFields?: Maybe<Scalars['Json']>;
  /** Deprecated format: Other fields added to action */
  fields?: Maybe<Array<CustomFieldInput>>;
  /** Donation payload */
  donation?: Maybe<DonationActionInput>;
  /** MTT payload */
  mtt?: Maybe<MttActionInput>;
  /** Test mode */
  testing?: Maybe<Scalars['Boolean']>;
};

export type ActionPage = {
  /** Id */
  id: Scalars['Int'];
  /** Locale for the widget, in i18n format */
  locale: Scalars['String'];
  /** Name where the widget is hosted */
  name: Scalars['String'];
  /** Thank you email templated of this Action Page */
  thankYouTemplate: Maybe<Scalars['String']>;
  /** A reference to thank you email template of this ActionPage */
  thankYouTemplateRef: Maybe<Scalars['String']>;
  /** Is live? */
  live: Scalars['Boolean'];
  /**
   * List of steps in journey
   * @deprecated moved under config
   */
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
   * slugs/names change (eg. some.org/1234). However, frontend Widget can
   * ask for ActionPage by it's current location.href (but without https://), in which case it is useful
   * to make this url match the real widget location.
   */
  name?: Maybe<Scalars['String']>;
  /** 2-letter, lowercase, code of ActionPage language */
  locale?: Maybe<Scalars['String']>;
  /** Thank you email template of this ActionPage */
  thankYouTemplate?: Maybe<Scalars['String']>;
  /** Supporter confirm email template of this ActionPage */
  supporterConfirmTemplate?: Maybe<Scalars['String']>;
  /** Extra supporter count. If you want to add a number of signatories you have offline or kept in another system, you can specify the number here. */
  extraSupporters?: Maybe<Scalars['Int']>;
  /** JSON string containing Action Page config */
  config?: Maybe<Scalars['Json']>;
  /** Collected PII is processed even with no opt-in */
  delivery?: Maybe<Scalars['Boolean']>;
};

export enum ActionPageStatus {
  /** This action page is ready to receive first action or is stalled for over 1 year */
  Standby = 'STANDBY',
  /** This action page received actions lately */
  Active = 'ACTIVE',
  /** This action page did not receive actions lately */
  Stalled = 'STALLED'
}

/** Count of actions for particular action type */
export type ActionTypeCount = {
  /** action type */
  actionType: Scalars['String'];
  /** count of actions of action type */
  count: Scalars['Int'];
};

export type ActivateKeyResult = {
  status: Status;
};

export type AddKeyInput = {
  /** Name of the key */
  name: Scalars['String'];
  /** Public part of the key (base64url) */
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

/** Api token metadata */
export type ApiToken = {
  expiresAt: Scalars['NaiveDateTime'];
};

/** Count of actions for particular action type */
export type AreaCount = {
  /** area */
  area: Scalars['String'];
  /** count of supporters in this area */
  count: Scalars['Int'];
};

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
  /** Statistics */
  stats: CampaignStats;
  /** Lead org */
  org: Org;
  /**
   * Fetch public actions. Can be used to display recent comments for example.
   *
   * To allow-list action fields to be public, `campaign.public_actions` must be set to a list of strings in form
   * action_type:custom_field_name, eg: `["signature:comment"]`. XXX this cannot be set in API, you need to set in backend.
   */
  actions: PublicActionsResult;
  /** List MTT targets of this campaign */
  targets: Maybe<Array<Maybe<Target>>>;
};


export type CampaignActionsArgs = {
  actionType: Scalars['String'];
  limit: Scalars['Int'];
};

/** Campaign content changed in mutations */
export type CampaignInput = {
  /** Campaign short name */
  name?: Maybe<Scalars['String']>;
  /** Campaign external_id. If provided, it will be used to find campaign. Can be used to rename a campaign */
  externalId?: Maybe<Scalars['Int']>;
  /** Campaign human readable title */
  title?: Maybe<Scalars['String']>;
  /** Schema for contact personal information */
  contactSchema?: Maybe<ContactSchema>;
  /** Custom config as stringified JSON map */
  config?: Maybe<Scalars['Json']>;
  /** Action pages of this campaign */
  actionPages?: Maybe<Array<ActionPageInput>>;
  /** MTT configuration */
  mtt?: Maybe<CampaignMttInput>;
};

export type CampaignMtt = {
  /** This is first day and start hour of the campaign. Note, every day of the campaign the start hour will be same. */
  startAt: Scalars['DateTime'];
  /** This is last day and end hour of the campaign. Note, every day of the campaign the end hour will be same. */
  endAt: Scalars['DateTime'];
  /**
   * If email templates are used to create MTT, use this template (works like thank you email templates).
   * Otherwise, the raw text that is send with MTT action will make a plain text email.
   */
  messageTemplate: Maybe<Scalars['String']>;
  /** A test target email (yourself) where test mtt actions will be sent (instead to real targets) */
  testEmail: Maybe<Scalars['String']>;
};

export type CampaignMttInput = {
  /** This is first day and start hour of the campaign. Note, every day of the campaign the start hour will be same. */
  startAt?: Maybe<Scalars['DateTime']>;
  /** This is last day and end hour of the campaign. Note, every day of the campaign the end hour will be same. */
  endAt?: Maybe<Scalars['DateTime']>;
  /**
   * If email templates are used to create MTT, use this template (works like thank you email templates).
   * Otherwise, the raw text that is send with MTT action will make a plain text email.
   */
  messageTemplate?: Maybe<Scalars['String']>;
  /** A test target email (yourself) where test mtt actions will be sent (instead to real targets) */
  testEmail?: Maybe<Scalars['String']>;
};

/** Campaign statistics */
export type CampaignStats = {
  /** Unique action tagers count */
  supporterCount: Scalars['Int'];
  /** Unique action takers by area */
  supporterCountByArea: Array<AreaCount>;
  /** Unique action takers by org */
  supporterCountByOrg: Array<OrgCount>;
  /** Unique supporter count not including the ones collected by org_name */
  supporterCountByOthers: Scalars['Int'];
  /** Action counts per action types (with duplicates) */
  actionCount: Array<ActionTypeCount>;
};


/** Campaign statistics */
export type CampaignStatsSupporterCountByOthersArgs = {
  orgName: Scalars['String'];
};

export type ChangeUserStatus = {
  status: Status;
};

export type Confirm = {
  /** Secret code/PIN of the confirm */
  code: Scalars['String'];
  /** Email the confirm is sent to */
  email: Maybe<Scalars['String']>;
  /** Message attached to the confirm */
  message: Maybe<Scalars['String']>;
  /** Object id that confirmable action refers to */
  objectId: Maybe<Scalars['Int']>;
  /** Who created the confirm */
  creator: Maybe<User>;
};

export type ConfirmInput = {
  /** secret code of this confirm */
  code: Scalars['String'];
  /** email that confirm was assigned for */
  email?: Maybe<Scalars['String']>;
  /** object_id that this confirm refers to */
  objectId?: Maybe<Scalars['Int']>;
};

export type ConfirmResult = {
  /** Status of Confirm: Success, Confirming (waiting for confirmation), Noop */
  status: Status;
  /** Action page if its an object of confirm */
  actionPage: Maybe<ActionPage>;
  /** Campaign page if its an object of confirm */
  campaign: Maybe<Campaign>;
  /** Org if its an object of confirm */
  org: Maybe<Org>;
  /** A message attached to the confirm */
  message: Maybe<Scalars['String']>;
};

/** GDPR consent data for this org */
export type Consent = {
  /** communication (email) opt-in */
  optIn: Maybe<Scalars['Boolean']>;
  /** Consent timestamp */
  givenAt: Scalars['NaiveDateTime'];
  /** Email status, whether it's normal, DOI, or bouncing */
  emailStatus: EmailStatus;
  /** When did the email status change last time */
  emailStatusChanged: Maybe<Scalars['NaiveDateTime']>;
  /** This action contained consent (if false, it could be a share action that is attached to another action containing a consent) */
  withConsent: Scalars['Boolean'];
};

/** GDPR consent data structure */
export type ConsentInput = {
  /** Has contact consented to receiving communication from widget owner? Null: not asked */
  optIn?: Maybe<Scalars['Boolean']>;
  /** Opt in to the campaign leader */
  leadOptIn?: Maybe<Scalars['Boolean']>;
};

export type Contact = {
  /** Contact ref (fingerprint) of supporter */
  contactRef: Scalars['ID'];
  /** Stringified json with PII optionally encrypted */
  payload: Scalars['String'];
  /** Encryption nonce value */
  nonce: Maybe<Scalars['String']>;
  /** Public key used to encrypt this action */
  publicKey: Maybe<KeyIds>;
  /** Signing key used to encrypt this action */
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
  key: Scalars['String'];
  value: Scalars['String'];
};

/** Custom field with a key and value. Both are strings. */
export type CustomFieldInput = {
  key: Scalars['String'];
  value: Scalars['String'];
  /** Unused. To mark action_type/key as transient, use campaign.transient_actions list */
  transient?: Maybe<Scalars['Boolean']>;
};



export type DeleteUserResult = {
  status: Status;
};

export type Donation = {
  schema: Maybe<DonationSchema>;
  /** Provide amount of this donation, in smallest units for currency */
  amount: Scalars['Int'];
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
  /** Provide amount of this donation, in smallest units for currency */
  amount?: Maybe<Scalars['Int']>;
  /** Provide currency of this donation */
  currency?: Maybe<Scalars['String']>;
  /** How often is the recurring donation collected */
  frequencyUnit?: Maybe<DonationFrequencyUnit>;
  /** Custom JSON data */
  payload: Scalars['Json'];
};

export enum DonationFrequencyUnit {
  OneOff = 'ONE_OFF',
  Weekly = 'WEEKLY',
  Monthly = 'MONTHLY',
  Daily = 'DAILY'
}

export enum DonationSchema {
  StripePaymentIntent = 'STRIPE_PAYMENT_INTENT'
}

export enum EmailStatus {
  /** An unused email. (Warning:  Or used, but we do not store the fact that emails are delivered ok) */
  None = 'NONE',
  /** The user has received a DOI on this email and accepted it */
  DoubleOptIn = 'DOUBLE_OPT_IN',
  /** This email was used and bounced */
  Bounce = 'BOUNCE',
  /** This email was used and blocked */
  Blocked = 'BLOCKED',
  /** This email was used and marked spam */
  Spam = 'SPAM',
  /** This email was used and user unsubscribed */
  Unsub = 'UNSUB'
}

export type EmailTemplateInput = {
  /** template name */
  name: Scalars['String'];
  /** template locale */
  locale?: Maybe<Scalars['String']>;
  /** Subject text */
  subject?: Maybe<Scalars['String']>;
  /** Html part body */
  html?: Maybe<Scalars['String']>;
  /** Plaintext part body */
  text?: Maybe<Scalars['String']>;
};

export type GenKeyInput = {
  /** Name of the key */
  name: Scalars['String'];
};

export type JoinOrgResult = {
  /** Result of joining - succes or pending confirmation */
  status: Status;
  /** Org that was joined */
  org: Org;
};


/** Encryption or sign key with integer id (database) */
export type Key = {
  /** Key id */
  id: Scalars['Int'];
  /** Public part of the key (base64url) */
  public: Scalars['String'];
  /** Name of the key (human readable) */
  name: Scalars['String'];
  /** Is it active? */
  active: Scalars['Boolean'];
  /** Is it expired? */
  expired: Scalars['Boolean'];
  /** When the key was expired, in UTC */
  expiredAt: Maybe<Scalars['NaiveDateTime']>;
};

export type KeyIds = {
  /** Key id */
  id: Scalars['Int'];
  /** Public part of the key (base64url) */
  public: Scalars['String'];
};

export type KeyWithPrivate = {
  /** Key id */
  id: Scalars['Int'];
  /** Public part of the key (base64url) */
  public: Scalars['String'];
  /** Private (Secret) part of the key (base64url) */
  private: Scalars['String'];
  /** Name of the key (human readable) */
  name: Scalars['String'];
  /** Is it active? */
  active: Scalars['Boolean'];
  /** Is it expired? */
  expired: Scalars['Boolean'];
  /** When the key was expired, in UTC */
  expiredAt: Maybe<Scalars['NaiveDateTime']>;
};

export type LaunchActionPageResult = {
  status: Status;
};

export type MttActionInput = {
  /** Subject line */
  subject?: Maybe<Scalars['String']>;
  /** Body */
  body?: Maybe<Scalars['String']>;
  /** Target ids */
  targets: Array<Scalars['String']>;
  /** Files to attach (images allowed) */
  files?: Maybe<Array<Scalars['String']>>;
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
  /** config */
  config: Scalars['Json'];
};

/** Count of supporters for particular org */
export type OrgCount = {
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
  supporterConfirm?: Maybe<Scalars['Boolean']>;
  /** Email opt in template name */
  supporterConfirmTemplate?: Maybe<Scalars['String']>;
  /** Only send thank you emails to opt-ins */
  doiThankYou?: Maybe<Scalars['Boolean']>;
  /** Config */
  config?: Maybe<Scalars['Json']>;
};

export type OrgUser = {
  email: Scalars['String'];
  /** Role in an org */
  role: Scalars['String'];
  /** Date and time the user was created on this instance */
  createdAt: Scalars['NaiveDateTime'];
  /** Date and time when user joined org */
  joinedAt: Scalars['NaiveDateTime'];
  /** Will be removed */
  lastSigninAt: Maybe<Scalars['NaiveDateTime']>;
};

export type OrgUserInput = {
  /** Email of user */
  email: Scalars['String'];
  /** Role name of user in this org */
  role: Scalars['String'];
};

export type Partnership = {
  /** Partner org */
  org: Org;
  /** Partner's pages that are part of this campaign (can be more, eg: multiple languages) */
  actionPages: Array<ActionPage>;
  /** Join/Launch requests of this partner */
  launchRequests: Array<Confirm>;
  /** The partner staffers who initiated a request */
  launchRequesters: Array<User>;
};

export type PersonalData = {
  /** Schema for contact personal information */
  contactSchema: ContactSchema;
  /** Email opt in enabled */
  supporterConfirm: Scalars['Boolean'];
  /** Email opt in template name */
  supporterConfirmTemplate: Maybe<Scalars['String']>;
  /** High data security enabled */
  highSecurity: Scalars['Boolean'];
  /** Only send thank you emails to opt-ins */
  doiThankYou: Scalars['Boolean'];
};

export type PrivateActionPage = ActionPage & {
  /** Id */
  id: Scalars['Int'];
  /** Locale for the widget, in i18n format */
  locale: Scalars['String'];
  /** Name where the widget is hosted */
  name: Scalars['String'];
  /** Thank you email templated of this Action Page */
  thankYouTemplate: Maybe<Scalars['String']>;
  /** A reference to thank you email template of this ActionPage */
  thankYouTemplateRef: Maybe<Scalars['String']>;
  /** Is live? */
  live: Scalars['Boolean'];
  /**
   * List of steps in journey
   * @deprecated moved under config
   */
  journey: Array<Scalars['String']>;
  /** Config JSON of this action page */
  config: Scalars['Json'];
  /** Campaign this action page belongs to. */
  campaign: Campaign;
  /** Org the action page belongs to */
  org: Org;
  /** Extra supporters, a number added to deduplicated supporter count. Cannot be added to per-area or per-action_type counts. */
  extraSupporters: Scalars['Int'];
  /**
   * Action page collects also opt-out actions, to deliver them to authorities.
   * If false, the opt-outs will fallback to lead (we never trash data with opt-outs)
   */
  delivery: Scalars['Boolean'];
  /** Email template to confirm supporter (DOI) */
  supporterConfirmTemplate: Maybe<Scalars['String']>;
  /** Location of the widget as last seen in HTTP REFERER header */
  location: Maybe<Scalars['String']>;
  /** Status of action page - STANDBY (ready to get actions), ACTIVE (collecting actions), STALLED (actions not coming any more) */
  status: Maybe<ActionPageStatus>;
};

export type PrivateCampaign = Campaign & {
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
  /** Statistics */
  stats: CampaignStats;
  /** Lead org */
  org: Org;
  /**
   * Fetch public actions. Can be used to display recent comments for example.
   *
   * To allow-list action fields to be public, `campaign.public_actions` must be set to a list of strings in form
   * action_type:custom_field_name, eg: `["signature:comment"]`. XXX this cannot be set in API, you need to set in backend.
   */
  actions: PublicActionsResult;
  /** List MTT targets of this campaign */
  targets: Maybe<Array<Maybe<Target>>>;
  /** Campaign onwer collects opt-out actions for delivery even if campaign partner is delivering */
  forceDelivery: Scalars['Boolean'];
  /** Action Pages of this campaign that are accessible to current user */
  actionPages: Array<PrivateActionPage>;
  /** List of partnerships and requests to join partnership */
  partnerships: Maybe<Array<Partnership>>;
  /** MTT configuration */
  mtt: Maybe<CampaignMtt>;
};


export type PrivateCampaignActionsArgs = {
  actionType: Scalars['String'];
  limit: Scalars['Int'];
};

export type PrivateOrg = Org & {
  /** Organisation short name */
  name: Scalars['String'];
  /** Organisation title (human readable name) */
  title: Scalars['String'];
  /** config */
  config: Scalars['Json'];
  /** Organization id */
  id: Scalars['Int'];
  /** Personal data settings for this org */
  personalData: PersonalData;
  /** Encryption keys */
  keys: Array<Key>;
  /** Get encryption key */
  key: Key;
  /** Services of this org */
  services: Array<Maybe<Service>>;
  /** Users of this org */
  users: Array<Maybe<OrgUser>>;
  /** Action processing settings for this org */
  processing: Processing;
  /** List campaigns this org is leader or partner of */
  campaigns: Array<Campaign>;
  /** List action pages this org has */
  actionPages: Array<ActionPage>;
  /** Get one page belonging to this org */
  actionPage: ActionPage;
  /** DEPRECATED: use campaign() in API root. Get campaign this org is leader or partner of by id */
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
  id: Scalars['Int'];
};

export type PrivateTarget = Target & {
  id: Scalars['String'];
  /** Name of target */
  name: Scalars['String'];
  /** unique external_id of target, used to upsert target */
  externalId: Scalars['String'];
  /** Locale of this target (in which language do they read emails?) */
  locale: Maybe<Scalars['String']>;
  /** Area of the target */
  area: Maybe<Scalars['String']>;
  /** Custom fields, stringified json */
  fields: Maybe<Scalars['Json']>;
  /** Email list of this target */
  emails: Array<Maybe<TargetEmail>>;
};

export type Processing = {
  /** Envelope FROM email when sending emails */
  emailFrom: Maybe<Scalars['String']>;
  /** Use a particular owned service type for sending emails */
  emailBackend: Maybe<ServiceName>;
  /** Is the supporter required to double opt in their action (and associated personal data)? */
  supporterConfirm: Scalars['Boolean'];
  /** The email template name that will be used to send the action DOI request */
  supporterConfirmTemplate: Maybe<Scalars['String']>;
  /** Only send thank you emails to opt-ins */
  doiThankYou: Scalars['Boolean'];
  /** Should proca put action in a custom queue, so an external service can do this? */
  customSupporterConfirm: Scalars['Boolean'];
  /** Should proca put action in a custom queue, so an external service can do this? */
  customActionConfirm: Scalars['Boolean'];
  /** Should proca put action in custom delivery queue, so an external service can sync it? */
  customActionDeliver: Scalars['Boolean'];
  /** Should proca put events in custom delivery queue, so an external service can sync it? */
  customEventDeliver: Scalars['Boolean'];
  /** Use a particular owned service type for sending events */
  eventBackend: Maybe<ServiceName>;
  /** Use a particular owned service type for sending actions */
  pushBackend: Maybe<ServiceName>;
  /** Use a particular owned service type for uploading files */
  storageBackend: Maybe<ServiceName>;
  /** Use a particular owned service type for looking up supporters in CRM */
  detailBackend: Maybe<ServiceName>;
  /** Email templates. (warn: contant is not available to fetch) */
  emailTemplates: Maybe<Array<Scalars['String']>>;
};

export type PublicActionPage = ActionPage & {
  /** Id */
  id: Scalars['Int'];
  /** Locale for the widget, in i18n format */
  locale: Scalars['String'];
  /** Name where the widget is hosted */
  name: Scalars['String'];
  /** Thank you email templated of this Action Page */
  thankYouTemplate: Maybe<Scalars['String']>;
  /** A reference to thank you email template of this ActionPage */
  thankYouTemplateRef: Maybe<Scalars['String']>;
  /** Is live? */
  live: Scalars['Boolean'];
  /**
   * List of steps in journey
   * @deprecated moved under config
   */
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
  /** Custom field keys which are public */
  fieldKeys: Maybe<Array<Scalars['String']>>;
  /** List of actions custom fields */
  list: Maybe<Array<Maybe<ActionCustomFields>>>;
};

export type PublicCampaign = Campaign & {
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
  /** Statistics */
  stats: CampaignStats;
  /** Lead org */
  org: Org;
  /**
   * Fetch public actions. Can be used to display recent comments for example.
   *
   * To allow-list action fields to be public, `campaign.public_actions` must be set to a list of strings in form
   * action_type:custom_field_name, eg: `["signature:comment"]`. XXX this cannot be set in API, you need to set in backend.
   */
  actions: PublicActionsResult;
  /** List MTT targets of this campaign */
  targets: Maybe<Array<Maybe<Target>>>;
};


export type PublicCampaignActionsArgs = {
  actionType: Scalars['String'];
  limit: Scalars['Int'];
};

export type PublicOrg = Org & {
  /** Organisation short name */
  name: Scalars['String'];
  /** Organisation title (human readable name) */
  title: Scalars['String'];
  /** config */
  config: Scalars['Json'];
};

export type PublicTarget = Target & {
  id: Scalars['String'];
  /** Name of target */
  name: Scalars['String'];
  /** unique external_id of target, used to upsert target */
  externalId: Scalars['String'];
  /** Locale of this target (in which language do they read emails?) */
  locale: Maybe<Scalars['String']>;
  /** Area of the target */
  area: Maybe<Scalars['String']>;
  /** Custom fields, stringified json */
  fields: Maybe<Scalars['Json']>;
};

export enum Queue {
  /** Queue of thank you email sender worker */
  EmailSupporter = 'EMAIL_SUPPORTER',
  /** a custom queue of action that needs DOI */
  CustomSupporterConfirm = 'CUSTOM_SUPPORTER_CONFIRM',
  /** a custom queue of action that needs moderation */
  CustomActionConfirm = 'CUSTOM_ACTION_CONFIRM',
  /** a custom queue of actions to sync to CRM */
  CustomActionDeliver = 'CUSTOM_ACTION_DELIVER',
  /** Queue of SQS sync worker */
  Sqs = 'SQS',
  /** Queue of webhook sync worker */
  Webhook = 'WEBHOOK'
}

export type RequeueResult = {
  /** Count of actions selected for requeueing */
  count: Scalars['Int'];
  /** Count of actions that could not be requeued */
  failed: Scalars['Int'];
};

export type RootMutationType = {
  /**
   * Upserts a campaign.
   *
   * Creates or appends campaign and it's action pages. In case of append, it
   * will change the campaign with the matching name, and action pages with
   * matching names. It will create new action pages if you pass new names. No
   * Action Pages will be removed (principle of not removing signature data).
   */
  upsertCampaign: Campaign;
  /** Updates an existing campaign. */
  updateCampaign: Campaign;
  /** Add a new campaign */
  addCampaign: Campaign;
  /**
   * Delete a campaign.
   * Deletion will be blocked if there are action pages with personal data (we never remove personal data unless via GDPR).
   */
  deleteCampaign: Status;
  /** Update an Action Page */
  updateActionPage: ActionPage;
  /**
   * Adds a new Action Page based on another Action Page. Intended to be used to
   * create a partner action page based off lead's one. Copies: campaign, locale, config, delivery flag
   */
  copyActionPage: ActionPage;
  /**
   * Adds a new Action Page based on latest Action Page from campaign. Intended to be used to
   * create a partner action page based off lead's one. Copies: campaign, locale, config, delivery flag
   */
  copyCampaignActionPage: ActionPage;
  addActionPage: ActionPage;
  /** Sends a request to lead to set the page to live=true */
  launchActionPage: LaunchActionPageResult;
  /** Delete an action page */
  deleteActionPage: Status;
  /** Adds an action referencing contact data via contactRef */
  addAction: ContactReference;
  /** Adds an action with contact data */
  addActionContact: ContactReference;
  /** Link actions with refs to contact with contact reference */
  linkActions: ContactReference;
  /** Requeue actions into one of processing destinations */
  requeueActions: RequeueResult;
  /** Add user to org by email */
  addOrgUser: ChangeUserStatus;
  /** Invite an user to org by email (can be not yet user!) */
  inviteOrgUser: Confirm;
  updateOrgUser: ChangeUserStatus;
  deleteOrgUser: Maybe<DeleteUserResult>;
  /** Update (current) user details */
  updateUser: User;
  resetApiToken: Scalars['String'];
  /** Add an org. Calling user  will become it's owner. */
  addOrg: Org;
  /** Delete an org */
  deleteOrg: Status;
  /** Update an org */
  updateOrg: PrivateOrg;
  /** Update org processing settings */
  updateOrgProcessing: PrivateOrg;
  /** Try becoming a staffer of the org */
  joinOrg: JoinOrgResult;
  /** Generate a new encryption key in org */
  generateKey: KeyWithPrivate;
  /** Add a key to encryption keys */
  addKey: Key;
  /** A separate key activate operation, because you also need to add the key to receiving system before it is used */
  activateKey: ActivateKeyResult;
  /**
   * Upsert an email tempalte to be used for sending various emails.
   * It belongs to org and is identified by (name, locale), so you can have multiple "thank_you" templates for different languages.
   */
  upsertTemplate: Maybe<Status>;
  /** Insert or update a service for an org, using id to to update a particular one */
  upsertService: Service;
  /** Stripe API - add a stripe payment intent, when donating to the action page specified by id */
  addStripePaymentIntent: Scalars['Json'];
  /** Stripe API - add a stripe subscription, when donating to the action page specified by id */
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
  /** Accept a confirm by user */
  acceptUserConfirm: ConfirmResult;
  /** Reject a confirm by user */
  rejectUserConfirm: ConfirmResult;
  /**
   * Upsert multiple targets at once.
   * external_id is used to decide if new target record is added, or existing one is updated.
   */
  upsertTargets: Array<Maybe<PrivateTarget>>;
};


export type RootMutationTypeUpsertCampaignArgs = {
  orgName: Scalars['String'];
  input: CampaignInput;
};


export type RootMutationTypeUpdateCampaignArgs = {
  id?: Maybe<Scalars['Int']>;
  name?: Maybe<Scalars['String']>;
  input: CampaignInput;
};


export type RootMutationTypeAddCampaignArgs = {
  orgName: Scalars['String'];
  input: CampaignInput;
};


export type RootMutationTypeDeleteCampaignArgs = {
  id?: Maybe<Scalars['Int']>;
  name?: Maybe<Scalars['String']>;
  externalId?: Maybe<Scalars['Int']>;
};


export type RootMutationTypeUpdateActionPageArgs = {
  id?: Maybe<Scalars['Int']>;
  name?: Maybe<Scalars['String']>;
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


export type RootMutationTypeAddActionPageArgs = {
  orgName: Scalars['String'];
  campaignName: Scalars['String'];
  input: ActionPageInput;
};


export type RootMutationTypeLaunchActionPageArgs = {
  name: Scalars['String'];
  message?: Maybe<Scalars['String']>;
};


export type RootMutationTypeDeleteActionPageArgs = {
  id?: Maybe<Scalars['Int']>;
  name?: Maybe<Scalars['String']>;
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


export type RootMutationTypeRequeueActionsArgs = {
  orgName: Scalars['String'];
  ids?: Maybe<Array<Scalars['Int']>>;
  queue: Queue;
};


export type RootMutationTypeAddOrgUserArgs = {
  orgName: Scalars['String'];
  input: OrgUserInput;
};


export type RootMutationTypeInviteOrgUserArgs = {
  orgName: Scalars['String'];
  input: OrgUserInput;
  message?: Maybe<Scalars['String']>;
};


export type RootMutationTypeUpdateOrgUserArgs = {
  orgName: Scalars['String'];
  input: OrgUserInput;
};


export type RootMutationTypeDeleteOrgUserArgs = {
  orgName: Scalars['String'];
  email: Scalars['String'];
};


export type RootMutationTypeUpdateUserArgs = {
  input: UserDetailsInput;
  id?: Maybe<Scalars['Int']>;
  email?: Maybe<Scalars['String']>;
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


export type RootMutationTypeUpdateOrgProcessingArgs = {
  name: Scalars['String'];
  emailBackend?: Maybe<ServiceName>;
  emailFrom?: Maybe<Scalars['String']>;
  supporterConfirm?: Maybe<Scalars['Boolean']>;
  supporterConfirmTemplate?: Maybe<Scalars['String']>;
  doiThankYou?: Maybe<Scalars['Boolean']>;
  customSupporterConfirm?: Maybe<Scalars['Boolean']>;
  customActionConfirm?: Maybe<Scalars['Boolean']>;
  customActionDeliver?: Maybe<Scalars['Boolean']>;
  customEventDeliver?: Maybe<Scalars['Boolean']>;
  eventBackend?: Maybe<ServiceName>;
  storageBackend?: Maybe<ServiceName>;
  detailBackend?: Maybe<ServiceName>;
  pushBackend?: Maybe<ServiceName>;
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


export type RootMutationTypeUpsertTemplateArgs = {
  orgName: Scalars['String'];
  input: EmailTemplateInput;
};


export type RootMutationTypeUpsertServiceArgs = {
  orgName: Scalars['String'];
  id?: Maybe<Scalars['Int']>;
  input: ServiceInput;
};


export type RootMutationTypeAddStripePaymentIntentArgs = {
  actionPageId: Scalars['Int'];
  input: StripePaymentIntentInput;
  contactRef?: Maybe<Scalars['ID']>;
  testing?: Maybe<Scalars['Boolean']>;
};


export type RootMutationTypeAddStripeSubscriptionArgs = {
  actionPageId: Scalars['Int'];
  input: StripeSubscriptionInput;
  contactRef?: Maybe<Scalars['ID']>;
  testing?: Maybe<Scalars['Boolean']>;
};


export type RootMutationTypeAddStripeObjectArgs = {
  actionPageId: Scalars['Int'];
  paymentIntent?: Maybe<Scalars['Json']>;
  subscription?: Maybe<Scalars['Json']>;
  customer?: Maybe<Scalars['Json']>;
  price?: Maybe<Scalars['Json']>;
  testing?: Maybe<Scalars['Boolean']>;
};


export type RootMutationTypeAcceptOrgConfirmArgs = {
  name: Scalars['String'];
  confirm: ConfirmInput;
};


export type RootMutationTypeRejectOrgConfirmArgs = {
  name: Scalars['String'];
  confirm: ConfirmInput;
};


export type RootMutationTypeAcceptUserConfirmArgs = {
  confirm: ConfirmInput;
};


export type RootMutationTypeRejectUserConfirmArgs = {
  confirm: ConfirmInput;
};


export type RootMutationTypeUpsertTargetsArgs = {
  targets: Array<TargetInput>;
  campaignId: Scalars['Int'];
  replace?: Maybe<Scalars['Boolean']>;
};

export type RootQueryType = {
  /** Returns a public list of campaigns, filtered by title. Can be used to implement a campaign search box on a website. */
  campaigns: Array<Campaign>;
  /**
   * Get one campaign. If you have access to the campaign, as lead or
   * partner, you will get a private view of the campaign, otherwise, a public
   * view.
   */
  campaign: Maybe<Campaign>;
  /**
   * Get action page.
   * Depending on your access (page owner, lead, instance admin),
   * you will get private or public view of the page.
   */
  actionPage: ActionPage;
  /** Export actions collected by org, optionally filtered by campaign */
  exportActions: Array<Maybe<Action>>;
  /** Get the current user, as determined by Authorization header */
  currentUser: User;
  /** Select users from this instnace. Requires a manage users admin permission. */
  users: Array<User>;
  /** Organization api (authenticated) */
  org: PrivateOrg;
};


export type RootQueryTypeCampaignsArgs = {
  title?: Maybe<Scalars['String']>;
  name?: Maybe<Scalars['String']>;
  id?: Maybe<Scalars['Int']>;
};


export type RootQueryTypeCampaignArgs = {
  id?: Maybe<Scalars['Int']>;
  name?: Maybe<Scalars['String']>;
};


export type RootQueryTypeActionPageArgs = {
  id?: Maybe<Scalars['Int']>;
  name?: Maybe<Scalars['String']>;
  url?: Maybe<Scalars['String']>;
};


export type RootQueryTypeExportActionsArgs = {
  orgName: Scalars['String'];
  campaignName?: Maybe<Scalars['String']>;
  campaignId?: Maybe<Scalars['Int']>;
  start?: Maybe<Scalars['Int']>;
  after?: Maybe<Scalars['DateTime']>;
  limit?: Maybe<Scalars['Int']>;
  onlyOptIn?: Maybe<Scalars['Boolean']>;
  onlyDoubleOptIn?: Maybe<Scalars['Boolean']>;
  includeTesting?: Maybe<Scalars['Boolean']>;
};


export type RootQueryTypeUsersArgs = {
  select?: Maybe<SelectUser>;
};


export type RootQueryTypeOrgArgs = {
  name: Scalars['String'];
};

export type RootSubscriptionType = {
  actionPageUpserted: ActionPage;
};


export type RootSubscriptionTypeActionPageUpsertedArgs = {
  orgName?: Maybe<Scalars['String']>;
};

export type SelectActionPage = {
  /** Filter by campaign Id */
  campaignId?: Maybe<Scalars['Int']>;
};

export type SelectCampaign = {
  titleLike?: Maybe<Scalars['String']>;
  orgName?: Maybe<Scalars['String']>;
};

export type SelectKey = {
  /** Key id */
  id?: Maybe<Scalars['Int']>;
  /** Only active */
  active?: Maybe<Scalars['Boolean']>;
  /** Key having this public part */
  public?: Maybe<Scalars['String']>;
};

export type SelectService = {
  name?: Maybe<ServiceName>;
};

/** Criteria to filter users */
export type SelectUser = {
  id?: Maybe<Scalars['Int']>;
  /** Use % as wildcard */
  email?: Maybe<Scalars['String']>;
  /** Exact org name */
  orgName?: Maybe<Scalars['String']>;
};

export type Service = {
  /** Id */
  id: Scalars['Int'];
  /** Service name (type) */
  name: ServiceName;
  /** Hostname of service, but can be used as any "container" of the service. For AWS, contains a region. */
  host: Maybe<Scalars['String']>;
  /** User, Account id, client id, whatever your API has */
  user: Maybe<Scalars['String']>;
  /** A sub-selector of a resource. Can be url path, but can be something like AWS bucket name */
  path: Maybe<Scalars['String']>;
};

export type ServiceInput = {
  /** Service name (type) */
  name: ServiceName;
  /** Hostname of service, but can be used as any "container" of the service. For AWS, contains a region. */
  host?: Maybe<Scalars['String']>;
  /** User, Account id, client id, whatever your API has */
  user?: Maybe<Scalars['String']>;
  /** Password, key, secret or whatever your API has as secret credential */
  password?: Maybe<Scalars['String']>;
  /** A sub-selector of a resource. Can be url path, but can be something like AWS bucket name */
  path?: Maybe<Scalars['String']>;
};

export enum ServiceName {
  /** AWS SES to send emails */
  Ses = 'SES',
  /** AWS SQS to process messages */
  Sqs = 'SQS',
  /** Mailjet to send emails */
  Mailjet = 'MAILJET',
  /** SMTP to send emails */
  Smtp = 'SMTP',
  /** Wordpress HTTP API */
  Wordpress = 'WORDPRESS',
  /** Stripe to process donations */
  Stripe = 'STRIPE',
  /** Stripe test account to test donations */
  TestStripe = 'TEST_STRIPE',
  /** HTTP POST webhook */
  Webhook = 'WEBHOOK',
  /** Use a service that instance org is using */
  System = 'SYSTEM',
  /** Supabase to store files */
  Supabase = 'SUPABASE'
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
  /** Amount of payment */
  amount: Scalars['Int'];
  /** Currency ofo payment */
  currency: Scalars['String'];
  /** Stripe payment method type */
  paymentMethodTypes?: Maybe<Array<Scalars['String']>>;
};

export type StripeSubscriptionInput = {
  /** Amount of payment */
  amount: Scalars['Int'];
  /** Currency ofo payment */
  currency: Scalars['String'];
  /** how often is recurrent payment made? */
  frequencyUnit: DonationFrequencyUnit;
};

export type Target = {
  id: Scalars['String'];
  /** Name of target */
  name: Scalars['String'];
  /** unique external_id of target, used to upsert target */
  externalId: Scalars['String'];
  /** Locale of this target (in which language do they read emails?) */
  locale: Maybe<Scalars['String']>;
  /** Area of the target */
  area: Maybe<Scalars['String']>;
  /** Custom fields, stringified json */
  fields: Maybe<Scalars['Json']>;
};

export type TargetEmail = {
  /** Email of target */
  email: Scalars['String'];
  /** The status of email (normal or bouncing etc) */
  emailStatus: EmailStatus;
  /** An error received when bouncing email was reported */
  error: Maybe<Scalars['String']>;
};

export type TargetEmailInput = {
  /** Email of target */
  email: Scalars['String'];
};

export type TargetInput = {
  /** Name of target */
  name?: Maybe<Scalars['String']>;
  /** unique external_id of target, used to upsert target */
  externalId: Scalars['String'];
  /** Locale of this target (in which language do they read emails?) */
  locale?: Maybe<Scalars['String']>;
  /** Area of the target */
  area?: Maybe<Scalars['String']>;
  /** Custom fields, stringified json */
  fields?: Maybe<Scalars['Json']>;
  /** Email list of this target */
  emails?: Maybe<Array<TargetEmailInput>>;
};

/** Tracking codes (UTM params) */
export type Tracking = {
  source: Scalars['String'];
  medium: Scalars['String'];
  campaign: Scalars['String'];
  content: Scalars['String'];
};

/** Tracking codes, utm medium/campaign/source default to 'unknown', content to empty string */
export type TrackingInput = {
  source?: Maybe<Scalars['String']>;
  medium?: Maybe<Scalars['String']>;
  campaign?: Maybe<Scalars['String']>;
  content?: Maybe<Scalars['String']>;
  /** Action page location. Url from which action is added. Must contain schema, domain, (port), pathname */
  location?: Maybe<Scalars['String']>;
};

export type User = {
  /** Id of user */
  id: Scalars['Int'];
  /** Email of user */
  email: Scalars['String'];
  /** Phone */
  phone: Maybe<Scalars['String']>;
  /** Url to profile picture */
  pictureUrl: Maybe<Scalars['String']>;
  /** Job title */
  jobTitle: Maybe<Scalars['String']>;
  /** Users API token (to check expiry) */
  apiToken: Maybe<ApiToken>;
  /** Is user an admin? */
  isAdmin: Scalars['Boolean'];
  /** user's roles in orgs */
  roles: Array<UserRole>;
};

export type UserDetailsInput = {
  /** Users profile pic url */
  pictureUrl?: Maybe<Scalars['String']>;
  /** Job title */
  jobTitle?: Maybe<Scalars['String']>;
  /** Phone */
  phone?: Maybe<Scalars['String']>;
};

export type UserRole = {
  /** Org this role is in */
  org: Org;
  /** Role name */
  role: Scalars['String'];
};
