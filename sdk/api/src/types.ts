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
  DateTime: any;
  Date: any;
  Json: any;
};

/** Tracking codes */
export type Tracking = {
  source: Scalars['String'];
  medium: Scalars['String'];
  campaign: Scalars['String'];
  content: Scalars['String'];
};

export type UserRole = {
  org: Org;
  role: Scalars['String'];
};

export type SelectActionPage = {
  campaignId?: Maybe<Scalars['Int']>;
};


export type KeyWithPrivate = {
  id: Scalars['Int'];
  public: Scalars['String'];
  private: Scalars['String'];
  name: Scalars['String'];
  active: Scalars['Boolean'];
  expired: Scalars['Boolean'];
  expiredAt: Maybe<Scalars['DateTime']>;
};

export type SimpleActionPage = {
  id: Scalars['Int'];
  name: Scalars['String'];
  locale: Scalars['String'];
};

/** GDPR consent data structure */
export type ConsentInput = {
  /** Has contact consented to receiving communication from widget owner? */
  optIn: Scalars['Boolean'];
  /** Opt in to the campaign leader */
  leadOptIn?: Maybe<Scalars['Boolean']>;
};

export type NationalityInput = {
  /** Nationality / issuer of id document */
  country: Scalars['String'];
  /** Document type */
  documentType?: Maybe<Scalars['String']>;
  /** Document serial id/number */
  documentNumber?: Maybe<Scalars['String']>;
};

/** GDPR consent data for this org */
export type Consent = {
  optIn: Scalars['Boolean'];
};

/** Tracking codes */
export type TrackingInput = {
  source: Scalars['String'];
  medium: Scalars['String'];
  campaign: Scalars['String'];
  content?: Maybe<Scalars['String']>;
};

/** Count of actions for particular action type */
export type ActionTypeCount = {
  /** action type */
  actionType: Scalars['String'];
  /** count of actions of action type */
  count: Scalars['Int'];
};

export enum ContactSchema {
  Eci = 'ECI',
  PopularInitiative = 'POPULAR_INITIATIVE',
  Basic = 'BASIC'
}

export type RootSubscriptionType = {
  actionPageUpserted: PublicActionPage;
};


export type RootSubscriptionTypeActionPageUpsertedArgs = {
  orgName?: Maybe<Scalars['String']>;
};

export type ActionCampaign = {
  name: Scalars['String'];
  externalId: Maybe<Scalars['Int']>;
};

/** ActionPage declaration (using the legacy url attribute) */
export type ActionPageInputLegacyUrl = {
  id?: Maybe<Scalars['Int']>;
  url?: Maybe<Scalars['String']>;
  locale?: Maybe<Scalars['String']>;
  thankYouTemplateRef?: Maybe<Scalars['String']>;
  extraSupporters?: Maybe<Scalars['Int']>;
  journey?: Maybe<Array<Scalars['String']>>;
  config?: Maybe<Scalars['String']>;
};

export type SelectKey = {
  id?: Maybe<Scalars['Int']>;
  active?: Maybe<Scalars['Boolean']>;
  public?: Maybe<Scalars['String']>;
};


/** Count of actions for particular action type */
export type AreaCount = {
  /** area */
  area: Scalars['String'];
  /** count of supporters in this area */
  count: Scalars['Int'];
};

/** Custom field added to action. For signature it can be contact, for mail it can be subject and body */
export type ActionInput = {
  /** Action Type */
  actionType: Scalars['String'];
  /** Other fields that accompany the signature */
  fields?: Maybe<Array<CustomFieldInput>>;
};

export type AddKeyInput = {
  name: Scalars['String'];
  public: Scalars['String'];
};

export type GenKeyInput = {
  name: Scalars['String'];
};

/** Result of actions query */
export type PublicActionsResult = {
  fieldKeys: Maybe<Array<Scalars['String']>>;
  list: Maybe<Array<Maybe<ActionCustomFields>>>;
};

export type ActivateKeyResult = {
  status: Status;
};

/** Campaign statistics */
export type CampaignStats = {
  /** Unique action tagers count */
  supporterCount: Scalars['Int'];
  /** Unique action takers by area */
  supporterCountByArea: Array<AreaCount>;
  /** Unique action takers by org */
  suppoterCountByOrg: Array<OrgCount>;
  supporterCountByOthers: Scalars['Int'];
  /** Action counts for selected action types */
  actionCount: Array<ActionTypeCount>;
};


/** Campaign statistics */
export type CampaignStatsSupporterCountByOthersArgs = {
  orgName: Scalars['String'];
};

export type ActionCustomFields = {
  actionId: Scalars['Int'];
  actionType: Scalars['String'];
  insertedAt: Scalars['DateTime'];
  fields: Array<CustomField>;
};

export type Action = {
  actionId: Scalars['Int'];
  createdAt: Scalars['DateTime'];
  actionType: Scalars['String'];
  contact: Contact;
  fields: Array<CustomField>;
  tracking: Maybe<Tracking>;
  campaign: ActionCampaign;
  actionPage: SimpleActionPage;
  privacy: Consent;
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
  /** Deprecated, use upsert_campaign. */
  declareCampaign: Campaign;
  /** Update an Action Page */
  updateActionPage: ActionPage;
  /**
   * Adds a new Action Page based on another Action Page. Intended to be used to
   * create a partner action page based off lead's one. Copies: campaign, locale, journey, config, delivery flag
   */
  copyActionPage: ActionPage;
  /** Adds an action referencing contact data via contactRef */
  addAction: ContactReference;
  /** Adds an action with contact data */
  addActionContact: ContactReference;
  /** Link actions with refs to contact with contact reference */
  linkActions: ContactReference;
  addOrgUser: Maybe<User>;
  deleteOrgUser: Maybe<DeleteUserResult>;
  updateOrgUser: Maybe<User>;
  addOrg: Org;
  deleteOrg: Scalars['Boolean'];
  updateOrg: Org;
  joinOrg: JoinOrgResult;
  generateKey: KeyWithPrivate;
  addKey: Key;
  /** A separate key activate operation, because you also need to add the key to receiving system before it is used */
  activateKey: ActivateKeyResult;
};


export type RootMutationTypeUpsertCampaignArgs = {
  input: CampaignInput;
  orgName: Scalars['String'];
};


export type RootMutationTypeDeclareCampaignArgs = {
  actionPages: Array<Maybe<ActionPageInputLegacyUrl>>;
  title: Scalars['String'];
  externalId?: Maybe<Scalars['Int']>;
  name: Scalars['String'];
  orgName: Scalars['String'];
};


export type RootMutationTypeUpdateActionPageArgs = {
  input: ActionPageInput;
  id: Scalars['Int'];
};


export type RootMutationTypeCopyActionPageArgs = {
  fromName: Scalars['String'];
  name: Scalars['String'];
  orgName: Scalars['String'];
};


export type RootMutationTypeAddActionArgs = {
  tracking?: Maybe<TrackingInput>;
  contactRef: Scalars['ID'];
  action: ActionInput;
  actionPageId: Scalars['Int'];
};


export type RootMutationTypeAddActionContactArgs = {
  contactRef?: Maybe<Scalars['ID']>;
  tracking?: Maybe<TrackingInput>;
  privacy: ConsentInput;
  contact: ContactInput;
  action: ActionInput;
  actionPageId: Scalars['Int'];
};


export type RootMutationTypeLinkActionsArgs = {
  linkRefs?: Maybe<Array<Scalars['String']>>;
  contactRef: Scalars['ID'];
  actionPageId: Scalars['Int'];
};


export type RootMutationTypeAddOrgUserArgs = {
  input: UserInput;
  orgName: Scalars['String'];
};


export type RootMutationTypeDeleteOrgUserArgs = {
  email: Scalars['String'];
  orgName: Scalars['String'];
};


export type RootMutationTypeUpdateOrgUserArgs = {
  input: UserInput;
  orgName: Scalars['String'];
};


export type RootMutationTypeAddOrgArgs = {
  input: OrgInput;
};


export type RootMutationTypeDeleteOrgArgs = {
  name: Scalars['String'];
};


export type RootMutationTypeUpdateOrgArgs = {
  input: OrgInput;
  name: Scalars['String'];
};


export type RootMutationTypeJoinOrgArgs = {
  name: Scalars['String'];
};


export type RootMutationTypeGenerateKeyArgs = {
  input: GenKeyInput;
  orgName: Scalars['String'];
};


export type RootMutationTypeAddKeyArgs = {
  input: AddKeyInput;
  orgName: Scalars['String'];
};


export type RootMutationTypeActivateKeyArgs = {
  id: Scalars['Int'];
  orgName: Scalars['String'];
};

export type RootQueryType = {
  /** Get a list of campains */
  campaigns: Array<Campaign>;
  /** Get action page */
  actionPage: PublicActionPage;
  exportActions: Array<Maybe<Action>>;
  currentUser: User;
  /** Organization api (authenticated) */
  org: Org;
};


export type RootQueryTypeCampaignsArgs = {
  name?: Maybe<Scalars['String']>;
  title?: Maybe<Scalars['String']>;
};


export type RootQueryTypeActionPageArgs = {
  url?: Maybe<Scalars['String']>;
  name?: Maybe<Scalars['String']>;
  id?: Maybe<Scalars['Int']>;
};


export type RootQueryTypeExportActionsArgs = {
  onlyOptIn?: Maybe<Scalars['Boolean']>;
  limit?: Maybe<Scalars['Int']>;
  after?: Maybe<Scalars['DateTime']>;
  start?: Maybe<Scalars['Int']>;
  campaignId?: Maybe<Scalars['Int']>;
  campaignName?: Maybe<Scalars['String']>;
  orgName: Scalars['String'];
};


export type RootQueryTypeOrgArgs = {
  name: Scalars['String'];
};

export type PublicOrg = {
  /** Organisation short name */
  name: Scalars['String'];
  /** Organisation title (human readable name) */
  title: Scalars['String'];
};

export type ActionPage = {
  id: Scalars['Int'];
  /** Locale for the widget, in i18n format */
  locale: Scalars['String'];
  /** Name where the widget is hosted */
  name: Scalars['String'];
  /** Reference to thank you email templated of this Action Page */
  thankYouTemplateRef: Maybe<Scalars['String']>;
  /** List of steps in journey */
  journey: Maybe<Array<Scalars['String']>>;
  /** Config JSON of this action page */
  config: Scalars['Json'];
  /** Extra supporters (added to supporters count) */
  extraSupporters: Scalars['Int'];
  /** Campaign this widget belongs to. Can be null for trashed action pages */
  campaign: Maybe<Campaign>;
  org: Maybe<PublicOrg>;
};

export type PublicActionPage = {
  id: Scalars['Int'];
  /** Locale for the widget, in i18n format */
  locale: Scalars['String'];
  /** Name where the widget is hosted */
  name: Scalars['String'];
  /** Reference to thank you email templated of this Action Page */
  thankYouTemplateRef: Maybe<Scalars['String']>;
  /** List of steps in journey */
  journey: Array<Scalars['String']>;
  /** Config JSON of this action page */
  config: Scalars['Json'];
  /** Campaign this widget belongs to. Can't be null because trashed action pages are not public */
  campaign: Campaign;
  org: PublicOrg;
};

export type DeleteUserResult = {
  status: Status;
};

/** Count of supporters for particular org */
export type OrgCount = {
  /** org */
  org: PublicOrg;
  /** count of supporters registered by org */
  count: Scalars['Int'];
};

/** Campaign input */
export type CampaignInput = {
  /** Campaign unchanging identifier */
  name: Scalars['String'];
  /** Campaign external_id. If provided, it will be used to find campaign. Can be used to rename a campaign */
  externalId?: Maybe<Scalars['Int']>;
  /** Campaign human readable title */
  title?: Maybe<Scalars['String']>;
  /** Custom config as stringified JSON map */
  config?: Maybe<Scalars['Json']>;
  /** Action pages of this campaign */
  actionPages: Array<ActionPageInput>;
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

export type PersonalData = {
  /** Schema for contact personal information */
  contactSchema: ContactSchema;
  /** Email opt in enabled */
  emailOptIn: Scalars['Boolean'];
  /** Email opt in template name */
  emailOptInTemplate: Maybe<Scalars['String']>;
};

export type SelectCampaign = {
  id?: Maybe<Scalars['Int']>;
};

export type Campaign = {
  id: Scalars['Int'];
  /** Internal name of the campaign */
  name: Scalars['String'];
  /** External ID (if set) */
  externalId: Maybe<Scalars['Int']>;
  /** Full, official name of the campaign */
  title: Scalars['String'];
  /** Custom config map */
  config: Scalars['Json'];
  /** Campaign statistics */
  stats: CampaignStats;
  /** Fetch public actions */
  actions: PublicActionsResult;
  org: PublicOrg;
};


export type CampaignActionsArgs = {
  limit: Scalars['Int'];
  actionType: Scalars['String'];
};

/** Encryption or sign key with integer id (database) */
export type Key = {
  id: Scalars['Int'];
  public: Scalars['String'];
  name: Scalars['String'];
  active: Scalars['Boolean'];
  expired: Scalars['Boolean'];
  expiredAt: Maybe<Scalars['DateTime']>;
};

export type Org = {
  /** Organization id */
  id: Scalars['Int'];
  /** Organisation short name */
  name: Scalars['String'];
  /** Organisation title (human readable name) */
  title: Scalars['String'];
  /** config */
  config: Scalars['Json'];
  /** Personal data settings for this org */
  personalData: PersonalData;
  keys: Array<Key>;
  key: Key;
  /** List campaigns this org is leader or partner of */
  campaigns: Array<Campaign>;
  /** List action pages this org has */
  actionPages: Array<ActionPage>;
  /** Action Page */
  actionPage: ActionPage;
  /** Get campaign this org is leader or partner of by id */
  campaign: Campaign;
};


export type OrgKeysArgs = {
  select?: Maybe<SelectKey>;
};


export type OrgKeyArgs = {
  select: SelectKey;
};


export type OrgCampaignsArgs = {
  select?: Maybe<SelectCampaign>;
};


export type OrgActionPagesArgs = {
  select?: Maybe<SelectActionPage>;
};


export type OrgActionPageArgs = {
  name?: Maybe<Scalars['String']>;
  id?: Maybe<Scalars['Int']>;
};


export type OrgCampaignArgs = {
  id?: Maybe<Scalars['Int']>;
};

export type ContactReference = {
  /** Contact's reference */
  contactRef: Scalars['String'];
  /** Contacts first name */
  firstName: Maybe<Scalars['String']>;
};

export type Contact = {
  contactRef: Scalars['String'];
  payload: Scalars['String'];
  nonce: Maybe<Scalars['String']>;
  publicKey: Maybe<KeyIds>;
  signKey: Maybe<KeyIds>;
};

export type JoinOrgResult = {
  status: Status;
};

/** Custom field with a key and value. Both are strings. */
export type CustomFieldInput = {
  key: Scalars['String'];
  value: Scalars['String'];
  transient?: Maybe<Scalars['Boolean']>;
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

/** Custom field with a key and value. */
export type CustomField = {
  key: Scalars['String'];
  value: Scalars['String'];
};

export type UserInput = {
  email: Scalars['String'];
  roles?: Maybe<Array<Scalars['String']>>;
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

export type KeyIds = {
  id: Scalars['Int'];
  public: Scalars['String'];
};

export enum Status {
  /** Operation awaiting confirmation */
  Confirming = 'CONFIRMING',
  /** Operation completed succesfully */
  Success = 'SUCCESS'
}

export type User = {
  id: Scalars['Int'];
  email: Scalars['String'];
  roles: Array<UserRole>;
};
