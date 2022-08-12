# How to sync actions data

In this guide I will outline how to write an action synchronization mechanism from Proca Server to a CRM.

What will you need?

1. Your CRM API - you must know how your CRM stores contacts and actions, and what's the API to add, fetch, update these
2. Proca actions queue address and access credentials - you will fetch your actions as they come from an AMQP (RabbitMQ) queue.
3. Your favourite programming language and tools to create a microservice


## Step 1: modelling the data

Every CRM is different. The first step is to figure out how to store actions data from Proca in your CRM.

In Proca we have this data model:

- Supporter - represents a physical person, your supporter or member. This record contains personal information (email, names, address) you have collected, as well as GDPR consent/privacy information associated with the personal data. There can be many records for the Supporter, because it can happen they they create two signatures with a different address, however, we treat email as unique identifier and we also create `supporter.contactRef` which is an email hash which can be used to deduplicate as well.

- Action - represents an online action, such as petition, share, donation. It is always connected to a Supporter that has done that action, and there can be multiple actions per single Supporter. Action record contains a type (`actionType`) and dictionary of `customFields`. In case of  "user journey" with 3 steps, we will have 1 Supporter + up to 3-4 actions if they go through all steps a (most steps generate 1 action, but share step will send 2 actions `share_open` and `share_close`, this is why I wrote 3-4).

- ActionPage - represents a website where the action was taken. You can use multiple action pages, eg. one for english and second for french sub-page of the campaign, or a partner campaign page, in case "split consent" was used, and supporters selecected to subscribe also to your newsletter, besides the partner's.

- Campaign - represents the campaign. 

You need to figure out how to store these actions. Perhaps your CRM does not allow to store actions, just contacts. Then you will discard the actions or maybe use first one as a source for contact. If you can store actions, you might want to deduplicate supporter records into single contact record, where you merge their personal information (eg. overwriting previously entered postcode with the newer postcode). You can use the `privacy` data to determine how you will manage your subscription settings for that contact.

## Step 2: Start receiving actions

You will receive the url (most usually amqps://api.proca.app), queue name (something like `cus.123.deliver`, username and password). Use your favourite AMQP client library to read the action messages. To learn more how they look like, read [this guide](https://docs.proca.app/processing.html#action-message).

Always _ack_ the message you managed to sync to your CRM, so it's removed from the queue.

In case you encounter a problem or crash, simply _nack_ the message (if you crash, _nack_ is default behavior) - it will be re-delivered after a small time when it's kept aside in a dead letter queue. This lets you still read next messages, and a problematic message will not block the whole queue.

### In case you are using Node (Typescript/Javascript)

If you are using node, you can use `@proca/queue` ([github](https://github.com/fixthestatusquo/proca-server/tree/main/sdk/queue)) library which helps out with reading the action messages. It has some extras:
- properly handle parallel syncing
- properly handle closing of the channel in case of crashing
- decrypt optionally encrypted personal information using `@proca/crypto` library 


## Extra: handle double opt in and email bounces

There [are few types of double opt in](https://proca.app/guide/double-opt-in/) and in case of _Newsletter opt in_, you receive the action first, and then you receive the consent later, after the member clicks on the email link. 

In this scenario, you will:

1. receive the whole action with `privacy: {emailStatus: 'none'}` - which means the email has not been yet verified.
2. later you will receive an [event message](https://docs.proca.app/processing.html#event-message) which will let you update the contact to add the subscription. This event type is `supporter.email_status` because it tells you something about how to tread the email of contact.

You will also receive this event when something wrong happens to the email, such as it bounces, or is marked as "spam" by the member. In this case you should update the contact to remove their subscription, or you can remove the contact altogether as invalid.

Of course, you can only receive a bounce event if Proca is sending an email to supporter - a thank you or confirm email.
