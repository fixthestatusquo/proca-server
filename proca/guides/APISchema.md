# GraphQL API Schema

## Table of Contents
  * [Query](#query)
  * [Mutation](#mutation)
  * [Objects](#objects)
    * [Action](#action)
    * [ActionCustomFields](#actioncustomfields)
    * [ActionTypeCount](#actiontypecount)
    * [ActivateKeyResult](#activatekeyresult)
    * [ApiToken](#apitoken)
    * [AreaCount](#areacount)
    * [CampaignMtt](#campaignmtt)
    * [CampaignStats](#campaignstats)
    * [ChangeUserStatus](#changeuserstatus)
    * [Confirm](#confirm)
    * [ConfirmResult](#confirmresult)
    * [Consent](#consent)
    * [Contact](#contact)
    * [ContactReference](#contactreference)
    * [CustomField](#customfield)
    * [DeleteUserResult](#deleteuserresult)
    * [Donation](#donation)
    * [JoinOrgResult](#joinorgresult)
    * [Key](#key)
    * [KeyIds](#keyids)
    * [KeyWithPrivate](#keywithprivate)
    * [LaunchActionPageResult](#launchactionpageresult)
    * [OrgCount](#orgcount)
    * [OrgUser](#orguser)
    * [Partnership](#partnership)
    * [PersonalData](#personaldata)
    * [PrivateActionPage](#privateactionpage)
    * [PrivateCampaign](#privatecampaign)
    * [PrivateOrg](#privateorg)
    * [PrivateTarget](#privatetarget)
    * [Processing](#processing)
    * [PublicActionPage](#publicactionpage)
    * [PublicActionsResult](#publicactionsresult)
    * [PublicCampaign](#publiccampaign)
    * [PublicOrg](#publicorg)
    * [PublicTarget](#publictarget)
    * [RequeueResult](#requeueresult)
    * [RootSubscriptionType](#rootsubscriptiontype)
    * [Service](#service)
    * [TargetEmail](#targetemail)
    * [Tracking](#tracking)
    * [User](#user)
    * [UserRole](#userrole)
  * [Inputs](#inputs)
    * [ActionInput](#actioninput)
    * [ActionPageInput](#actionpageinput)
    * [AddKeyInput](#addkeyinput)
    * [AddressInput](#addressinput)
    * [CampaignInput](#campaigninput)
    * [CampaignMttInput](#campaignmttinput)
    * [ConfirmInput](#confirminput)
    * [ConsentInput](#consentinput)
    * [ContactInput](#contactinput)
    * [CustomFieldInput](#customfieldinput)
    * [DonationActionInput](#donationactioninput)
    * [EmailTemplateInput](#emailtemplateinput)
    * [GenKeyInput](#genkeyinput)
    * [MttActionInput](#mttactioninput)
    * [NationalityInput](#nationalityinput)
    * [OrgInput](#orginput)
    * [OrgUserInput](#orguserinput)
    * [SelectActionPage](#selectactionpage)
    * [SelectCampaign](#selectcampaign)
    * [SelectKey](#selectkey)
    * [SelectService](#selectservice)
    * [SelectUser](#selectuser)
    * [ServiceInput](#serviceinput)
    * [StripePaymentIntentInput](#stripepaymentintentinput)
    * [StripeSubscriptionInput](#stripesubscriptioninput)
    * [TargetEmailInput](#targetemailinput)
    * [TargetInput](#targetinput)
    * [TrackingInput](#trackinginput)
    * [UserDetailsInput](#userdetailsinput)
  * [Enums](#enums)
    * [ActionPageStatus](#actionpagestatus)
    * [ContactSchema](#contactschema)
    * [DonationFrequencyUnit](#donationfrequencyunit)
    * [DonationSchema](#donationschema)
    * [EmailStatus](#emailstatus)
    * [Queue](#queue)
    * [ServiceName](#servicename)
    * [Status](#status)
  * [Scalars](#scalars)
    * [Boolean](#boolean)
    * [Date](#date)
    * [DateTime](#datetime)
    * [ID](#id)
    * [Int](#int)
    * [Json](#json)
    * [NaiveDateTime](#naivedatetime)
    * [String](#string)
  * [Interfaces](#interfaces)
    * [ActionPage](#actionpage)
    * [Campaign](#campaign)
    * [Org](#org)
    * [Target](#target)


## Query (RootQueryType)
<table>
<thead>
<tr>
<th align="left">Field</th>
<th align="right">Argument</th>
<th align="left">Type</th>
<th align="left">Description</th>
</tr>
</thead>
<tbody>
<tr>
<td colspan="2" valign="top"><strong>campaigns</strong></td>
<td valign="top">[<a href="#campaign">Campaign</a>!]!</td>
<td>

Get a list of campains

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">title</td>
<td valign="top"><a href="#string">String</a></td>
<td>

Filter campaigns by title using LIKE format (% means any sequence of characters)

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">name</td>
<td valign="top"><a href="#string">String</a></td>
<td>

DEPRECATED: use campaign(). Filter campaigns by name (exact match). If found, returns list of 1 campaign, otherwise an empty list

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">id</td>
<td valign="top"><a href="#int">Int</a></td>
<td>

DEPRECATED: use campaign(). Select by id, Returns list of 1 result

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>campaign</strong></td>
<td valign="top"><a href="#campaign">Campaign</a></td>
<td>

Get campaign

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">id</td>
<td valign="top"><a href="#int">Int</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">name</td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>actionPage</strong></td>
<td valign="top"><a href="#actionpage">ActionPage</a>!</td>
<td>

Get action page

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">id</td>
<td valign="top"><a href="#int">Int</a></td>
<td>

Get action page by id.

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">name</td>
<td valign="top"><a href="#string">String</a></td>
<td>

Get action page by name the widget is displayed on

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">url</td>
<td valign="top"><a href="#string">String</a></td>
<td>

Get action page by url the widget is displayed on (DEPRECATED, use name)

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>exportActions</strong></td>
<td valign="top">[<a href="#action">Action</a>]!</td>
<td></td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">orgName</td>
<td valign="top"><a href="#string">String</a>!</td>
<td>

Organization name

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">campaignName</td>
<td valign="top"><a href="#string">String</a></td>
<td>

Limit results to campaign name

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">campaignId</td>
<td valign="top"><a href="#int">Int</a></td>
<td>

Limit results to campaign id

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">start</td>
<td valign="top"><a href="#int">Int</a></td>
<td>

return only actions with id starting from this argument (inclusive)

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">after</td>
<td valign="top"><a href="#datetime">DateTime</a></td>
<td>

return only actions created at date time from this argument (inclusive)

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">limit</td>
<td valign="top"><a href="#int">Int</a></td>
<td>

Limit the number of returned actions

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">onlyOptIn</td>
<td valign="top"><a href="#boolean">Boolean</a></td>
<td>

Only download opted in contacts and actions (default true)

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">onlyDoubleOptIn</td>
<td valign="top"><a href="#boolean">Boolean</a></td>
<td>

Only download double opted in contacts

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">includeTesting</td>
<td valign="top"><a href="#boolean">Boolean</a></td>
<td>

Also include testing actions

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>currentUser</strong></td>
<td valign="top"><a href="#user">User</a>!</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>users</strong></td>
<td valign="top">[<a href="#user">User</a>!]!</td>
<td>

Select users from this instnace. Requires a manage users admin permission.

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">select</td>
<td valign="top"><a href="#selectuser">SelectUser</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>org</strong></td>
<td valign="top"><a href="#privateorg">PrivateOrg</a>!</td>
<td>

Organization api (authenticated)

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">name</td>
<td valign="top"><a href="#string">String</a>!</td>
<td>

Name of organisation

</td>
</tr>
</tbody>
</table>

## Mutation (RootMutationType)
<table>
<thead>
<tr>
<th align="left">Field</th>
<th align="right">Argument</th>
<th align="left">Type</th>
<th align="left">Description</th>
</tr>
</thead>
<tbody>
<tr>
<td colspan="2" valign="top"><strong>upsertCampaign</strong></td>
<td valign="top"><a href="#campaign">Campaign</a>!</td>
<td>

Upserts a campaign.

Creates or appends campaign and it's action pages. In case of append, it
will change the campaign with the matching name, and action pages with
matching names. It will create new action pages if you pass new names. No
Action Pages will be removed (principle of not removing signature data).

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">orgName</td>
<td valign="top"><a href="#string">String</a>!</td>
<td>

Org name

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">input</td>
<td valign="top"><a href="#campaigninput">CampaignInput</a>!</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>updateCampaign</strong></td>
<td valign="top"><a href="#campaign">Campaign</a>!</td>
<td></td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">id</td>
<td valign="top"><a href="#int">Int</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">name</td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">input</td>
<td valign="top"><a href="#campaigninput">CampaignInput</a>!</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>addCampaign</strong></td>
<td valign="top"><a href="#campaign">Campaign</a>!</td>
<td></td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">orgName</td>
<td valign="top"><a href="#string">String</a>!</td>
<td>

Org that is lead of this campaign

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">input</td>
<td valign="top"><a href="#campaigninput">CampaignInput</a>!</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>deleteCampaign</strong></td>
<td valign="top"><a href="#status">Status</a>!</td>
<td></td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">id</td>
<td valign="top"><a href="#int">Int</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">name</td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">externalId</td>
<td valign="top"><a href="#int">Int</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>updateActionPage</strong></td>
<td valign="top"><a href="#actionpage">ActionPage</a>!</td>
<td>

Update an Action Page

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">id</td>
<td valign="top"><a href="#int">Int</a></td>
<td>

Action Page id

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">name</td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">input</td>
<td valign="top"><a href="#actionpageinput">ActionPageInput</a>!</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>copyActionPage</strong></td>
<td valign="top"><a href="#actionpage">ActionPage</a>!</td>
<td>

Adds a new Action Page based on another Action Page. Intended to be used to
create a partner action page based off lead's one. Copies: campaign, locale, config, delivery flag

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">orgName</td>
<td valign="top"><a href="#string">String</a>!</td>
<td>

Org owner of new Action Page

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">name</td>
<td valign="top"><a href="#string">String</a>!</td>
<td>

New Action Page name

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">fromName</td>
<td valign="top"><a href="#string">String</a>!</td>
<td>

Name of Action Page this one is cloned from

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>copyCampaignActionPage</strong></td>
<td valign="top"><a href="#actionpage">ActionPage</a>!</td>
<td>

Adds a new Action Page based on latest Action Page from campaign. Intended to be used to
create a partner action page based off lead's one. Copies: campaign, locale, config, delivery flag

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">orgName</td>
<td valign="top"><a href="#string">String</a>!</td>
<td>

Org owner of new Action Page

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">name</td>
<td valign="top"><a href="#string">String</a>!</td>
<td>

New Action Page name

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">fromCampaignName</td>
<td valign="top"><a href="#string">String</a>!</td>
<td>

Name of Campaign from which the page is copied

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>addActionPage</strong></td>
<td valign="top"><a href="#actionpage">ActionPage</a>!</td>
<td></td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">orgName</td>
<td valign="top"><a href="#string">String</a>!</td>
<td>

Org owner of new Action Page

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">campaignName</td>
<td valign="top"><a href="#string">String</a>!</td>
<td>

Name of campaign where page is created

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">input</td>
<td valign="top"><a href="#actionpageinput">ActionPageInput</a>!</td>
<td>

Action Page attributes

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>launchActionPage</strong></td>
<td valign="top"><a href="#launchactionpageresult">LaunchActionPageResult</a>!</td>
<td></td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">name</td>
<td valign="top"><a href="#string">String</a>!</td>
<td>

Action Page name

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">message</td>
<td valign="top"><a href="#string">String</a></td>
<td>

Optional message for approver

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>deleteActionPage</strong></td>
<td valign="top"><a href="#status">Status</a>!</td>
<td></td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">id</td>
<td valign="top"><a href="#int">Int</a></td>
<td>

Action Page id

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">name</td>
<td valign="top"><a href="#string">String</a></td>
<td>

Action Page name

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>addAction</strong></td>
<td valign="top"><a href="#contactreference">ContactReference</a>!</td>
<td>

Adds an action referencing contact data via contactRef

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">actionPageId</td>
<td valign="top"><a href="#int">Int</a>!</td>
<td></td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">action</td>
<td valign="top"><a href="#actioninput">ActionInput</a>!</td>
<td>

Action data

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">contactRef</td>
<td valign="top"><a href="#id">ID</a>!</td>
<td>

Contact reference

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">tracking</td>
<td valign="top"><a href="#trackinginput">TrackingInput</a></td>
<td>

Tracking codes (UTM_*)

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>addActionContact</strong></td>
<td valign="top"><a href="#contactreference">ContactReference</a>!</td>
<td>

Adds an action with contact data

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">actionPageId</td>
<td valign="top"><a href="#int">Int</a>!</td>
<td></td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">action</td>
<td valign="top"><a href="#actioninput">ActionInput</a>!</td>
<td>

Action data

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">contact</td>
<td valign="top"><a href="#contactinput">ContactInput</a>!</td>
<td>

GDPR communication opt

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">privacy</td>
<td valign="top"><a href="#consentinput">ConsentInput</a>!</td>
<td>

Signature action data

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">tracking</td>
<td valign="top"><a href="#trackinginput">TrackingInput</a></td>
<td>

Tracking codes (UTM_*)

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">contactRef</td>
<td valign="top"><a href="#id">ID</a></td>
<td>

Links previous actions with just reference to this supporter data

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>linkActions</strong></td>
<td valign="top"><a href="#contactreference">ContactReference</a>!</td>
<td>

Link actions with refs to contact with contact reference

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">actionPageId</td>
<td valign="top"><a href="#int">Int</a>!</td>
<td>

Action Page id

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">contactRef</td>
<td valign="top"><a href="#id">ID</a>!</td>
<td>

Contact reference

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">linkRefs</td>
<td valign="top">[<a href="#string">String</a>!]</td>
<td>

Link actions with these references (if unlinked to supporter)

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>requeueActions</strong></td>
<td valign="top"><a href="#requeueresult">RequeueResult</a>!</td>
<td>

Requeue actions into one of processing destinations

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">orgName</td>
<td valign="top"><a href="#string">String</a>!</td>
<td>

Organization name

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">ids</td>
<td valign="top">[<a href="#int">Int</a>!]</td>
<td>

Action Ids

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">queue</td>
<td valign="top"><a href="#queue">Queue</a>!</td>
<td>

Destination queue

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>addOrgUser</strong></td>
<td valign="top"><a href="#changeuserstatus">ChangeUserStatus</a>!</td>
<td>

Add user to org by email

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">orgName</td>
<td valign="top"><a href="#string">String</a>!</td>
<td></td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">input</td>
<td valign="top"><a href="#orguserinput">OrgUserInput</a>!</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>inviteOrgUser</strong></td>
<td valign="top"><a href="#confirm">Confirm</a>!</td>
<td>

Invite an user to org by email (can be not yet user!)

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">orgName</td>
<td valign="top"><a href="#string">String</a>!</td>
<td></td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">input</td>
<td valign="top"><a href="#orguserinput">OrgUserInput</a>!</td>
<td></td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">message</td>
<td valign="top"><a href="#string">String</a></td>
<td>

Optional message for invited user

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>updateOrgUser</strong></td>
<td valign="top"><a href="#changeuserstatus">ChangeUserStatus</a>!</td>
<td></td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">orgName</td>
<td valign="top"><a href="#string">String</a>!</td>
<td></td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">input</td>
<td valign="top"><a href="#orguserinput">OrgUserInput</a>!</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>deleteOrgUser</strong></td>
<td valign="top"><a href="#deleteuserresult">DeleteUserResult</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">orgName</td>
<td valign="top"><a href="#string">String</a>!</td>
<td></td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">email</td>
<td valign="top"><a href="#string">String</a>!</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>updateUser</strong></td>
<td valign="top"><a href="#user">User</a>!</td>
<td>

Update (current) user details

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">input</td>
<td valign="top"><a href="#userdetailsinput">UserDetailsInput</a>!</td>
<td>

Input values to update in user

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">id</td>
<td valign="top"><a href="#int">Int</a></td>
<td>

Admin can use user id to specify user to update

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">email</td>
<td valign="top"><a href="#string">String</a></td>
<td>

Admin can use user email to specify user to update

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>resetApiToken</strong></td>
<td valign="top"><a href="#string">String</a>!</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>addOrg</strong></td>
<td valign="top"><a href="#org">Org</a>!</td>
<td></td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">input</td>
<td valign="top"><a href="#orginput">OrgInput</a>!</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>deleteOrg</strong></td>
<td valign="top"><a href="#status">Status</a>!</td>
<td></td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">name</td>
<td valign="top"><a href="#string">String</a>!</td>
<td>

Name of organisation

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>updateOrg</strong></td>
<td valign="top"><a href="#privateorg">PrivateOrg</a>!</td>
<td></td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">name</td>
<td valign="top"><a href="#string">String</a>!</td>
<td>

Name of organisation, used for lookup, can't be used to change org name

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">input</td>
<td valign="top"><a href="#orginput">OrgInput</a>!</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>updateOrgProcessing</strong></td>
<td valign="top"><a href="#privateorg">PrivateOrg</a>!</td>
<td>

Update org processing settings

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">name</td>
<td valign="top"><a href="#string">String</a>!</td>
<td>

Set email backend to

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">emailBackend</td>
<td valign="top"><a href="#servicename">ServiceName</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">emailFrom</td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">supporterConfirm</td>
<td valign="top"><a href="#boolean">Boolean</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">supporterConfirmTemplate</td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">doiThankYou</td>
<td valign="top"><a href="#boolean">Boolean</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">customSupporterConfirm</td>
<td valign="top"><a href="#boolean">Boolean</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">customActionConfirm</td>
<td valign="top"><a href="#boolean">Boolean</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">customActionDeliver</td>
<td valign="top"><a href="#boolean">Boolean</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">customEventDeliver</td>
<td valign="top"><a href="#boolean">Boolean</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">eventBackend</td>
<td valign="top"><a href="#servicename">ServiceName</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">storageBackend</td>
<td valign="top"><a href="#servicename">ServiceName</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">detailBackend</td>
<td valign="top"><a href="#servicename">ServiceName</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">pushBackend</td>
<td valign="top"><a href="#servicename">ServiceName</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>joinOrg</strong></td>
<td valign="top"><a href="#joinorgresult">JoinOrgResult</a>!</td>
<td></td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">name</td>
<td valign="top"><a href="#string">String</a>!</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>generateKey</strong></td>
<td valign="top"><a href="#keywithprivate">KeyWithPrivate</a>!</td>
<td></td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">orgName</td>
<td valign="top"><a href="#string">String</a>!</td>
<td>

Name of organisation

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">input</td>
<td valign="top"><a href="#genkeyinput">GenKeyInput</a>!</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>addKey</strong></td>
<td valign="top"><a href="#key">Key</a>!</td>
<td></td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">orgName</td>
<td valign="top"><a href="#string">String</a>!</td>
<td>

Name of organisation

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">input</td>
<td valign="top"><a href="#addkeyinput">AddKeyInput</a>!</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>activateKey</strong></td>
<td valign="top"><a href="#activatekeyresult">ActivateKeyResult</a>!</td>
<td>

A separate key activate operation, because you also need to add the key to receiving system before it is used

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">orgName</td>
<td valign="top"><a href="#string">String</a>!</td>
<td></td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">id</td>
<td valign="top"><a href="#int">Int</a>!</td>
<td>

Key id

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>upsertTemplate</strong></td>
<td valign="top"><a href="#status">Status</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">orgName</td>
<td valign="top"><a href="#string">String</a>!</td>
<td></td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">input</td>
<td valign="top"><a href="#emailtemplateinput">EmailTemplateInput</a>!</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>upsertService</strong></td>
<td valign="top"><a href="#service">Service</a>!</td>
<td></td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">orgName</td>
<td valign="top"><a href="#string">String</a>!</td>
<td></td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">id</td>
<td valign="top"><a href="#int">Int</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">input</td>
<td valign="top"><a href="#serviceinput">ServiceInput</a>!</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>addStripePaymentIntent</strong></td>
<td valign="top"><a href="#json">Json</a>!</td>
<td></td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">actionPageId</td>
<td valign="top"><a href="#int">Int</a>!</td>
<td></td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">input</td>
<td valign="top"><a href="#stripepaymentintentinput">StripePaymentIntentInput</a>!</td>
<td></td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">contactRef</td>
<td valign="top"><a href="#id">ID</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">testing</td>
<td valign="top"><a href="#boolean">Boolean</a></td>
<td>

Use test stripe api keys

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>addStripeSubscription</strong></td>
<td valign="top"><a href="#json">Json</a>!</td>
<td></td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">actionPageId</td>
<td valign="top"><a href="#int">Int</a>!</td>
<td></td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">input</td>
<td valign="top"><a href="#stripesubscriptioninput">StripeSubscriptionInput</a>!</td>
<td></td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">contactRef</td>
<td valign="top"><a href="#id">ID</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">testing</td>
<td valign="top"><a href="#boolean">Boolean</a></td>
<td>

Use test stripe api keys

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>addStripeObject</strong></td>
<td valign="top"><a href="#json">Json</a>!</td>
<td>

Create stripe object using Stripe key associated with action page owning org.
Pass any of paymentIntent, subscription, customer, price json params to be sent as-is to Stripe API. The result is a JSON returned by Stripe API or a GraphQL Error object.
If you provide customer along payment intent or subscription, it will be first created, then their id will be added to params for the payment intent or subscription, so you can pack 2 Stripe API calls into one. You can do the same with price object in case of a subscription.

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">actionPageId</td>
<td valign="top"><a href="#int">Int</a>!</td>
<td></td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">paymentIntent</td>
<td valign="top"><a href="#json">Json</a></td>
<td>

Parameters for Stripe Payment Intent creation

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">subscription</td>
<td valign="top"><a href="#json">Json</a></td>
<td>

Parameters for Stripe Subscription creation

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">customer</td>
<td valign="top"><a href="#json">Json</a></td>
<td>

Parameters for Stripe Customer creation

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">price</td>
<td valign="top"><a href="#json">Json</a></td>
<td>

Parameters for Stripe Price creation

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">testing</td>
<td valign="top"><a href="#boolean">Boolean</a></td>
<td>

Use test stripe api keys

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>acceptOrgConfirm</strong></td>
<td valign="top"><a href="#confirmresult">ConfirmResult</a>!</td>
<td>

Accept a confirm on behalf of organisation.

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">name</td>
<td valign="top"><a href="#string">String</a>!</td>
<td></td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">confirm</td>
<td valign="top"><a href="#confirminput">ConfirmInput</a>!</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>rejectOrgConfirm</strong></td>
<td valign="top"><a href="#confirmresult">ConfirmResult</a>!</td>
<td>

Reject a confirm on behalf of organisation.

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">name</td>
<td valign="top"><a href="#string">String</a>!</td>
<td></td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">confirm</td>
<td valign="top"><a href="#confirminput">ConfirmInput</a>!</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>acceptUserConfirm</strong></td>
<td valign="top"><a href="#confirmresult">ConfirmResult</a>!</td>
<td>

Accept a confirm by user

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">confirm</td>
<td valign="top"><a href="#confirminput">ConfirmInput</a>!</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>rejectUserConfirm</strong></td>
<td valign="top"><a href="#confirmresult">ConfirmResult</a>!</td>
<td>

Reject a confirm by user

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">confirm</td>
<td valign="top"><a href="#confirminput">ConfirmInput</a>!</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>upsertTargets</strong></td>
<td valign="top">[<a href="#privatetarget">PrivateTarget</a>]!</td>
<td></td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">targets</td>
<td valign="top">[<a href="#targetinput">TargetInput</a>!]!</td>
<td></td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">campaignId</td>
<td valign="top"><a href="#int">Int</a>!</td>
<td></td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">replace</td>
<td valign="top"><a href="#boolean">Boolean</a></td>
<td></td>
</tr>
</tbody>
</table>

## Objects

### Action

<table>
<thead>
<tr>
<th align="left">Field</th>
<th align="right">Argument</th>
<th align="left">Type</th>
<th align="left">Description</th>
</tr>
</thead>
<tbody>
<tr>
<td colspan="2" valign="top"><strong>actionId</strong></td>
<td valign="top"><a href="#int">Int</a>!</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>createdAt</strong></td>
<td valign="top"><a href="#naivedatetime">NaiveDateTime</a>!</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>actionType</strong></td>
<td valign="top"><a href="#string">String</a>!</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>contact</strong></td>
<td valign="top"><a href="#contact">Contact</a>!</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>customFields</strong></td>
<td valign="top"><a href="#json">Json</a>!</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>fields</strong> ⚠️</td>
<td valign="top">[<a href="#customfield">CustomField</a>!]!</td>
<td>

Deprecated, use customFields

<p>⚠️ <strong>DEPRECATED</strong></p>
<blockquote>

use custom_fields

</blockquote>
</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>tracking</strong></td>
<td valign="top"><a href="#tracking">Tracking</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>campaign</strong></td>
<td valign="top"><a href="#campaign">Campaign</a>!</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>actionPage</strong></td>
<td valign="top"><a href="#actionpage">ActionPage</a>!</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>privacy</strong></td>
<td valign="top"><a href="#consent">Consent</a>!</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>donation</strong></td>
<td valign="top"><a href="#donation">Donation</a></td>
<td></td>
</tr>
</tbody>
</table>

### ActionCustomFields

<table>
<thead>
<tr>
<th align="left">Field</th>
<th align="right">Argument</th>
<th align="left">Type</th>
<th align="left">Description</th>
</tr>
</thead>
<tbody>
<tr>
<td colspan="2" valign="top"><strong>actionId</strong></td>
<td valign="top"><a href="#int">Int</a>!</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>actionType</strong></td>
<td valign="top"><a href="#string">String</a>!</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>insertedAt</strong></td>
<td valign="top"><a href="#naivedatetime">NaiveDateTime</a>!</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>area</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>customFields</strong></td>
<td valign="top"><a href="#json">Json</a>!</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>fields</strong> ⚠️</td>
<td valign="top">[<a href="#customfield">CustomField</a>!]!</td>
<td>
<p>⚠️ <strong>DEPRECATED</strong></p>
<blockquote>

use custom_fields

</blockquote>
</td>
</tr>
</tbody>
</table>

### ActionTypeCount

Count of actions for particular action type

<table>
<thead>
<tr>
<th align="left">Field</th>
<th align="right">Argument</th>
<th align="left">Type</th>
<th align="left">Description</th>
</tr>
</thead>
<tbody>
<tr>
<td colspan="2" valign="top"><strong>actionType</strong></td>
<td valign="top"><a href="#string">String</a>!</td>
<td>

action type

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>count</strong></td>
<td valign="top"><a href="#int">Int</a>!</td>
<td>

count of actions of action type

</td>
</tr>
</tbody>
</table>

### ActivateKeyResult

<table>
<thead>
<tr>
<th align="left">Field</th>
<th align="right">Argument</th>
<th align="left">Type</th>
<th align="left">Description</th>
</tr>
</thead>
<tbody>
<tr>
<td colspan="2" valign="top"><strong>status</strong></td>
<td valign="top"><a href="#status">Status</a>!</td>
<td></td>
</tr>
</tbody>
</table>

### ApiToken

Api token metadata

<table>
<thead>
<tr>
<th align="left">Field</th>
<th align="right">Argument</th>
<th align="left">Type</th>
<th align="left">Description</th>
</tr>
</thead>
<tbody>
<tr>
<td colspan="2" valign="top"><strong>expiresAt</strong></td>
<td valign="top"><a href="#naivedatetime">NaiveDateTime</a>!</td>
<td></td>
</tr>
</tbody>
</table>

### AreaCount

Count of actions for particular action type

<table>
<thead>
<tr>
<th align="left">Field</th>
<th align="right">Argument</th>
<th align="left">Type</th>
<th align="left">Description</th>
</tr>
</thead>
<tbody>
<tr>
<td colspan="2" valign="top"><strong>area</strong></td>
<td valign="top"><a href="#string">String</a>!</td>
<td>

area

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>count</strong></td>
<td valign="top"><a href="#int">Int</a>!</td>
<td>

count of supporters in this area

</td>
</tr>
</tbody>
</table>

### CampaignMtt

<table>
<thead>
<tr>
<th align="left">Field</th>
<th align="right">Argument</th>
<th align="left">Type</th>
<th align="left">Description</th>
</tr>
</thead>
<tbody>
<tr>
<td colspan="2" valign="top"><strong>startAt</strong></td>
<td valign="top"><a href="#datetime">DateTime</a>!</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>endAt</strong></td>
<td valign="top"><a href="#datetime">DateTime</a>!</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>messageTemplate</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>testEmail</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
</tbody>
</table>

### CampaignStats

Campaign statistics

<table>
<thead>
<tr>
<th align="left">Field</th>
<th align="right">Argument</th>
<th align="left">Type</th>
<th align="left">Description</th>
</tr>
</thead>
<tbody>
<tr>
<td colspan="2" valign="top"><strong>supporterCount</strong></td>
<td valign="top"><a href="#int">Int</a>!</td>
<td>

Unique action tagers count

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>supporterCountByArea</strong></td>
<td valign="top">[<a href="#areacount">AreaCount</a>!]!</td>
<td>

Unique action takers by area

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>supporterCountByOrg</strong></td>
<td valign="top">[<a href="#orgcount">OrgCount</a>!]!</td>
<td>

Unique action takers by org

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>supporterCountByOthers</strong></td>
<td valign="top"><a href="#int">Int</a>!</td>
<td></td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">orgName</td>
<td valign="top"><a href="#string">String</a>!</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>actionCount</strong></td>
<td valign="top">[<a href="#actiontypecount">ActionTypeCount</a>!]!</td>
<td>

Action counts for selected action types

</td>
</tr>
</tbody>
</table>

### ChangeUserStatus

<table>
<thead>
<tr>
<th align="left">Field</th>
<th align="right">Argument</th>
<th align="left">Type</th>
<th align="left">Description</th>
</tr>
</thead>
<tbody>
<tr>
<td colspan="2" valign="top"><strong>status</strong></td>
<td valign="top"><a href="#status">Status</a>!</td>
<td></td>
</tr>
</tbody>
</table>

### Confirm

<table>
<thead>
<tr>
<th align="left">Field</th>
<th align="right">Argument</th>
<th align="left">Type</th>
<th align="left">Description</th>
</tr>
</thead>
<tbody>
<tr>
<td colspan="2" valign="top"><strong>code</strong></td>
<td valign="top"><a href="#string">String</a>!</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>email</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>message</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>objectId</strong></td>
<td valign="top"><a href="#int">Int</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>creator</strong></td>
<td valign="top"><a href="#user">User</a></td>
<td></td>
</tr>
</tbody>
</table>

### ConfirmResult

<table>
<thead>
<tr>
<th align="left">Field</th>
<th align="right">Argument</th>
<th align="left">Type</th>
<th align="left">Description</th>
</tr>
</thead>
<tbody>
<tr>
<td colspan="2" valign="top"><strong>status</strong></td>
<td valign="top"><a href="#status">Status</a>!</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>actionPage</strong></td>
<td valign="top"><a href="#actionpage">ActionPage</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>campaign</strong></td>
<td valign="top"><a href="#campaign">Campaign</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>org</strong></td>
<td valign="top"><a href="#org">Org</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>message</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
</tbody>
</table>

### Consent

GDPR consent data for this org

<table>
<thead>
<tr>
<th align="left">Field</th>
<th align="right">Argument</th>
<th align="left">Type</th>
<th align="left">Description</th>
</tr>
</thead>
<tbody>
<tr>
<td colspan="2" valign="top"><strong>optIn</strong></td>
<td valign="top"><a href="#boolean">Boolean</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>givenAt</strong></td>
<td valign="top"><a href="#naivedatetime">NaiveDateTime</a>!</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>emailStatus</strong></td>
<td valign="top"><a href="#emailstatus">EmailStatus</a>!</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>emailStatusChanged</strong></td>
<td valign="top"><a href="#naivedatetime">NaiveDateTime</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>withConsent</strong></td>
<td valign="top"><a href="#boolean">Boolean</a>!</td>
<td></td>
</tr>
</tbody>
</table>

### Contact

<table>
<thead>
<tr>
<th align="left">Field</th>
<th align="right">Argument</th>
<th align="left">Type</th>
<th align="left">Description</th>
</tr>
</thead>
<tbody>
<tr>
<td colspan="2" valign="top"><strong>contactRef</strong></td>
<td valign="top"><a href="#id">ID</a>!</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>payload</strong></td>
<td valign="top"><a href="#string">String</a>!</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>nonce</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>publicKey</strong></td>
<td valign="top"><a href="#keyids">KeyIds</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>signKey</strong></td>
<td valign="top"><a href="#keyids">KeyIds</a></td>
<td></td>
</tr>
</tbody>
</table>

### ContactReference

<table>
<thead>
<tr>
<th align="left">Field</th>
<th align="right">Argument</th>
<th align="left">Type</th>
<th align="left">Description</th>
</tr>
</thead>
<tbody>
<tr>
<td colspan="2" valign="top"><strong>contactRef</strong></td>
<td valign="top"><a href="#string">String</a>!</td>
<td>

Contact's reference

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>firstName</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td>

Contacts first name

</td>
</tr>
</tbody>
</table>

### CustomField

Custom field with a key and value.

<table>
<thead>
<tr>
<th align="left">Field</th>
<th align="right">Argument</th>
<th align="left">Type</th>
<th align="left">Description</th>
</tr>
</thead>
<tbody>
<tr>
<td colspan="2" valign="top"><strong>key</strong></td>
<td valign="top"><a href="#string">String</a>!</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>value</strong></td>
<td valign="top"><a href="#string">String</a>!</td>
<td></td>
</tr>
</tbody>
</table>

### DeleteUserResult

<table>
<thead>
<tr>
<th align="left">Field</th>
<th align="right">Argument</th>
<th align="left">Type</th>
<th align="left">Description</th>
</tr>
</thead>
<tbody>
<tr>
<td colspan="2" valign="top"><strong>status</strong></td>
<td valign="top"><a href="#status">Status</a>!</td>
<td></td>
</tr>
</tbody>
</table>

### Donation

<table>
<thead>
<tr>
<th align="left">Field</th>
<th align="right">Argument</th>
<th align="left">Type</th>
<th align="left">Description</th>
</tr>
</thead>
<tbody>
<tr>
<td colspan="2" valign="top"><strong>schema</strong></td>
<td valign="top"><a href="#donationschema">DonationSchema</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>amount</strong></td>
<td valign="top"><a href="#int">Int</a>!</td>
<td>

Provide amount of this donation, in smallest units for currency

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>currency</strong></td>
<td valign="top"><a href="#string">String</a>!</td>
<td>

Provide currency of this donation

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>payload</strong></td>
<td valign="top"><a href="#json">Json</a>!</td>
<td>

Donation data

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>frequencyUnit</strong></td>
<td valign="top"><a href="#donationfrequencyunit">DonationFrequencyUnit</a>!</td>
<td>

Donation frequency unit

</td>
</tr>
</tbody>
</table>

### JoinOrgResult

<table>
<thead>
<tr>
<th align="left">Field</th>
<th align="right">Argument</th>
<th align="left">Type</th>
<th align="left">Description</th>
</tr>
</thead>
<tbody>
<tr>
<td colspan="2" valign="top"><strong>status</strong></td>
<td valign="top"><a href="#status">Status</a>!</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>org</strong></td>
<td valign="top"><a href="#org">Org</a>!</td>
<td></td>
</tr>
</tbody>
</table>

### Key

Encryption or sign key with integer id (database)

<table>
<thead>
<tr>
<th align="left">Field</th>
<th align="right">Argument</th>
<th align="left">Type</th>
<th align="left">Description</th>
</tr>
</thead>
<tbody>
<tr>
<td colspan="2" valign="top"><strong>id</strong></td>
<td valign="top"><a href="#int">Int</a>!</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>public</strong></td>
<td valign="top"><a href="#string">String</a>!</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>name</strong></td>
<td valign="top"><a href="#string">String</a>!</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>active</strong></td>
<td valign="top"><a href="#boolean">Boolean</a>!</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>expired</strong></td>
<td valign="top"><a href="#boolean">Boolean</a>!</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>expiredAt</strong></td>
<td valign="top"><a href="#naivedatetime">NaiveDateTime</a></td>
<td>

When the key was expired, in UTC

</td>
</tr>
</tbody>
</table>

### KeyIds

<table>
<thead>
<tr>
<th align="left">Field</th>
<th align="right">Argument</th>
<th align="left">Type</th>
<th align="left">Description</th>
</tr>
</thead>
<tbody>
<tr>
<td colspan="2" valign="top"><strong>id</strong></td>
<td valign="top"><a href="#int">Int</a>!</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>public</strong></td>
<td valign="top"><a href="#string">String</a>!</td>
<td></td>
</tr>
</tbody>
</table>

### KeyWithPrivate

<table>
<thead>
<tr>
<th align="left">Field</th>
<th align="right">Argument</th>
<th align="left">Type</th>
<th align="left">Description</th>
</tr>
</thead>
<tbody>
<tr>
<td colspan="2" valign="top"><strong>id</strong></td>
<td valign="top"><a href="#int">Int</a>!</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>public</strong></td>
<td valign="top"><a href="#string">String</a>!</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>private</strong></td>
<td valign="top"><a href="#string">String</a>!</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>name</strong></td>
<td valign="top"><a href="#string">String</a>!</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>active</strong></td>
<td valign="top"><a href="#boolean">Boolean</a>!</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>expired</strong></td>
<td valign="top"><a href="#boolean">Boolean</a>!</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>expiredAt</strong></td>
<td valign="top"><a href="#naivedatetime">NaiveDateTime</a></td>
<td>

When the key was expired, in UTC

</td>
</tr>
</tbody>
</table>

### LaunchActionPageResult

<table>
<thead>
<tr>
<th align="left">Field</th>
<th align="right">Argument</th>
<th align="left">Type</th>
<th align="left">Description</th>
</tr>
</thead>
<tbody>
<tr>
<td colspan="2" valign="top"><strong>status</strong></td>
<td valign="top"><a href="#status">Status</a>!</td>
<td></td>
</tr>
</tbody>
</table>

### OrgCount

Count of supporters for particular org

<table>
<thead>
<tr>
<th align="left">Field</th>
<th align="right">Argument</th>
<th align="left">Type</th>
<th align="left">Description</th>
</tr>
</thead>
<tbody>
<tr>
<td colspan="2" valign="top"><strong>org</strong></td>
<td valign="top"><a href="#org">Org</a>!</td>
<td>

org

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>count</strong></td>
<td valign="top"><a href="#int">Int</a>!</td>
<td>

count of supporters registered by org

</td>
</tr>
</tbody>
</table>

### OrgUser

<table>
<thead>
<tr>
<th align="left">Field</th>
<th align="right">Argument</th>
<th align="left">Type</th>
<th align="left">Description</th>
</tr>
</thead>
<tbody>
<tr>
<td colspan="2" valign="top"><strong>email</strong></td>
<td valign="top"><a href="#string">String</a>!</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>role</strong></td>
<td valign="top"><a href="#string">String</a>!</td>
<td>

Role in an org

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>createdAt</strong></td>
<td valign="top"><a href="#naivedatetime">NaiveDateTime</a>!</td>
<td>

Date and time the user was created on this instance

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>joinedAt</strong></td>
<td valign="top"><a href="#naivedatetime">NaiveDateTime</a>!</td>
<td>

Date and time when user joined org

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>lastSigninAt</strong></td>
<td valign="top"><a href="#naivedatetime">NaiveDateTime</a></td>
<td>

Will be removed

</td>
</tr>
</tbody>
</table>

### Partnership

<table>
<thead>
<tr>
<th align="left">Field</th>
<th align="right">Argument</th>
<th align="left">Type</th>
<th align="left">Description</th>
</tr>
</thead>
<tbody>
<tr>
<td colspan="2" valign="top"><strong>org</strong></td>
<td valign="top"><a href="#org">Org</a>!</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>actionPages</strong></td>
<td valign="top">[<a href="#actionpage">ActionPage</a>!]!</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>launchRequests</strong></td>
<td valign="top">[<a href="#confirm">Confirm</a>!]!</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>launchRequesters</strong></td>
<td valign="top">[<a href="#user">User</a>!]!</td>
<td></td>
</tr>
</tbody>
</table>

### PersonalData

<table>
<thead>
<tr>
<th align="left">Field</th>
<th align="right">Argument</th>
<th align="left">Type</th>
<th align="left">Description</th>
</tr>
</thead>
<tbody>
<tr>
<td colspan="2" valign="top"><strong>contactSchema</strong></td>
<td valign="top"><a href="#contactschema">ContactSchema</a>!</td>
<td>

Schema for contact personal information

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>supporterConfirm</strong></td>
<td valign="top"><a href="#boolean">Boolean</a>!</td>
<td>

Email opt in enabled

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>supporterConfirmTemplate</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td>

Email opt in template name

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>highSecurity</strong></td>
<td valign="top"><a href="#boolean">Boolean</a>!</td>
<td>

High data security enabled

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>doiThankYou</strong></td>
<td valign="top"><a href="#boolean">Boolean</a>!</td>
<td>

Only send thank you emails to opt-ins

</td>
</tr>
</tbody>
</table>

### PrivateActionPage

<table>
<thead>
<tr>
<th align="left">Field</th>
<th align="right">Argument</th>
<th align="left">Type</th>
<th align="left">Description</th>
</tr>
</thead>
<tbody>
<tr>
<td colspan="2" valign="top"><strong>id</strong></td>
<td valign="top"><a href="#int">Int</a>!</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>locale</strong></td>
<td valign="top"><a href="#string">String</a>!</td>
<td>

Locale for the widget, in i18n format

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>name</strong></td>
<td valign="top"><a href="#string">String</a>!</td>
<td>

Name where the widget is hosted

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>thankYouTemplate</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td>

Thank you email templated of this Action Page

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>thankYouTemplateRef</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td>

A reference to thank you email template of this ActionPage

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>live</strong></td>
<td valign="top"><a href="#boolean">Boolean</a>!</td>
<td>

Is live?

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>journey</strong></td>
<td valign="top">[<a href="#string">String</a>!]!</td>
<td>

List of steps in journey (DEPRECATED: moved under config)

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>config</strong></td>
<td valign="top"><a href="#json">Json</a>!</td>
<td>

Config JSON of this action page

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>campaign</strong></td>
<td valign="top"><a href="#campaign">Campaign</a>!</td>
<td>

Campaign this action page belongs to.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>org</strong></td>
<td valign="top"><a href="#org">Org</a>!</td>
<td>

Org the action page belongs to

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>extraSupporters</strong></td>
<td valign="top"><a href="#int">Int</a>!</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>delivery</strong></td>
<td valign="top"><a href="#boolean">Boolean</a>!</td>
<td>

Action page collects also opt-out actions

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>supporterConfirmTemplate</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td>

Email template to confirm supporter

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>location</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td>

Location of the widget as last seen in HTTP REFERER header

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>status</strong></td>
<td valign="top"><a href="#actionpagestatus">ActionPageStatus</a></td>
<td>

Status of action page

</td>
</tr>
</tbody>
</table>

### PrivateCampaign

<table>
<thead>
<tr>
<th align="left">Field</th>
<th align="right">Argument</th>
<th align="left">Type</th>
<th align="left">Description</th>
</tr>
</thead>
<tbody>
<tr>
<td colspan="2" valign="top"><strong>id</strong></td>
<td valign="top"><a href="#int">Int</a>!</td>
<td>

Campaign id

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>externalId</strong></td>
<td valign="top"><a href="#int">Int</a></td>
<td>

External ID (if set)

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>name</strong></td>
<td valign="top"><a href="#string">String</a>!</td>
<td>

Internal name of the campaign

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>title</strong></td>
<td valign="top"><a href="#string">String</a>!</td>
<td>

Full, official name of the campaign

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>contactSchema</strong></td>
<td valign="top"><a href="#contactschema">ContactSchema</a>!</td>
<td>

Schema for contact personal information

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>config</strong></td>
<td valign="top"><a href="#json">Json</a>!</td>
<td>

Custom config map

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>stats</strong></td>
<td valign="top"><a href="#campaignstats">CampaignStats</a>!</td>
<td>

Campaign statistics

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>org</strong></td>
<td valign="top"><a href="#org">Org</a>!</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>actions</strong></td>
<td valign="top"><a href="#publicactionsresult">PublicActionsResult</a>!</td>
<td>

Fetch public actions

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">actionType</td>
<td valign="top"><a href="#string">String</a>!</td>
<td>

Return actions of this action type

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">limit</td>
<td valign="top"><a href="#int">Int</a>!</td>
<td>

Limit the number of returned actions, default is 10, max is 100)

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>targets</strong></td>
<td valign="top">[<a href="#target">Target</a>]</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>forceDelivery</strong></td>
<td valign="top"><a href="#boolean">Boolean</a>!</td>
<td>

Campaign onwer collects opt-out actions for delivery even if campaign partner is

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>actionPages</strong></td>
<td valign="top">[<a href="#privateactionpage">PrivateActionPage</a>!]!</td>
<td>

Action Pages of this campaign that are accessible to current user

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>partnerships</strong></td>
<td valign="top">[<a href="#partnership">Partnership</a>!]</td>
<td>

List of partnerships and requests

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>mtt</strong></td>
<td valign="top"><a href="#campaignmtt">CampaignMtt</a></td>
<td>

MTT configuration

</td>
</tr>
</tbody>
</table>

### PrivateOrg

<table>
<thead>
<tr>
<th align="left">Field</th>
<th align="right">Argument</th>
<th align="left">Type</th>
<th align="left">Description</th>
</tr>
</thead>
<tbody>
<tr>
<td colspan="2" valign="top"><strong>name</strong></td>
<td valign="top"><a href="#string">String</a>!</td>
<td>

Organisation short name

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>title</strong></td>
<td valign="top"><a href="#string">String</a>!</td>
<td>

Organisation title (human readable name)

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>config</strong></td>
<td valign="top"><a href="#json">Json</a>!</td>
<td>

config

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>id</strong></td>
<td valign="top"><a href="#int">Int</a>!</td>
<td>

Organization id

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>personalData</strong></td>
<td valign="top"><a href="#personaldata">PersonalData</a>!</td>
<td>

Personal data settings for this org

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>keys</strong></td>
<td valign="top">[<a href="#key">Key</a>!]!</td>
<td></td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">select</td>
<td valign="top"><a href="#selectkey">SelectKey</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>key</strong></td>
<td valign="top"><a href="#key">Key</a>!</td>
<td></td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">select</td>
<td valign="top"><a href="#selectkey">SelectKey</a>!</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>services</strong></td>
<td valign="top">[<a href="#service">Service</a>]!</td>
<td></td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">select</td>
<td valign="top"><a href="#selectservice">SelectService</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>users</strong></td>
<td valign="top">[<a href="#orguser">OrgUser</a>]!</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>processing</strong></td>
<td valign="top"><a href="#processing">Processing</a>!</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>campaigns</strong></td>
<td valign="top">[<a href="#campaign">Campaign</a>!]!</td>
<td>

List campaigns this org is leader or partner of

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">select</td>
<td valign="top"><a href="#selectcampaign">SelectCampaign</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>actionPages</strong></td>
<td valign="top">[<a href="#actionpage">ActionPage</a>!]!</td>
<td>

List action pages this org has

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">select</td>
<td valign="top"><a href="#selectactionpage">SelectActionPage</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>actionPage</strong></td>
<td valign="top"><a href="#actionpage">ActionPage</a>!</td>
<td>

Action Page

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">id</td>
<td valign="top"><a href="#int">Int</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">name</td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>campaign</strong></td>
<td valign="top"><a href="#campaign">Campaign</a>!</td>
<td>

DEPRECATED: use campaign() in API root. Get campaign this org is leader or partner of by id

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">id</td>
<td valign="top"><a href="#int">Int</a>!</td>
<td></td>
</tr>
</tbody>
</table>

### PrivateTarget

<table>
<thead>
<tr>
<th align="left">Field</th>
<th align="right">Argument</th>
<th align="left">Type</th>
<th align="left">Description</th>
</tr>
</thead>
<tbody>
<tr>
<td colspan="2" valign="top"><strong>id</strong></td>
<td valign="top"><a href="#string">String</a>!</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>name</strong></td>
<td valign="top"><a href="#string">String</a>!</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>externalId</strong></td>
<td valign="top"><a href="#string">String</a>!</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>locale</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>area</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>fields</strong></td>
<td valign="top"><a href="#json">Json</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>emails</strong></td>
<td valign="top">[<a href="#targetemail">TargetEmail</a>]!</td>
<td></td>
</tr>
</tbody>
</table>

### Processing

<table>
<thead>
<tr>
<th align="left">Field</th>
<th align="right">Argument</th>
<th align="left">Type</th>
<th align="left">Description</th>
</tr>
</thead>
<tbody>
<tr>
<td colspan="2" valign="top"><strong>emailFrom</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>emailBackend</strong></td>
<td valign="top"><a href="#servicename">ServiceName</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>supporterConfirm</strong></td>
<td valign="top"><a href="#boolean">Boolean</a>!</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>supporterConfirmTemplate</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>doiThankYou</strong></td>
<td valign="top"><a href="#boolean">Boolean</a>!</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>customSupporterConfirm</strong></td>
<td valign="top"><a href="#boolean">Boolean</a>!</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>customActionConfirm</strong></td>
<td valign="top"><a href="#boolean">Boolean</a>!</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>customActionDeliver</strong></td>
<td valign="top"><a href="#boolean">Boolean</a>!</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>customEventDeliver</strong></td>
<td valign="top"><a href="#boolean">Boolean</a>!</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>eventBackend</strong></td>
<td valign="top"><a href="#servicename">ServiceName</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>pushBackend</strong></td>
<td valign="top"><a href="#servicename">ServiceName</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>storageBackend</strong></td>
<td valign="top"><a href="#servicename">ServiceName</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>detailBackend</strong></td>
<td valign="top"><a href="#servicename">ServiceName</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>emailTemplates</strong></td>
<td valign="top">[<a href="#string">String</a>!]</td>
<td></td>
</tr>
</tbody>
</table>

### PublicActionPage

<table>
<thead>
<tr>
<th align="left">Field</th>
<th align="right">Argument</th>
<th align="left">Type</th>
<th align="left">Description</th>
</tr>
</thead>
<tbody>
<tr>
<td colspan="2" valign="top"><strong>id</strong></td>
<td valign="top"><a href="#int">Int</a>!</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>locale</strong></td>
<td valign="top"><a href="#string">String</a>!</td>
<td>

Locale for the widget, in i18n format

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>name</strong></td>
<td valign="top"><a href="#string">String</a>!</td>
<td>

Name where the widget is hosted

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>thankYouTemplate</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td>

Thank you email templated of this Action Page

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>thankYouTemplateRef</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td>

A reference to thank you email template of this ActionPage

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>live</strong></td>
<td valign="top"><a href="#boolean">Boolean</a>!</td>
<td>

Is live?

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>journey</strong></td>
<td valign="top">[<a href="#string">String</a>!]!</td>
<td>

List of steps in journey (DEPRECATED: moved under config)

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>config</strong></td>
<td valign="top"><a href="#json">Json</a>!</td>
<td>

Config JSON of this action page

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>campaign</strong></td>
<td valign="top"><a href="#campaign">Campaign</a>!</td>
<td>

Campaign this action page belongs to.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>org</strong></td>
<td valign="top"><a href="#org">Org</a>!</td>
<td>

Org the action page belongs to

</td>
</tr>
</tbody>
</table>

### PublicActionsResult

Result of actions query

<table>
<thead>
<tr>
<th align="left">Field</th>
<th align="right">Argument</th>
<th align="left">Type</th>
<th align="left">Description</th>
</tr>
</thead>
<tbody>
<tr>
<td colspan="2" valign="top"><strong>fieldKeys</strong></td>
<td valign="top">[<a href="#string">String</a>!]</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>list</strong></td>
<td valign="top">[<a href="#actioncustomfields">ActionCustomFields</a>]</td>
<td></td>
</tr>
</tbody>
</table>

### PublicCampaign

<table>
<thead>
<tr>
<th align="left">Field</th>
<th align="right">Argument</th>
<th align="left">Type</th>
<th align="left">Description</th>
</tr>
</thead>
<tbody>
<tr>
<td colspan="2" valign="top"><strong>id</strong></td>
<td valign="top"><a href="#int">Int</a>!</td>
<td>

Campaign id

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>externalId</strong></td>
<td valign="top"><a href="#int">Int</a></td>
<td>

External ID (if set)

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>name</strong></td>
<td valign="top"><a href="#string">String</a>!</td>
<td>

Internal name of the campaign

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>title</strong></td>
<td valign="top"><a href="#string">String</a>!</td>
<td>

Full, official name of the campaign

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>contactSchema</strong></td>
<td valign="top"><a href="#contactschema">ContactSchema</a>!</td>
<td>

Schema for contact personal information

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>config</strong></td>
<td valign="top"><a href="#json">Json</a>!</td>
<td>

Custom config map

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>stats</strong></td>
<td valign="top"><a href="#campaignstats">CampaignStats</a>!</td>
<td>

Campaign statistics

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>org</strong></td>
<td valign="top"><a href="#org">Org</a>!</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>actions</strong></td>
<td valign="top"><a href="#publicactionsresult">PublicActionsResult</a>!</td>
<td>

Fetch public actions

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">actionType</td>
<td valign="top"><a href="#string">String</a>!</td>
<td>

Return actions of this action type

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">limit</td>
<td valign="top"><a href="#int">Int</a>!</td>
<td>

Limit the number of returned actions, default is 10, max is 100)

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>targets</strong></td>
<td valign="top">[<a href="#target">Target</a>]</td>
<td></td>
</tr>
</tbody>
</table>

### PublicOrg

<table>
<thead>
<tr>
<th align="left">Field</th>
<th align="right">Argument</th>
<th align="left">Type</th>
<th align="left">Description</th>
</tr>
</thead>
<tbody>
<tr>
<td colspan="2" valign="top"><strong>name</strong></td>
<td valign="top"><a href="#string">String</a>!</td>
<td>

Organisation short name

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>title</strong></td>
<td valign="top"><a href="#string">String</a>!</td>
<td>

Organisation title (human readable name)

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>config</strong></td>
<td valign="top"><a href="#json">Json</a>!</td>
<td>

config

</td>
</tr>
</tbody>
</table>

### PublicTarget

<table>
<thead>
<tr>
<th align="left">Field</th>
<th align="right">Argument</th>
<th align="left">Type</th>
<th align="left">Description</th>
</tr>
</thead>
<tbody>
<tr>
<td colspan="2" valign="top"><strong>id</strong></td>
<td valign="top"><a href="#string">String</a>!</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>name</strong></td>
<td valign="top"><a href="#string">String</a>!</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>externalId</strong></td>
<td valign="top"><a href="#string">String</a>!</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>locale</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>area</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>fields</strong></td>
<td valign="top"><a href="#json">Json</a></td>
<td></td>
</tr>
</tbody>
</table>

### RequeueResult

<table>
<thead>
<tr>
<th align="left">Field</th>
<th align="right">Argument</th>
<th align="left">Type</th>
<th align="left">Description</th>
</tr>
</thead>
<tbody>
<tr>
<td colspan="2" valign="top"><strong>count</strong></td>
<td valign="top"><a href="#int">Int</a>!</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>failed</strong></td>
<td valign="top"><a href="#int">Int</a>!</td>
<td></td>
</tr>
</tbody>
</table>

### RootSubscriptionType

<table>
<thead>
<tr>
<th align="left">Field</th>
<th align="right">Argument</th>
<th align="left">Type</th>
<th align="left">Description</th>
</tr>
</thead>
<tbody>
<tr>
<td colspan="2" valign="top"><strong>actionPageUpserted</strong></td>
<td valign="top"><a href="#actionpage">ActionPage</a>!</td>
<td></td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">orgName</td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
</tbody>
</table>

### Service

<table>
<thead>
<tr>
<th align="left">Field</th>
<th align="right">Argument</th>
<th align="left">Type</th>
<th align="left">Description</th>
</tr>
</thead>
<tbody>
<tr>
<td colspan="2" valign="top"><strong>id</strong></td>
<td valign="top"><a href="#int">Int</a>!</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>name</strong></td>
<td valign="top"><a href="#servicename">ServiceName</a>!</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>host</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>user</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>path</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
</tbody>
</table>

### TargetEmail

<table>
<thead>
<tr>
<th align="left">Field</th>
<th align="right">Argument</th>
<th align="left">Type</th>
<th align="left">Description</th>
</tr>
</thead>
<tbody>
<tr>
<td colspan="2" valign="top"><strong>email</strong></td>
<td valign="top"><a href="#string">String</a>!</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>emailStatus</strong></td>
<td valign="top"><a href="#emailstatus">EmailStatus</a>!</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>error</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
</tbody>
</table>

### Tracking

Tracking codes

<table>
<thead>
<tr>
<th align="left">Field</th>
<th align="right">Argument</th>
<th align="left">Type</th>
<th align="left">Description</th>
</tr>
</thead>
<tbody>
<tr>
<td colspan="2" valign="top"><strong>source</strong></td>
<td valign="top"><a href="#string">String</a>!</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>medium</strong></td>
<td valign="top"><a href="#string">String</a>!</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>campaign</strong></td>
<td valign="top"><a href="#string">String</a>!</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>content</strong></td>
<td valign="top"><a href="#string">String</a>!</td>
<td></td>
</tr>
</tbody>
</table>

### User

<table>
<thead>
<tr>
<th align="left">Field</th>
<th align="right">Argument</th>
<th align="left">Type</th>
<th align="left">Description</th>
</tr>
</thead>
<tbody>
<tr>
<td colspan="2" valign="top"><strong>id</strong></td>
<td valign="top"><a href="#int">Int</a>!</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>email</strong></td>
<td valign="top"><a href="#string">String</a>!</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>phone</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>pictureUrl</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>jobTitle</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>apiToken</strong></td>
<td valign="top"><a href="#apitoken">ApiToken</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>isAdmin</strong></td>
<td valign="top"><a href="#boolean">Boolean</a>!</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>roles</strong></td>
<td valign="top">[<a href="#userrole">UserRole</a>!]!</td>
<td></td>
</tr>
</tbody>
</table>

### UserRole

<table>
<thead>
<tr>
<th align="left">Field</th>
<th align="right">Argument</th>
<th align="left">Type</th>
<th align="left">Description</th>
</tr>
</thead>
<tbody>
<tr>
<td colspan="2" valign="top"><strong>org</strong></td>
<td valign="top"><a href="#org">Org</a>!</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>role</strong></td>
<td valign="top"><a href="#string">String</a>!</td>
<td></td>
</tr>
</tbody>
</table>

## Inputs

### ActionInput

Custom field added to action. For signature it can be contact, for mail it can be subject and body

<table>
<thead>
<tr>
<th colspan="2" align="left">Field</th>
<th align="left">Type</th>
<th align="left">Description</th>
</tr>
</thead>
<tbody>
<tr>
<td colspan="2" valign="top"><strong>actionType</strong></td>
<td valign="top"><a href="#string">String</a>!</td>
<td>

Action Type

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>customFields</strong></td>
<td valign="top"><a href="#json">Json</a></td>
<td>

Custom fields added to action

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>donation</strong></td>
<td valign="top"><a href="#donationactioninput">DonationActionInput</a></td>
<td>

Donation payload

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>mtt</strong></td>
<td valign="top"><a href="#mttactioninput">MttActionInput</a></td>
<td>

MTT payload

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>testing</strong></td>
<td valign="top"><a href="#boolean">Boolean</a></td>
<td>

Test mode

</td>
</tr>
</tbody>
</table>

### ActionPageInput

ActionPage input

<table>
<thead>
<tr>
<th colspan="2" align="left">Field</th>
<th align="left">Type</th>
<th align="left">Description</th>
</tr>
</thead>
<tbody>
<tr>
<td colspan="2" valign="top"><strong>name</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td>

Unique NAME identifying ActionPage.

Does not have to exist, must be unique. Can be a 'technical' identifier
scoped to particular organization, so it does not have to change when the
slugs/names change (eg. some.org/1234). However, frontent Widget can
ask for ActionPage by it's current location.href (but without https://), in which case it is useful
to make this url match the real widget location.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>locale</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td>

2-letter, lowercase, code of ActionPage language

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>thankYouTemplate</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td>

Thank you email template of this ActionPage

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>supporterConfirmTemplate</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td>

Supporter confirm email template of this ActionPage

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>extraSupporters</strong></td>
<td valign="top"><a href="#int">Int</a></td>
<td>

Extra supporter count. If you want to add a number of signatories you have offline or kept in another system, you can specify the number here.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>config</strong></td>
<td valign="top"><a href="#json">Json</a></td>
<td>

JSON string containing Action Page config

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>delivery</strong></td>
<td valign="top"><a href="#boolean">Boolean</a></td>
<td>

Collected PII is processed even with no opt-in

</td>
</tr>
</tbody>
</table>

### AddKeyInput

<table>
<thead>
<tr>
<th colspan="2" align="left">Field</th>
<th align="left">Type</th>
<th align="left">Description</th>
</tr>
</thead>
<tbody>
<tr>
<td colspan="2" valign="top"><strong>name</strong></td>
<td valign="top"><a href="#string">String</a>!</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>public</strong></td>
<td valign="top"><a href="#string">String</a>!</td>
<td></td>
</tr>
</tbody>
</table>

### AddressInput

Address type which can hold different addres fields.

<table>
<thead>
<tr>
<th colspan="2" align="left">Field</th>
<th align="left">Type</th>
<th align="left">Description</th>
</tr>
</thead>
<tbody>
<tr>
<td colspan="2" valign="top"><strong>country</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td>

Country code (two-letter).

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>postcode</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td>

Postcode, in format correct for country locale

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>locality</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td>

Locality, which can be a city/town/village

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>region</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td>

Region, being province, voyevodship, county

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>street</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td>

Street name

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>streetNumber</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td>

Street number

</td>
</tr>
</tbody>
</table>

### CampaignInput

Campaign input

<table>
<thead>
<tr>
<th colspan="2" align="left">Field</th>
<th align="left">Type</th>
<th align="left">Description</th>
</tr>
</thead>
<tbody>
<tr>
<td colspan="2" valign="top"><strong>name</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td>

Campaign unchanging identifier

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>externalId</strong></td>
<td valign="top"><a href="#int">Int</a></td>
<td>

Campaign external_id. If provided, it will be used to find campaign. Can be used to rename a campaign

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>title</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td>

Campaign human readable title

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>contactSchema</strong></td>
<td valign="top"><a href="#contactschema">ContactSchema</a></td>
<td>

Schema for contact personal information

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>config</strong></td>
<td valign="top"><a href="#json">Json</a></td>
<td>

Custom config as stringified JSON map

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>actionPages</strong></td>
<td valign="top">[<a href="#actionpageinput">ActionPageInput</a>!]</td>
<td>

Action pages of this campaign

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>mtt</strong></td>
<td valign="top"><a href="#campaignmttinput">CampaignMttInput</a></td>
<td>

MTT configuration

</td>
</tr>
</tbody>
</table>

### CampaignMttInput

<table>
<thead>
<tr>
<th colspan="2" align="left">Field</th>
<th align="left">Type</th>
<th align="left">Description</th>
</tr>
</thead>
<tbody>
<tr>
<td colspan="2" valign="top"><strong>startAt</strong></td>
<td valign="top"><a href="#datetime">DateTime</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>endAt</strong></td>
<td valign="top"><a href="#datetime">DateTime</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>messageTemplate</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>testEmail</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
</tbody>
</table>

### ConfirmInput

<table>
<thead>
<tr>
<th colspan="2" align="left">Field</th>
<th align="left">Type</th>
<th align="left">Description</th>
</tr>
</thead>
<tbody>
<tr>
<td colspan="2" valign="top"><strong>code</strong></td>
<td valign="top"><a href="#string">String</a>!</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>email</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>objectId</strong></td>
<td valign="top"><a href="#int">Int</a></td>
<td></td>
</tr>
</tbody>
</table>

### ConsentInput

GDPR consent data structure

<table>
<thead>
<tr>
<th colspan="2" align="left">Field</th>
<th align="left">Type</th>
<th align="left">Description</th>
</tr>
</thead>
<tbody>
<tr>
<td colspan="2" valign="top"><strong>optIn</strong></td>
<td valign="top"><a href="#boolean">Boolean</a></td>
<td>

Has contact consented to receiving communication from widget owner? Null: not asked

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>leadOptIn</strong></td>
<td valign="top"><a href="#boolean">Boolean</a></td>
<td>

Opt in to the campaign leader

</td>
</tr>
</tbody>
</table>

### ContactInput

Contact information

<table>
<thead>
<tr>
<th colspan="2" align="left">Field</th>
<th align="left">Type</th>
<th align="left">Description</th>
</tr>
</thead>
<tbody>
<tr>
<td colspan="2" valign="top"><strong>name</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td>

Full name

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>firstName</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td>

First name (when you provide full name split into first and last)

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>lastName</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td>

Last name (when you provide full name split into first and last)

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>email</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td>

Email

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>phone</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td>

Contacts phone number

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>birthDate</strong></td>
<td valign="top"><a href="#date">Date</a></td>
<td>

Date of birth in format YYYY-MM-DD

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>address</strong></td>
<td valign="top"><a href="#addressinput">AddressInput</a></td>
<td>

Contacts address

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>nationality</strong></td>
<td valign="top"><a href="#nationalityinput">NationalityInput</a></td>
<td>

Nationality information

</td>
</tr>
</tbody>
</table>

### CustomFieldInput

Custom field with a key and value. Both are strings.

<table>
<thead>
<tr>
<th colspan="2" align="left">Field</th>
<th align="left">Type</th>
<th align="left">Description</th>
</tr>
</thead>
<tbody>
<tr>
<td colspan="2" valign="top"><strong>key</strong></td>
<td valign="top"><a href="#string">String</a>!</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>value</strong></td>
<td valign="top"><a href="#string">String</a>!</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>transient</strong></td>
<td valign="top"><a href="#boolean">Boolean</a></td>
<td>

Unused. To mark action_type/key as transient, use campaign.transient_actions list

</td>
</tr>
</tbody>
</table>

### DonationActionInput

<table>
<thead>
<tr>
<th colspan="2" align="left">Field</th>
<th align="left">Type</th>
<th align="left">Description</th>
</tr>
</thead>
<tbody>
<tr>
<td colspan="2" valign="top"><strong>schema</strong></td>
<td valign="top"><a href="#donationschema">DonationSchema</a></td>
<td>

Provide payload schema to validate, eg. stripe_payment_intent

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>amount</strong></td>
<td valign="top"><a href="#int">Int</a></td>
<td>

Provide amount of this donation, in smallest units for currency

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>currency</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td>

Provide currency of this donation

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>frequencyUnit</strong></td>
<td valign="top"><a href="#donationfrequencyunit">DonationFrequencyUnit</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>payload</strong></td>
<td valign="top"><a href="#json">Json</a>!</td>
<td></td>
</tr>
</tbody>
</table>

### EmailTemplateInput

<table>
<thead>
<tr>
<th colspan="2" align="left">Field</th>
<th align="left">Type</th>
<th align="left">Description</th>
</tr>
</thead>
<tbody>
<tr>
<td colspan="2" valign="top"><strong>name</strong></td>
<td valign="top"><a href="#string">String</a>!</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>locale</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>subject</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>html</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>text</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
</tbody>
</table>

### GenKeyInput

<table>
<thead>
<tr>
<th colspan="2" align="left">Field</th>
<th align="left">Type</th>
<th align="left">Description</th>
</tr>
</thead>
<tbody>
<tr>
<td colspan="2" valign="top"><strong>name</strong></td>
<td valign="top"><a href="#string">String</a>!</td>
<td></td>
</tr>
</tbody>
</table>

### MttActionInput

<table>
<thead>
<tr>
<th colspan="2" align="left">Field</th>
<th align="left">Type</th>
<th align="left">Description</th>
</tr>
</thead>
<tbody>
<tr>
<td colspan="2" valign="top"><strong>subject</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td>

Subject line

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>body</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td>

Body

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>targets</strong></td>
<td valign="top">[<a href="#string">String</a>!]!</td>
<td>

Target ids

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>files</strong></td>
<td valign="top">[<a href="#string">String</a>!]</td>
<td>

Files to attach (images allowed)

</td>
</tr>
</tbody>
</table>

### NationalityInput

<table>
<thead>
<tr>
<th colspan="2" align="left">Field</th>
<th align="left">Type</th>
<th align="left">Description</th>
</tr>
</thead>
<tbody>
<tr>
<td colspan="2" valign="top"><strong>country</strong></td>
<td valign="top"><a href="#string">String</a>!</td>
<td>

Nationality / issuer of id document

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>documentType</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td>

Document type

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>documentNumber</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td>

Document serial id/number

</td>
</tr>
</tbody>
</table>

### OrgInput

<table>
<thead>
<tr>
<th colspan="2" align="left">Field</th>
<th align="left">Type</th>
<th align="left">Description</th>
</tr>
</thead>
<tbody>
<tr>
<td colspan="2" valign="top"><strong>name</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td>

Name used to rename

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>title</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td>

Organisation title (human readable name)

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>contactSchema</strong></td>
<td valign="top"><a href="#contactschema">ContactSchema</a></td>
<td>

Schema for contact personal information

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>supporterConfirm</strong></td>
<td valign="top"><a href="#boolean">Boolean</a></td>
<td>

Email opt in enabled

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>supporterConfirmTemplate</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td>

Email opt in template name

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>doiThankYou</strong></td>
<td valign="top"><a href="#boolean">Boolean</a></td>
<td>

Only send thank you emails to opt-ins

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>config</strong></td>
<td valign="top"><a href="#json">Json</a></td>
<td>

Config

</td>
</tr>
</tbody>
</table>

### OrgUserInput

<table>
<thead>
<tr>
<th colspan="2" align="left">Field</th>
<th align="left">Type</th>
<th align="left">Description</th>
</tr>
</thead>
<tbody>
<tr>
<td colspan="2" valign="top"><strong>email</strong></td>
<td valign="top"><a href="#string">String</a>!</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>role</strong></td>
<td valign="top"><a href="#string">String</a>!</td>
<td></td>
</tr>
</tbody>
</table>

### SelectActionPage

<table>
<thead>
<tr>
<th colspan="2" align="left">Field</th>
<th align="left">Type</th>
<th align="left">Description</th>
</tr>
</thead>
<tbody>
<tr>
<td colspan="2" valign="top"><strong>campaignId</strong></td>
<td valign="top"><a href="#int">Int</a></td>
<td></td>
</tr>
</tbody>
</table>

### SelectCampaign

<table>
<thead>
<tr>
<th colspan="2" align="left">Field</th>
<th align="left">Type</th>
<th align="left">Description</th>
</tr>
</thead>
<tbody>
<tr>
<td colspan="2" valign="top"><strong>titleLike</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>orgName</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
</tbody>
</table>

### SelectKey

<table>
<thead>
<tr>
<th colspan="2" align="left">Field</th>
<th align="left">Type</th>
<th align="left">Description</th>
</tr>
</thead>
<tbody>
<tr>
<td colspan="2" valign="top"><strong>id</strong></td>
<td valign="top"><a href="#int">Int</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>active</strong></td>
<td valign="top"><a href="#boolean">Boolean</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>public</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
</tbody>
</table>

### SelectService

<table>
<thead>
<tr>
<th colspan="2" align="left">Field</th>
<th align="left">Type</th>
<th align="left">Description</th>
</tr>
</thead>
<tbody>
<tr>
<td colspan="2" valign="top"><strong>name</strong></td>
<td valign="top"><a href="#servicename">ServiceName</a></td>
<td></td>
</tr>
</tbody>
</table>

### SelectUser

Criteria to filter users

<table>
<thead>
<tr>
<th colspan="2" align="left">Field</th>
<th align="left">Type</th>
<th align="left">Description</th>
</tr>
</thead>
<tbody>
<tr>
<td colspan="2" valign="top"><strong>id</strong></td>
<td valign="top"><a href="#int">Int</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>email</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td>

Use % as wildcard

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>orgName</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td>

Exact org name

</td>
</tr>
</tbody>
</table>

### ServiceInput

<table>
<thead>
<tr>
<th colspan="2" align="left">Field</th>
<th align="left">Type</th>
<th align="left">Description</th>
</tr>
</thead>
<tbody>
<tr>
<td colspan="2" valign="top"><strong>name</strong></td>
<td valign="top"><a href="#servicename">ServiceName</a>!</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>host</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>user</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>password</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>path</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
</tbody>
</table>

### StripePaymentIntentInput

<table>
<thead>
<tr>
<th colspan="2" align="left">Field</th>
<th align="left">Type</th>
<th align="left">Description</th>
</tr>
</thead>
<tbody>
<tr>
<td colspan="2" valign="top"><strong>amount</strong></td>
<td valign="top"><a href="#int">Int</a>!</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>currency</strong></td>
<td valign="top"><a href="#string">String</a>!</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>paymentMethodTypes</strong></td>
<td valign="top">[<a href="#string">String</a>!]</td>
<td></td>
</tr>
</tbody>
</table>

### StripeSubscriptionInput

<table>
<thead>
<tr>
<th colspan="2" align="left">Field</th>
<th align="left">Type</th>
<th align="left">Description</th>
</tr>
</thead>
<tbody>
<tr>
<td colspan="2" valign="top"><strong>amount</strong></td>
<td valign="top"><a href="#int">Int</a>!</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>currency</strong></td>
<td valign="top"><a href="#string">String</a>!</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>frequencyUnit</strong></td>
<td valign="top"><a href="#donationfrequencyunit">DonationFrequencyUnit</a>!</td>
<td></td>
</tr>
</tbody>
</table>

### TargetEmailInput

<table>
<thead>
<tr>
<th colspan="2" align="left">Field</th>
<th align="left">Type</th>
<th align="left">Description</th>
</tr>
</thead>
<tbody>
<tr>
<td colspan="2" valign="top"><strong>email</strong></td>
<td valign="top"><a href="#string">String</a>!</td>
<td></td>
</tr>
</tbody>
</table>

### TargetInput

<table>
<thead>
<tr>
<th colspan="2" align="left">Field</th>
<th align="left">Type</th>
<th align="left">Description</th>
</tr>
</thead>
<tbody>
<tr>
<td colspan="2" valign="top"><strong>name</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>externalId</strong></td>
<td valign="top"><a href="#string">String</a>!</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>locale</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>area</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>fields</strong></td>
<td valign="top"><a href="#json">Json</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>emails</strong></td>
<td valign="top">[<a href="#targetemailinput">TargetEmailInput</a>!]</td>
<td></td>
</tr>
</tbody>
</table>

### TrackingInput

Tracking codes, utm medium/campaign/source default to 'unknown', content to empty string

<table>
<thead>
<tr>
<th colspan="2" align="left">Field</th>
<th align="left">Type</th>
<th align="left">Description</th>
</tr>
</thead>
<tbody>
<tr>
<td colspan="2" valign="top"><strong>source</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>medium</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>campaign</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>content</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>location</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td>

Action page location. Url from which action is added. Must contain schema, domain, (port), pathname

</td>
</tr>
</tbody>
</table>

### UserDetailsInput

<table>
<thead>
<tr>
<th colspan="2" align="left">Field</th>
<th align="left">Type</th>
<th align="left">Description</th>
</tr>
</thead>
<tbody>
<tr>
<td colspan="2" valign="top"><strong>pictureUrl</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>jobTitle</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>phone</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
</tbody>
</table>

## Enums

### ActionPageStatus

<table>
<thead>
<th align="left">Value</th>
<th align="left">Description</th>
</thead>
<tbody>
<tr>
<td valign="top"><strong>STANDBY</strong></td>
<td>

This action page is ready to receive first action or is stalled for over 1 year

</td>
</tr>
<tr>
<td valign="top"><strong>ACTIVE</strong></td>
<td>

This action page received actions lately

</td>
</tr>
<tr>
<td valign="top"><strong>STALLED</strong></td>
<td>

This action page did not receive actions lately

</td>
</tr>
</tbody>
</table>

### ContactSchema

<table>
<thead>
<th align="left">Value</th>
<th align="left">Description</th>
</thead>
<tbody>
<tr>
<td valign="top"><strong>BASIC</strong></td>
<td></td>
</tr>
<tr>
<td valign="top"><strong>POPULAR_INITIATIVE</strong></td>
<td></td>
</tr>
<tr>
<td valign="top"><strong>ECI</strong></td>
<td></td>
</tr>
<tr>
<td valign="top"><strong>IT_CI</strong></td>
<td></td>
</tr>
</tbody>
</table>

### DonationFrequencyUnit

<table>
<thead>
<th align="left">Value</th>
<th align="left">Description</th>
</thead>
<tbody>
<tr>
<td valign="top"><strong>ONE_OFF</strong></td>
<td></td>
</tr>
<tr>
<td valign="top"><strong>WEEKLY</strong></td>
<td></td>
</tr>
<tr>
<td valign="top"><strong>MONTHLY</strong></td>
<td></td>
</tr>
<tr>
<td valign="top"><strong>DAILY</strong></td>
<td></td>
</tr>
</tbody>
</table>

### DonationSchema

<table>
<thead>
<th align="left">Value</th>
<th align="left">Description</th>
</thead>
<tbody>
<tr>
<td valign="top"><strong>STRIPE_PAYMENT_INTENT</strong></td>
<td></td>
</tr>
</tbody>
</table>

### EmailStatus

<table>
<thead>
<th align="left">Value</th>
<th align="left">Description</th>
</thead>
<tbody>
<tr>
<td valign="top"><strong>NONE</strong></td>
<td></td>
</tr>
<tr>
<td valign="top"><strong>DOUBLE_OPT_IN</strong></td>
<td></td>
</tr>
<tr>
<td valign="top"><strong>BOUNCE</strong></td>
<td></td>
</tr>
<tr>
<td valign="top"><strong>BLOCKED</strong></td>
<td></td>
</tr>
<tr>
<td valign="top"><strong>SPAM</strong></td>
<td></td>
</tr>
<tr>
<td valign="top"><strong>UNSUB</strong></td>
<td></td>
</tr>
</tbody>
</table>

### Queue

<table>
<thead>
<th align="left">Value</th>
<th align="left">Description</th>
</thead>
<tbody>
<tr>
<td valign="top"><strong>EMAIL_SUPPORTER</strong></td>
<td></td>
</tr>
<tr>
<td valign="top"><strong>CUSTOM_SUPPORTER_CONFIRM</strong></td>
<td></td>
</tr>
<tr>
<td valign="top"><strong>CUSTOM_ACTION_CONFIRM</strong></td>
<td></td>
</tr>
<tr>
<td valign="top"><strong>CUSTOM_ACTION_DELIVER</strong></td>
<td></td>
</tr>
<tr>
<td valign="top"><strong>SQS</strong></td>
<td></td>
</tr>
<tr>
<td valign="top"><strong>WEBHOOK</strong></td>
<td></td>
</tr>
</tbody>
</table>

### ServiceName

<table>
<thead>
<th align="left">Value</th>
<th align="left">Description</th>
</thead>
<tbody>
<tr>
<td valign="top"><strong>SES</strong></td>
<td></td>
</tr>
<tr>
<td valign="top"><strong>SQS</strong></td>
<td></td>
</tr>
<tr>
<td valign="top"><strong>MAILJET</strong></td>
<td></td>
</tr>
<tr>
<td valign="top"><strong>SMTP</strong></td>
<td></td>
</tr>
<tr>
<td valign="top"><strong>WORDPRESS</strong></td>
<td></td>
</tr>
<tr>
<td valign="top"><strong>STRIPE</strong></td>
<td></td>
</tr>
<tr>
<td valign="top"><strong>TEST_STRIPE</strong></td>
<td></td>
</tr>
<tr>
<td valign="top"><strong>WEBHOOK</strong></td>
<td></td>
</tr>
<tr>
<td valign="top"><strong>SYSTEM</strong></td>
<td></td>
</tr>
<tr>
<td valign="top"><strong>SUPABASE</strong></td>
<td></td>
</tr>
</tbody>
</table>

### Status

<table>
<thead>
<th align="left">Value</th>
<th align="left">Description</th>
</thead>
<tbody>
<tr>
<td valign="top"><strong>SUCCESS</strong></td>
<td>

Operation completed succesfully

</td>
</tr>
<tr>
<td valign="top"><strong>CONFIRMING</strong></td>
<td>

Operation awaiting confirmation

</td>
</tr>
<tr>
<td valign="top"><strong>NOOP</strong></td>
<td>

Operation had no effect (already done)

</td>
</tr>
</tbody>
</table>

## Scalars

### Boolean

The `Boolean` scalar type represents `true` or `false`.

### Date

The `Date` scalar type represents a date. The Date appears in a JSON
response as an ISO8601 formatted string, without a time component.

### DateTime

The `DateTime` scalar type represents a date and time in the UTC
timezone. The DateTime appears in a JSON response as an ISO8601 formatted
string, including UTC timezone ("Z"). The parsed date and time string will
be converted to UTC if there is an offset.

### ID

The `ID` scalar type represents a unique identifier, often used to refetch an object or as key for a cache. The ID type appears in a JSON response as a String; however, it is not intended to be human-readable. When expected as an input type, any string (such as `"4"`) or integer (such as `4`) input value will be accepted as an ID.

### Int

The `Int` scalar type represents non-fractional signed whole numeric values. Int can represent values between -(2^31) and 2^31 - 1.

### Json

### NaiveDateTime

The `Naive DateTime` scalar type represents a naive date and time without
timezone. The DateTime appears in a JSON response as an ISO8601 formatted
string.

### String

The `String` scalar type represents textual data, represented as UTF-8 character sequences. The String type is most often used by GraphQL to represent free-form human-readable text.


## Interfaces


### ActionPage

<table>
<thead>
<tr>
<th align="left">Field</th>
<th align="right">Argument</th>
<th align="left">Type</th>
<th align="left">Description</th>
</tr>
</thead>
<tbody>
<tr>
<td colspan="2" valign="top"><strong>id</strong></td>
<td valign="top"><a href="#int">Int</a>!</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>locale</strong></td>
<td valign="top"><a href="#string">String</a>!</td>
<td>

Locale for the widget, in i18n format

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>name</strong></td>
<td valign="top"><a href="#string">String</a>!</td>
<td>

Name where the widget is hosted

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>thankYouTemplate</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td>

Thank you email templated of this Action Page

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>thankYouTemplateRef</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td>

A reference to thank you email template of this ActionPage

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>live</strong></td>
<td valign="top"><a href="#boolean">Boolean</a>!</td>
<td>

Is live?

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>journey</strong></td>
<td valign="top">[<a href="#string">String</a>!]!</td>
<td>

List of steps in journey (DEPRECATED: moved under config)

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>config</strong></td>
<td valign="top"><a href="#json">Json</a>!</td>
<td>

Config JSON of this action page

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>campaign</strong></td>
<td valign="top"><a href="#campaign">Campaign</a>!</td>
<td>

Campaign this action page belongs to.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>org</strong></td>
<td valign="top"><a href="#org">Org</a>!</td>
<td>

Org the action page belongs to

</td>
</tr>
</tbody>
</table>

### Campaign

<table>
<thead>
<tr>
<th align="left">Field</th>
<th align="right">Argument</th>
<th align="left">Type</th>
<th align="left">Description</th>
</tr>
</thead>
<tbody>
<tr>
<td colspan="2" valign="top"><strong>id</strong></td>
<td valign="top"><a href="#int">Int</a>!</td>
<td>

Campaign id

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>externalId</strong></td>
<td valign="top"><a href="#int">Int</a></td>
<td>

External ID (if set)

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>name</strong></td>
<td valign="top"><a href="#string">String</a>!</td>
<td>

Internal name of the campaign

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>title</strong></td>
<td valign="top"><a href="#string">String</a>!</td>
<td>

Full, official name of the campaign

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>contactSchema</strong></td>
<td valign="top"><a href="#contactschema">ContactSchema</a>!</td>
<td>

Schema for contact personal information

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>config</strong></td>
<td valign="top"><a href="#json">Json</a>!</td>
<td>

Custom config map

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>stats</strong></td>
<td valign="top"><a href="#campaignstats">CampaignStats</a>!</td>
<td>

Campaign statistics

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>org</strong></td>
<td valign="top"><a href="#org">Org</a>!</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>actions</strong></td>
<td valign="top"><a href="#publicactionsresult">PublicActionsResult</a>!</td>
<td>

Fetch public actions

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">actionType</td>
<td valign="top"><a href="#string">String</a>!</td>
<td>

Return actions of this action type

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">limit</td>
<td valign="top"><a href="#int">Int</a>!</td>
<td>

Limit the number of returned actions, default is 10, max is 100)

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>targets</strong></td>
<td valign="top">[<a href="#target">Target</a>]</td>
<td></td>
</tr>
</tbody>
</table>

### Org

<table>
<thead>
<tr>
<th align="left">Field</th>
<th align="right">Argument</th>
<th align="left">Type</th>
<th align="left">Description</th>
</tr>
</thead>
<tbody>
<tr>
<td colspan="2" valign="top"><strong>name</strong></td>
<td valign="top"><a href="#string">String</a>!</td>
<td>

Organisation short name

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>title</strong></td>
<td valign="top"><a href="#string">String</a>!</td>
<td>

Organisation title (human readable name)

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>config</strong></td>
<td valign="top"><a href="#json">Json</a>!</td>
<td>

config

</td>
</tr>
</tbody>
</table>

### Target

<table>
<thead>
<tr>
<th align="left">Field</th>
<th align="right">Argument</th>
<th align="left">Type</th>
<th align="left">Description</th>
</tr>
</thead>
<tbody>
<tr>
<td colspan="2" valign="top"><strong>id</strong></td>
<td valign="top"><a href="#string">String</a>!</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>name</strong></td>
<td valign="top"><a href="#string">String</a>!</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>externalId</strong></td>
<td valign="top"><a href="#string">String</a>!</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>locale</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>area</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>fields</strong></td>
<td valign="top"><a href="#json">Json</a></td>
<td></td>
</tr>
</tbody>
</table>
Done in 0.18s.
