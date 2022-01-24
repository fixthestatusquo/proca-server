# Action data processing

Proca provides a versatile system for processing action data, which supports:

1. Confirmation - whether PII needs to be confirmed by user (user
   clicks on email link to confirm or reject their submission), or action should be
   moderated (open letter signatory, or mail to target moderation for content),
   Proca can put supporter and action data in _confirming_ stage, before they
   are delivered.
   
   Out of the box, Proca supports sending _supporter confirm_ emails and confirming
   supporter data this way. However, you can _plug in_ to this mechanism and
   provide your own Supporter or Action confirmation mechanism. For instance,
   you could build a volunteer based, crowd-source moderation app that checks
   content of submitted actions (like signups, or mail to targets).


2. Delivery - Actions can be delivered using internal and external mechanisms,
   all running in parallel and with batching for performance.
   The Action can be delivered by:
   - Thank you e-mail with templated, personalized content (including
     `firstName`, or custom field replacement)
   - Forwarding to CRM - using a decrypting gateway under your control, you can deliver decrypted member data to CRM of choice.
   - Forwarding to SQS - where you can do whatever SQS is used for!
   - Stored in your Org's queue (AMQP), where you can fetch actions from and process in a custom way. 

## Queues

Supporter and action data is based on AMQP queues (we use Rabbitmq). `Proca.Pipes.Topology` server is responsible to set up and maintain the queue setup. The stages of processing data is implemented by `Proca.Server.Processing` server.

For each stages of processing, actions can land in custom queues. If you enable the custom queues for some stages, you are responsible to do something with the messages in the respective queue, otherwise they will be stuck at that stage.

- `cus.X.confirm.supporter` - queue for actions with supporter put in confirming state
- `cus.X.confirm.action` - queue for actions with action put in supporter state
- `cus.X.deliver` - queue for delivering actions to final endpoint

You can enable the custom queues by setting the respective Org setting: `customSupporterConfirm`, `customActionConfirm`, `customActionDeliver`.


## Action message

Because the backbone of action processing system is RabbitMQ, the actions are AMQP messages with actions serialized to JSON as payload. They contain basic action and supporter data received by `addActionContact` and `addAtion` APIs, as well as some redundant, supplementary information (eg. campaign title), so the recipient of the message does not have to look it up.

The v1 schema of action messages has following fields:

- `actionId` - the numeric id of the action 
- `action` - action data, similar to `action` API parameter. A map of:
  - `actionType` - action type as string 
  - `fields` - a list of custom fields. Each is a map with `key` and `value` fields.
  - `createdAt` - date time of action creation  
- `actionPageId` - id of action page / widget this action was collected through.
- `actionPage` - supplementary action page information, map of: 
  - `name` - name of action page
  - `locale` - action page locale 
  - `thankYouTemplateRef` - a code-name of thank you email assigned to that action page 
- `campaign` - supplementary campaign information, map of: 
  - `name` - shortname of the campaign 
  - `title` - title of the campaign 
  - `externalId` - an external id of campaign, if assigned
- `contact` - personal information of member doing the action:
  - `ref` - unique personal data fingerprint, can be used to deduplicate
  - `payload` - personal information serialized into JSON string 
  - `firstName` - first name of member, extracted from personal data
  - `email` - email of member, extracted from personal data
  - `area` - area of member, extracted from personal data 
  - `nonce` - (encryption only), nonce of encrypted payload
  - `publicKey` - (encryption only), public key of recipient
  - `signKey` - (encryption only), public key of signatory
- `tracking` - the utm paramters given on action creation:
  - `source`, `medium`, `campaign`, `content` - respective `utm_X` params.
  - `location` - approximate url of widget page (if known)
- `privacy` - information about GDPR consent for processing data and communication:
  - `communication` - true/false - member gave consent to receive mailings
  - `givenAt` - timestamp of consent (can differ from actions createdAt)

