import { GraphQLClient } from 'graphql-request';
import { print } from 'graphql';
import gql from 'graphql-tag';
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

export type ActionCustomFields = {
  __typename?: 'ActionCustomFields';
  actionType: Scalars['String'];
  fields?: Maybe<Array<CustomField>>;
  insertedAt: Scalars['Datetime'];
};

export type Action = {
  __typename?: 'Action';
  actionType: Scalars['String'];
  fields: Array<CustomField>;
};

export type ActionsExport = {
  __typename?: 'ActionsExport';
  list: Array<Action>;
};

export type ActionPage = {
  __typename?: 'ActionPage';
  /** Campaign this widget belongs to */
  campaign?: Maybe<Campaign>;
  /** Config JSON of this action page */
  config?: Maybe<Scalars['String']>;
  id?: Maybe<Scalars['Int']>;
  /** List of steps in journey */
  journey?: Maybe<Array<Scalars['String']>>;
  /** Locale for the widget, in i18n format */
  locale?: Maybe<Scalars['String']>;
  /** Name where the widget is hosted */
  name?: Maybe<Scalars['String']>;
  org?: Maybe<PublicOrg>;
  /** Reference to thank you email templated of this Action Page */
  thankYouTemplateRef?: Maybe<Scalars['String']>;
};

/** Custom field added to action. For signature it can be contact, for mail it can be subject and body */
export type ActionInput = {
  /** Action Type */
  actionType: Scalars['String'];
  /** Other fields that accompany the signature */
  fields?: Maybe<Array<CustomFieldInput>>;
};

/** GDPR consent data structure */
export type ConsentInput = {
  leadOptIn?: Maybe<Scalars['Boolean']>;
  /** Has contact consented to receiving communication from widget owner? */
  optIn: Scalars['Boolean'];
};

/** Result of actions query */
export type PublicActionsResult = {
  __typename?: 'PublicActionsResult';
  fieldKeys?: Maybe<Array<Scalars['String']>>;
  list?: Maybe<Array<Maybe<ActionCustomFields>>>;
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

export enum ContactSchema {
  Basic = 'BASIC',
  PopularInitiative = 'POPULAR_INITIATIVE'
}

export type Campaign = {
  __typename?: 'Campaign';
  /** Fetch public actions */
  actions?: Maybe<PublicActionsResult>;
  /** External ID (if set) */
  externalId?: Maybe<Scalars['Int']>;
  id?: Maybe<Scalars['Int']>;
  /** Internal name of the campaign */
  name?: Maybe<Scalars['String']>;
  org?: Maybe<PublicOrg>;
  /** Campaign statistics */
  stats?: Maybe<CampaignStats>;
  /** Full, official name of the campaign */
  title?: Maybe<Scalars['String']>;
};


export type CampaignActionsArgs = {
  actionPageId?: Maybe<Scalars['Int']>;
  actionType: Scalars['String'];
  campaignId?: Maybe<Scalars['Int']>;
};

export type PublicOrg = {
  __typename?: 'PublicOrg';
  /** Organisation short name */
  name?: Maybe<Scalars['String']>;
  /** Organisation title (human readable name) */
  title?: Maybe<Scalars['String']>;
};

/** Count of actions for particular action type */
export type ActionTypeCount = {
  __typename?: 'ActionTypeCount';
  /** action type */
  actionType: Scalars['String'];
  /** count of actions of action type */
  count: Scalars['Int'];
};

/** ActionPage declaration */
export type ActionPageInput = {
  /** JSON string containing Action Page config */
  config?: Maybe<Scalars['String']>;
  /** Extra supporter count. If you want to add a number of signatories you have offline or kept in another system, you can specify the number here.  */
  extraSupporters?: Maybe<Scalars['Int']>;
  /** Action Page id */
  id?: Maybe<Scalars['Int']>;
  /** List of steps in the journey */
  journey?: Maybe<Array<Scalars['String']>>;
  /** 2-letter, lowercase, code of ActionPage language */
  locale?: Maybe<Scalars['String']>;
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
  /** A reference to thank you email template of this ActionPage */
  thankYouTemplateRef?: Maybe<Scalars['String']>;
};

/** Contact information */
export type ContactInput = {
  /** Contacts address */
  address?: Maybe<AddressInput>;
  /** Date of birth in format YYYY-MM-DD */
  birthDate?: Maybe<Scalars['String']>;
  /** Email */
  email?: Maybe<Scalars['String']>;
  /** First name (when you provide full name split into first and last) */
  firstName?: Maybe<Scalars['String']>;
  /** Last name (when you provide full name split into first and last) */
  lastName?: Maybe<Scalars['String']>;
  /** Full name */
  name?: Maybe<Scalars['String']>;
  /** Contacts phone number */
  phone?: Maybe<Scalars['String']>;
};

export type ContactReference = {
  __typename?: 'ContactReference';
  /** Contact's reference */
  contactRef?: Maybe<Scalars['String']>;
  /** Contacts first name */
  firstName?: Maybe<Scalars['String']>;
};

export type RootMutationType = {
  __typename?: 'RootMutationType';
  /** Adds an action referencing contact data via contactRef */
  addAction?: Maybe<ContactReference>;
  /** Adds an action with contact data */
  addActionContact?: Maybe<ContactReference>;
  /** Deprecated, use upsert_campaign. */
  declareCampaign?: Maybe<Campaign>;
  /** Link actions with refs to contact with contact reference */
  linkActions?: Maybe<ContactReference>;
  /** Update an Action Page */
  updateActionPage?: Maybe<ActionPage>;
  updateOrg?: Maybe<Org>;
  /**
   * Upserts a campaign.
   * 
   * Creates or appends campaign and it's action pages. In case of append, it
   * will change the campaign with the matching name, and action pages with
   * matching names. It will create new action pages if you pass new names. No
   * Action Pages will be removed (principle of not removing signature data).
   */
  upsertCampaign?: Maybe<Campaign>;
};


export type RootMutationTypeAddActionArgs = {
  action: ActionInput;
  actionPageId: Scalars['Int'];
  contactRef?: Maybe<Scalars['ID']>;
  tracking?: Maybe<TrackingInput>;
};


export type RootMutationTypeAddActionContactArgs = {
  action: ActionInput;
  actionPageId: Scalars['Int'];
  contact: ContactInput;
  contactRef?: Maybe<Scalars['ID']>;
  privacy: ConsentInput;
  tracking?: Maybe<TrackingInput>;
};


export type RootMutationTypeDeclareCampaignArgs = {
  actionPages: Array<Maybe<ActionPageInputLegacyUrl>>;
  externalId?: Maybe<Scalars['Int']>;
  name: Scalars['String'];
  orgName: Scalars['String'];
  title: Scalars['String'];
};


export type RootMutationTypeLinkActionsArgs = {
  actionPageId: Scalars['Int'];
  contactRef: Scalars['ID'];
  linkRefs?: Maybe<Array<Scalars['String']>>;
};


export type RootMutationTypeUpdateActionPageArgs = {
  config?: Maybe<Scalars['String']>;
  extraSupporters?: Maybe<Scalars['Int']>;
  id: Scalars['Int'];
  journey?: Maybe<Array<Scalars['String']>>;
  locale?: Maybe<Scalars['String']>;
  name?: Maybe<Scalars['String']>;
  thankYouTemplateRef?: Maybe<Scalars['String']>;
};


export type RootMutationTypeUpdateOrgArgs = {
  contactSchema?: Maybe<ContactSchema>;
  emailOptIn?: Maybe<Scalars['Boolean']>;
  emailOptInTemplate?: Maybe<Scalars['String']>;
  name: Scalars['String'];
  title?: Maybe<Scalars['String']>;
};


export type RootMutationTypeUpsertCampaignArgs = {
  actionPages: Array<Maybe<ActionPageInput>>;
  externalId?: Maybe<Scalars['Int']>;
  name: Scalars['String'];
  orgName: Scalars['String'];
  title: Scalars['String'];
};

export type Signature = {
  __typename?: 'Signature';
  /** Action page id */
  actionPageId?: Maybe<Scalars['Int']>;
  /** Campaign id */
  campaignId?: Maybe<Scalars['Int']>;
  /** Encrypted contact data in Base64url */
  contact?: Maybe<Scalars['String']>;
  /** DateTime of signature (UTC) */
  created?: Maybe<Scalars['Datetime']>;
  /** Signature id */
  id?: Maybe<Scalars['Int']>;
  /** Encryption nonce in Base64url */
  nonce?: Maybe<Scalars['String']>;
  /** Opt in given when adding sig */
  optIn?: Maybe<Scalars['Boolean']>;
};

export type RootQueryType = {
  __typename?: 'RootQueryType';
  /** Get action page */
  actionPage?: Maybe<ActionPage>;
  /** Get a list of campains */
  campaigns?: Maybe<Array<Maybe<Campaign>>>;
  exportActions?: Maybe<ActionsExport>;
  /** Organization api (authenticated) */
  org?: Maybe<Org>;
};


export type RootQueryTypeActionPageArgs = {
  id?: Maybe<Scalars['Int']>;
  name?: Maybe<Scalars['String']>;
  url?: Maybe<Scalars['String']>;
};


export type RootQueryTypeCampaignsArgs = {
  name?: Maybe<Scalars['String']>;
  title?: Maybe<Scalars['String']>;
};


export type RootQueryTypeExportActionsArgs = {
  after?: Maybe<Scalars['Datetime']>;
  campaignId?: Maybe<Scalars['Int']>;
  limit?: Maybe<Scalars['Int']>;
  orgName: Scalars['String'];
  start?: Maybe<Scalars['Int']>;
};


export type RootQueryTypeOrgArgs = {
  name: Scalars['String'];
};

export type SignatureList = {
  __typename?: 'SignatureList';
  /** List of returned signatures */
  list?: Maybe<Array<Maybe<Signature>>>;
  /** Public key of sender (proca app), in Base64url encoding (RFC 4648 5.) */
  publicKey?: Maybe<Scalars['String']>;
};

/** Campaign statistics */
export type CampaignStats = {
  __typename?: 'CampaignStats';
  /** Action counts for selected action types */
  actionCount?: Maybe<Array<ActionTypeCount>>;
  /** Signature count (naive at the moment) */
  supporterCount?: Maybe<Scalars['Int']>;
};

export type Org = {
  __typename?: 'Org';
  /** List action pages this org has */
  actionPages?: Maybe<Array<Maybe<ActionPage>>>;
  /** Get campaign this org is leader or partner of by id */
  campaign?: Maybe<Campaign>;
  /** List campaigns this org is leader or partner of */
  campaigns?: Maybe<Array<Maybe<Campaign>>>;
  /** Organization id */
  id?: Maybe<Scalars['Int']>;
  /** Organisation short name */
  name?: Maybe<Scalars['String']>;
  personalData: PersonalData;
  /**
   * Get signatures this org has collected.
   * Provide campaign_id to only get signatures for a campaign
   * XXX DEPRECATE AND REMOVE
   */
  signatures?: Maybe<SignatureList>;
  /** Organisation title (human readable name) */
  title?: Maybe<Scalars['String']>;
};


export type OrgCampaignArgs = {
  id?: Maybe<Scalars['Int']>;
};


export type OrgSignaturesArgs = {
  after?: Maybe<Scalars['Datetime']>;
  campaignId?: Maybe<Scalars['Int']>;
  limit?: Maybe<Scalars['Int']>;
  start?: Maybe<Scalars['Int']>;
};

/** ActionPage declaration (using the legacy url attribute) */
export type ActionPageInputLegacyUrl = {
  config?: Maybe<Scalars['String']>;
  extraSupporters?: Maybe<Scalars['Int']>;
  id?: Maybe<Scalars['Int']>;
  journey?: Maybe<Array<Scalars['String']>>;
  locale?: Maybe<Scalars['String']>;
  thankYouTemplateRef?: Maybe<Scalars['String']>;
  url?: Maybe<Scalars['String']>;
};

/** Address type which can hold different addres fields. */
export type AddressInput = {
  /** Country code (two-letter). */
  country?: Maybe<Scalars['String']>;
  /** Locality, which can be a city/town/village */
  locality?: Maybe<Scalars['String']>;
  /** Postcode, in format correct for country locale */
  postcode?: Maybe<Scalars['String']>;
  /** Region, being province, voyevodship, county */
  region?: Maybe<Scalars['String']>;
};

/** Custom field with a key and value. */
export type CustomField = {
  __typename?: 'CustomField';
  key: Scalars['String'];
  value: Scalars['String'];
};


/** Tracking codes */
export type TrackingInput = {
  campaign: Scalars['String'];
  content?: Maybe<Scalars['String']>;
  medium: Scalars['String'];
  source: Scalars['String'];
};

/** Custom field with a key and value. Both are strings. */
export type CustomFieldInput = {
  key: Scalars['String'];
  transient?: Maybe<Scalars['Boolean']>;
  value: Scalars['String'];
};



export type SdkFunctionWrapper = <T>(action: () => Promise<T>) => Promise<T>;


const defaultWrapper: SdkFunctionWrapper = sdkFunction => sdkFunction();
export function getSdk(client: GraphQLClient, withWrapper: SdkFunctionWrapper = defaultWrapper) {
  return {

  };
}
export type Sdk = ReturnType<typeof getSdk>;