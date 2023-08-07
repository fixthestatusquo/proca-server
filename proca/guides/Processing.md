# Action data processing

Proca provides a versatile system for processing action data, which supports:

## Confirmation

Confirmation - whether PII/action needs to be confirmed by user (user clicks
on email link to confirm or reject their submission), or action should be
moderated (open letter signatory, or mail to target moderation for content -
in which case a campaigner approbes the action somehow, via UI or email
link). When using confirmation, actions wait in _confirming_ stage, before
they are delivered. Both `Proca.Action` and `Proca.Supporter` can be put into
_confirming_ state.

   
   ```
   [ New action ] --> [ Wait: Supporter confirmed? ] --> [ Wait: Action confirmed? ] --> [ Deliver! ]
                              (optional)                          (optional)
   actions go to queue:          V                                   V                        V
                                 V                                   V                        V
   Proca internal queue:    wrk.ORG_ID.email.supporter            (none)              wrk.ORG_ID.{email.supporter,sqs,webhook}       
   Customer queue:          cus.ORG_ID.confirm.supporter  cus.ORG_ID.confirm.action   cus.ORG_ID.deliver
   ```
   
_(See `Proca.Stage.Processing` for a schema of a state machine of processing statuses on Supporter and Action)_
   
Out of the box, Proca supports sending _supporter confirm_ emails and
confirming supporter data this way. This is sometimes called action DOI, but
it boils down to proving that supporter data _is real_, because someone
received an email and clicked on the link. After a Supporter is confirmed,
all other actions added to that supporter (via `addAction`, eg. Share) will
be assumed to be confirmed too.

If you do not want to use the default mechanism to send an email to _confirm
a supporter_, you can build your own mechanism (push notification). In that
case you will want to _disable_ the email sending, and _enable_ a custom
queue where you will read actions put into _confirming_ state. You will then
send your push notification and if user clicks the special link, the
supporter will be confirmed (and all actions associated with it like
signature or share).

The special link to confirm a supporter has a form: `/link/s/${action_id}/accept/${contact_ref}`.

The other special link to _reject_ a supporter can be used to mark a _confirming_ Supporter as _rejected_ ("It wasn't me!" link). The form is: `/link/s/${action_id}/reject/${contact_ref}`

Proca also supports confirming of each action separately (_action confirmation_), this was not used much in real world. However, in this case we don't care if the supporter email is real, we care more about the action content, for example, custom fields, MTT body, attached file. We would put actions in a wait/confirming state until such actions are moderated/checked and accepted. **Partly unimplemented**: There is no api or link format to confirm or reject a particular action (could be easily added but needs a proper use-case).

## Delivery

Delivery of actions means that action is ready to be served and consumed. Actions can be delivered using internal and external mechanisms.
   
The Action can be delivered by:
- Thank you e-mail with templated, personalized content (including
    `firstName`, or custom field replacement)
- Forwarding to CRM - using we webhook, or a custom queue + special (decrypting) gateway microservice which synces actions into CRM of choice.
- Forwarding to SQS - where you can do whatever SQS is used for!

## Email DOI or communication consent

The Email DOI, which is double consenting to receiving emails, is modeled separately from this mechanism, and is described in `Proca.Supporter`.

However, a bouncing email will mark Supporter as rejected (same as if they would click "It wasn't me!" link).


## Queues

Supporter and action data is based on AMQP queues (we use Rabbitmq). `Proca.Pipes.Topology` server is responsible to set up and maintain the queue setup. The stages of processing data is implemented by `Proca.Stage.Processing` server.

Queues allow us to process actions in parallel and with batching for performance, as well as provide retry mechanism if actions are not ACK-ed.

For each stages of processing, actions can land in custom queues. If you enable the custom queues for some stages, you are responsible to do something with the messages in the respective queue, otherwise they will be stuck at that stage.

- `cus.X.confirm.supporter` - queue for actions with supporter put in confirming state
- `cus.X.confirm.action` - queue for actions with action put in supporter state
- `cus.X.deliver` - queue for delivering actions to final endpoint

You can enable the custom queues by setting the respective Org setting: `customSupporterConfirm`, `customActionConfirm`, `customActionDeliver`.

- `org.X.fail` - for any failed processing (or when you nack/don't ack a message) the message will land in a fail queue for 30 sec before being redelivered to the queue again. This mechanism prevents a fast retry loops. However, the failed messages are _not_ removed even if they are retried many times, which has to be carefully handled by consumer. For example, if re-delivery count is high, you might consider to drop a message. If reading a message has non-idempotent side effect, consider storing information about particular id being processed. This can let you avoid sending multiple emails in case you sent the email during action processing, but then encountered an error and failed to ack the message.


## Action message

Because the backbone of action processing system is RabbitMQ, the actions are AMQP messages with actions serialized to JSON as payload. They contain basic action and supporter data received by `addActionContact` and `addAtion` APIs, as well as some redundant, supplementary information (eg. campaign title), so the recipient of the message does not have to look it up.

The AMQP message is routed with a key: `ACTION_TYPE.CAMPAIGN_NAME` (where action type is `actionType` given on action creation, and campaign name is a campaign short name).

The current schema of action data is version 2. Version 1 is deprecated and you should not expect to receive it for new deployments.

You can find a TypeScript [definition of Action Message v2](https://github.com/fixthestatusquo/proca-server/blob/main/sdk/queue/src/actionMessage.ts#L106) in `@proca/queue` package. The description of [encrypted personal information structure](https://github.com/fixthestatusquo/proca-server/blob/main/sdk/crypto/src/types.ts#L27) is defined in `@proca/crypto`.

Below is the explanation for content under each key in the Action data map. Nested lists describe keys of a nested maps. It is explicitly noted when a value is an array of maps, 


- `schema` - always `proca:action:2`
- `actionId` - the numeric id of the action 
- `action` - action data, similar to `action` API parameter. A map of:
  - `actionType` - action type as string 
  - `fields` - a map of custom fields. Keys are strings, values are either: string, number, array of strings, array of numbers.
  - `createdAt` - timestamp (ISO8601) of action creation
  - `testing` - boolean - true if action was added with `testing: true` parameter 
- `actionPageId` - id of action page / widget this action was collected through.
- `actionPage` - supplementary action page information, map of: 
  - `name` - name of action page
  - `locale` - action page locale (in short or long format, eg: `de` - German, `de_AT` - Austrian German)
  - `thankYouTemplate` - a string identifier of thank you email assigned to that action page (can be null)
  - `supporterConfirmTemplate` - a string identifier of supporter confirmation email assigned to that action page (can be null)
- `campaign` - supplementary campaign information, map of: 
  - `name` - shortname of the campaign 
  - `title` - title of the campaign 
  - `externalId` - an external numeric id of campaign, if assigned
  - `contactSchema` - type of collected personal data, `basic`, `eci` or others
- `contact` - personal information of member doing the action (the content depends on campaign type and what PII is collected):
  - `contactRef` - unique personal data fingerprint, can be used to de-duplicate (always present)
  - `dupeRank` - rank of extra occurrence of that contact taking action in this campaign (0 - first time, >0 - "duplicate")
  - `email` - email of member (always present)
  - `firstName` - first name of member (always present)
  - `lastName`
  - `postcode`
  - `country`
  - `address` - extra address details, null if not collected, map of:
    - `street` - street name 
    - `street_number` - street number if collected separately (alternatively it's just part of `street`)
    - `locality` - city, town, village
    - `region` - province, county, other administrative division area bigger then locality but smaller then country
- `personalInfo` - if PII is encrypted, it will not be adde to `contact` map but passed in following fields:
  - `payload` - an encrypted JSON in Base64url encoding, containing the personal data that is passed in `contact` map when encryption is not used.
  - `nonce` - nonce of encrypted payload
  - `encryptKey` - public key of recipient (encryption key of your org), map of:
    - `id` - key id in proca server 
    - `public` - public part of key, encoded with Base64url
  - `signKey` - public key of signatory (Proca server), map of:
    - `id` - key id in proca server 
    - `public` - public part of key, encoded with Base64url
- `tracking` - the utm parameters given on action creation:
  - `source`, `medium`, `campaign`, `content` - respective `utm_X` params.
  - `location` - approximate url of widget page (if Proca server was able to determine it)
- `privacy` - information about GDPR consent for processing data and communication:
  - `optIn` - true/false - member gave consent to receive mailings
  - `givenAt` - timestamp (ISO8601) of consent (can differ from actions createdAt)
  - `withConsent` - `true` if this action carried a consent, `false` if this action was attached to existing contact info, but did not have consent itself (eg. share step after signing petition)
  - `emailStatus` - mailability of the email, one of:
    - `null` - standard status after email was collected, probably can be used for mailing
    - `doubleOptIn` - the member explicitly gave consent to use this email by clicking a confirmation link in an email 
    - `bounce`, `blocked`, `spam`, `unsub` - the email should not be used for mailing, because it either bounced/was blocked, or the member marked you as spam, or unsubscribed (using Gmail unsubscribe button for example)
  - `emailStatusChange` - timestamp (ISO8601) when was the last status change of email (when double opt in happened, or when the email started bouncing)



## Event message 

Proca produces additional event messages (if enabled for organization with `customEventDeliver` flag). There is a number of events that are generated on creation/change of data relating to your campaign. Always check the `schema` and `eventType` field to discard (ack) event messages you do not want to process.

### event types 

#### Supporter email status changed 

You will receive this message if email status of a supporter changes. It can happen *after* the action was already synced to your CRM - for example, when they click the double opt in link (then the new status is `double_opt_in`) or if Proca Server tried to email them, end that email bounced. Handle this event to manage the subscription status in your CRM.

Message structure:

- `schema` - always `proca:event:2`
- `eventType` - is `supporter.email_status`
- `timestamp` - event timestamp (ISO8601)
- `supporter` - data of supporter whos status changed, map of:
  - `contact` - same as in action message
  - `privacy` - same as in action message (contains new `emailStatus`)
  - `personalInfo` - same as in action message


#### Campaign updated 

Message structure 

- `schema` - always `proca:event:2`
- `eventType` - is `system.campaign_updated`
- `timestamp` - event timestamp (ISO8601)
- `campaignId` - id of campaign 
- `campaign` - campaign details, map of:
  - `id`
  - `name`
  - `title`
  - `contactSchema`
  - `config` - custom map


## Built-in workers

### Email the supporter worker

- Reads queue: `wrk.ORG_ID.email.supporter`
- This queue gets messages from 2 exchanges:
  - `org.ORG_ID.confirm.supporter` - actions with `stage="supporter_confirm"` and routing key `campaign.action_type`
  - `org.ORG_ID.deliver` - actions with `stage="deliver"` and routing key `campaign.action_type`
  
This worker sends emails to supporters in two cases. The supporter confirmation (action doi) it will send the template set as `actionPage.supporterConfirmTemplate` or `org.supporterConfirmTemplate`, whichever is available.

After supporter is accepted, or if no supporter confirm is performed, instantly, worker will send the thank you email. Template in `actionPage.thankYouTemplate` is used, if set. If `Org.doiThankYou` is set for the org, thank you emails will only be sent to supporters who have opted in to communication. This can be used to collect newsletter doi by putting `{{doiLink}}` in that thank you email. Supporters who did not give communication consent, will not get any email at all. If you just want to hide the `{{doiLink}}` from those who have not opted i, but send thank you email to everyone, use `{{#privacy.optIn}}Click this {{doiLink}}.{{/privacy.optIn}}`.

The emails will only be sent for actions with supporter - added via API `addActionContact`, not `addAction`(so not for `share` action).

The `Org.emailFrom` must be set for any emails to be sent.

The worker will only run for orgs collecting data, not others that data is shared with.

It will use the `Proca.Service` set as  `emailBackend` configured for the org collecting action.




