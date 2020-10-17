export type Maybe<T> = T | null;
export type Exact<T extends { [key: string]: unknown }> = { [K in keyof T]: T[K] };
/** All built-in and custom scalars, mapped to their actual values */
export type Scalars = {
  ID: string;
  String: string;
  Boolean: boolean;
  Int: number;
  Float: number;
  Datetime: any;
};

/** Tracking codes */
export type Tracking = {
  __typename?: 'Tracking';
  source: Scalars['String'];
  medium: Scalars['String'];
  campaign: Scalars['String'];
  content: Scalars['String'];
};

export type Signature = {
  __typename?: 'Signature';
  /** Signature id */
  id?: Maybe<Scalars['Int']>;
  /** DateTime of signature (UTC) */
  created?: Maybe<Scalars['Datetime']>;
  /** Encryption nonce in Base64url */
  nonce?: Maybe<Scalars['String']>;
  /** Encrypted contact data in Base64url */
  contact?: Maybe<Scalars['String']>;
  /** Campaign id */
  campaignId?: Maybe<Scalars['Int']>;
  /** Action page id */
  actionPageId?: Maybe<Scalars['Int']>;
  /** Opt in given when adding sig */
  optIn?: Maybe<Scalars['Boolean']>;
};

export type SimpleActionPage = {
  __typename?: 'SimpleActionPage';
  id: Scalars['Int'];
  name: Scalars['String'];
  locale: Scalars['String'];
};

export type SignatureList = {
  __typename?: 'SignatureList';
  /** Public key of sender (proca app), in Base64url encoding (RFC 4648 5.) */
  publicKey?: Maybe<Scalars['String']>;
  /** List of returned signatures */
  list?: Maybe<Array<Maybe<Signature>>>;
};

/** GDPR consent data structure */
export type ConsentInput = {
  /** Has contact consented to receiving communication from widget owner? */
  optIn: Scalars['Boolean'];
  /** Opt in to the campaign leader */
  leadOptIn?: Maybe<Scalars['Boolean']>;
};

/** GDPR consent data for this org */
export type Consent = {
  __typename?: 'Consent';
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
  __typename?: 'ActionTypeCount';
  /** action type */
  actionType: Scalars['String'];
  /** count of actions of action type */
  count: Scalars['Int'];
};

export enum ContactSchema {
  PopularInitiative = 'POPULAR_INITIATIVE',
  Basic = 'BASIC'
}

export type RootSubscriptionType = {
  __typename?: 'RootSubscriptionType';
  actionPageUpserted?: Maybe<PublicActionPage>;
};


export type RootSubscriptionTypeActionPageUpsertedArgs = {
  orgName?: Maybe<Scalars['String']>;
};

export type ActionCampaign = {
  __typename?: 'ActionCampaign';
  name: Scalars['String'];
  externalId: Scalars['Int'];
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

/** Custom field added to action. For signature it can be contact, for mail it can be subject and body */
export type ActionInput = {
  /** Action Type */
  actionType: Scalars['String'];
  /** Other fields that accompany the signature */
  fields?: Maybe<Array<CustomFieldInput>>;
};

/** Result of actions query */
export type PublicActionsResult = {
  __typename?: 'PublicActionsResult';
  fieldKeys?: Maybe<Array<Scalars['String']>>;
  list?: Maybe<Array<Maybe<ActionCustomFields>>>;
};

/** Campaign statistics */
export type CampaignStats = {
  __typename?: 'CampaignStats';
  /** Signature count (naive at the moment) */
  supporterCount?: Maybe<Scalars['Int']>;
  /** Action counts for selected action types */
  actionCount?: Maybe<Array<ActionTypeCount>>;
};

export type ActionCustomFields = {
  __typename?: 'ActionCustomFields';
  actionType: Scalars['String'];
  insertedAt: Scalars['Datetime'];
  fields?: Maybe<Array<CustomField>>;
};

export type Action = {
  __typename?: 'Action';
  actionId: Scalars['Int'];
  createdAt: Scalars['Datetime'];
  actionType: Scalars['String'];
  contact: Contact;
  fields: Array<CustomField>;
  tracking?: Maybe<Tracking>;
  campaign: ActionCampaign;
  actionPage: SimpleActionPage;
  privacy: Consent;
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
  upsertCampaign?: Maybe<Campaign>;
  /** Deprecated, use upsert_campaign. */
  declareCampaign?: Maybe<Campaign>;
  /** Update an Action Page */
  updateActionPage?: Maybe<ActionPage>;
  /** Adds an action referencing contact data via contactRef */
  addAction?: Maybe<ContactReference>;
  /** Adds an action with contact data */
  addActionContact?: Maybe<ContactReference>;
  /** Link actions with refs to contact with contact reference */
  linkActions?: Maybe<ContactReference>;
  updateOrg?: Maybe<Org>;
};


export type RootMutationTypeUpsertCampaignArgs = {
  actionPages: Array<Maybe<ActionPageInput>>;
  title?: Maybe<Scalars['String']>;
  externalId?: Maybe<Scalars['Int']>;
  name: Scalars['String'];
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
  config?: Maybe<Scalars['String']>;
  journey?: Maybe<Array<Scalars['String']>>;
  extraSupporters?: Maybe<Scalars['Int']>;
  thankYouTemplateRef?: Maybe<Scalars['String']>;
  locale?: Maybe<Scalars['String']>;
  name?: Maybe<Scalars['String']>;
  id: Scalars['Int'];
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


export type RootMutationTypeUpdateOrgArgs = {
  emailOptInTemplate?: Maybe<Scalars['String']>;
  emailOptIn?: Maybe<Scalars['Boolean']>;
  contactSchema?: Maybe<ContactSchema>;
  title?: Maybe<Scalars['String']>;
  name: Scalars['String'];
};

export type RootQueryType = {
  __typename?: 'RootQueryType';
  /** Get a list of campains */
  campaigns?: Maybe<Array<Maybe<Campaign>>>;
  /** Get action page */
  actionPage?: Maybe<PublicActionPage>;
  exportActions?: Maybe<Array<Maybe<Action>>>;
  /** Organization api (authenticated) */
  org?: Maybe<Org>;
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
  limit?: Maybe<Scalars['Int']>;
  after?: Maybe<Scalars['Datetime']>;
  start?: Maybe<Scalars['Int']>;
  campaignId?: Maybe<Scalars['Int']>;
  campaignName?: Maybe<Scalars['String']>;
  orgName: Scalars['String'];
};


export type RootQueryTypeOrgArgs = {
  name: Scalars['String'];
};

export type PublicOrg = {
  __typename?: 'PublicOrg';
  /** Organisation short name */
  name?: Maybe<Scalars['String']>;
  /** Organisation title (human readable name) */
  title?: Maybe<Scalars['String']>;
};

export type ActionPage = {
  __typename?: 'ActionPage';
  id?: Maybe<Scalars['Int']>;
  /** Locale for the widget, in i18n format */
  locale?: Maybe<Scalars['String']>;
  /** Name where the widget is hosted */
  name?: Maybe<Scalars['String']>;
  /** Reference to thank you email templated of this Action Page */
  thankYouTemplateRef?: Maybe<Scalars['String']>;
  /** List of steps in journey */
  journey?: Maybe<Array<Scalars['String']>>;
  /** Config JSON of this action page */
  config?: Maybe<Scalars['String']>;
  /** Extra supporters (added to supporters count) */
  extraSupporters?: Maybe<Scalars['Int']>;
  /** Campaign this widget belongs to */
  campaign?: Maybe<Campaign>;
  org?: Maybe<PublicOrg>;
};

export type PublicActionPage = {
  __typename?: 'PublicActionPage';
  id?: Maybe<Scalars['Int']>;
  /** Locale for the widget, in i18n format */
  locale?: Maybe<Scalars['String']>;
  /** Name where the widget is hosted */
  name?: Maybe<Scalars['String']>;
  /** Reference to thank you email templated of this Action Page */
  thankYouTemplateRef?: Maybe<Scalars['String']>;
  /** List of steps in journey */
  journey?: Maybe<Array<Scalars['String']>>;
  /** Config JSON of this action page */
  config?: Maybe<Scalars['String']>;
  /** Campaign this widget belongs to */
  campaign?: Maybe<Campaign>;
  org?: Maybe<PublicOrg>;
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
};

/** ActionPage declaration */
export type ActionPageInput = {
  /** Action Page id */
  id?: Maybe<Scalars['Int']>;
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
  config?: Maybe<Scalars['String']>;
};

export type PersonalData = {
  __typename?: 'PersonalData';
  /** Schema for contact personal information */
  contactSchema: ContactSchema;
  /** Email opt in enabled */
  emailOptIn: Scalars['Boolean'];
  /** Email opt in template name */
  emailOptInTemplate?: Maybe<Scalars['String']>;
};

export type Campaign = {
  __typename?: 'Campaign';
  id?: Maybe<Scalars['Int']>;
  /** Internal name of the campaign */
  name?: Maybe<Scalars['String']>;
  /** External ID (if set) */
  externalId?: Maybe<Scalars['Int']>;
  /** Full, official name of the campaign */
  title?: Maybe<Scalars['String']>;
  /** Campaign statistics */
  stats?: Maybe<CampaignStats>;
  /** Fetch public actions */
  actions?: Maybe<PublicActionsResult>;
  org?: Maybe<PublicOrg>;
};


export type CampaignActionsArgs = {
  actionType: Scalars['String'];
};

/** Encryption or sign key with integer id (database) */
export type Key = {
  __typename?: 'Key';
  id: Scalars['Int'];
  public: Scalars['String'];
  name?: Maybe<Scalars['String']>;
  expiredAt?: Maybe<Scalars['Datetime']>;
};

export type Org = {
  __typename?: 'Org';
  /** Organization id */
  id?: Maybe<Scalars['Int']>;
  /** Organisation short name */
  name?: Maybe<Scalars['String']>;
  /** Organisation title (human readable name) */
  title?: Maybe<Scalars['String']>;
  personalData: PersonalData;
  keys: Array<Key>;
  /** List campaigns this org is leader or partner of */
  campaigns?: Maybe<Array<Maybe<Campaign>>>;
  /** List action pages this org has */
  actionPages?: Maybe<Array<Maybe<ActionPage>>>;
  actionPage?: Maybe<ActionPage>;
  /** Get campaign this org is leader or partner of by id */
  campaign?: Maybe<Campaign>;
  /**
   * Get signatures this org has collected.
   * Provide campaign_id to only get signatures for a campaign
   * XXX DEPRECATE AND REMOVE
   */
  signatures?: Maybe<SignatureList>;
};


export type OrgActionPageArgs = {
  name?: Maybe<Scalars['String']>;
  id?: Maybe<Scalars['Int']>;
};


export type OrgCampaignArgs = {
  id?: Maybe<Scalars['Int']>;
};


export type OrgSignaturesArgs = {
  limit?: Maybe<Scalars['Int']>;
  after?: Maybe<Scalars['Datetime']>;
  start?: Maybe<Scalars['Int']>;
  campaignId?: Maybe<Scalars['Int']>;
};

export type ContactReference = {
  __typename?: 'ContactReference';
  /** Contact's reference */
  contactRef?: Maybe<Scalars['String']>;
  /** Contacts first name */
  firstName?: Maybe<Scalars['String']>;
};

export type Contact = {
  __typename?: 'Contact';
  contactRef: Scalars['String'];
  payload?: Maybe<Scalars['String']>;
  nonce?: Maybe<Scalars['String']>;
  publicKey?: Maybe<Key>;
  signKey?: Maybe<Key>;
};

/** Custom field with a key and value. Both are strings. */
export type CustomFieldInput = {
  key: Scalars['String'];
  value: Scalars['String'];
  transient?: Maybe<Scalars['Boolean']>;
};

/** Custom field with a key and value. */
export type CustomField = {
  __typename?: 'CustomField';
  key: Scalars['String'];
  value: Scalars['String'];
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
  birthDate?: Maybe<Scalars['String']>;
  /** Contacts address */
  address?: Maybe<AddressInput>;
};
