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
  /** action type */
  actionType: Scalars['String'];
  /** count of actions of action type */
  count: Scalars['Int'];
};

export type ActivateKeyResult = {
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
  status: Status;
};

export type Confirm = {
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
  status: Status;
  actionPage: Maybe<ActionPage>;
  campaign: Maybe<Campaign>;
  org: Maybe<Org>;
};

/** GDPR consent data for this org */
export type Consent = {
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
  transient?: Maybe<Scalars['Boolean']>;
};




export type DeleteUserResult = {
  status: Status;
};

export type Donation = {
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
  status: Status;
  org: Org;
};


/** Encryption or sign key with integer id (database) */
export type Key = {
  id: Scalars['Int'];
  public: Scalars['String'];
  name: Scalars['String'];
  active: Scalars['Boolean'];
  expired: Scalars['Boolean'];
  /** When the key was expired, in UTC */
  expiredAt: Maybe<Scalars['NaiveDateTime']>;
};

export type KeyIds = {
  id: Scalars['Int'];
  public: Scalars['String'];
};

export type KeyWithPrivate = {
  id: Scalars['Int'];
  public: Scalars['String'];
  private: Scalars['String'];
  name: Scalars['String'];
  active: Scalars['Boolean'];
  expired: Scalars['Boolean'];
  /** When the key was expired, in UTC */
  expiredAt: Maybe<Scalars['DateTime']>;
};

export type LaunchActionPageResult = {
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
  email: Scalars['String'];
  role: Scalars['String'];
  createdAt: Scalars['NaiveDateTime'];
  joinedAt: Scalars['NaiveDateTime'];
  lastSigninAt: Maybe<Scalars['NaiveDateTime']>;
};

export type Partnership = {
  org: Org;
  actionPages: Array<ActionPage>;
  launchRequests: Array<Confirm>;
};

export type PersonalData = {
  /** Schema for contact personal information */
  contactSchema: ContactSchema;
  /** Email opt in enabled */
  emailOptIn: Scalars['Boolean'];
  /** Email opt in template name */
  emailOptInTemplate: Maybe<Scalars['String']>;
};

export type PrivateActionPage = ActionPage & {
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
  fieldKeys: Maybe<Array<Scalars['String']>>;
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
  /** Organisation short name */
  name: Scalars['String'];
  /** Organisation title (human readable name) */
  title: Scalars['String'];
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
  id: Scalars['Int'];
  email: Scalars['String'];
  roles: Array<UserRole>;
};

export type UserInput = {
  email: Scalars['String'];
  role: Scalars['String'];
};

export type UserRole = {
  org: Org;
  role: Scalars['String'];
};
