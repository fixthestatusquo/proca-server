# Mailchimp Sync

A syncer that reads RabbitMQ queue for actions and synces them to Mailchimp CRM.

## Build and install

- `yarn build`, `yarn publish`
- installs `mailchimp-sync` command into system



## Configuration

- `QUEUE_URL` - An AMQP url with credentials eg `amqp://user:password@localhost/proca_live`
- `AUTH_TOKEN` - Mailchip api key


Run with options:

```
-q a queue to read actions from
-t test sign-in (ping API)
-s list senders (from emails)
-e email - search member by email
-l get lists
-L break-down lists by language
-T audienceName audience name used as template for new lists 
-A audienceName - just add all to that audience
-U upsert list (-c listname) - clone a new list from tempalte list (`-T`)
-D subcribe after DOI - set consent to `pending` and wait for DOI to happen.
-O opt out as transactional - if opted out in proca, add "transaction email consent" in MC
-o only opt ins
-S skip campaigns
-P amqp prefetch count = count to sync in parallel
-k keystore
```

To just sync you would run with: `mailchimp-sync -q cus.264.deliver_t4f -P 5 -T 'T4F Test'`

- You need a `-T` - template list to be cloned. in MC you cannot just add a new list (you do not know how to configure it and there are many options). You must create it in UI.



### Example config for WWF

WWF has to mailchimp accounts, one for all campaigns, one for Together4Forests, but they share proca org.

- What we do is we create a new delivery queue: `cus.264.deliver_t4f` which has a routing key in RabbitMQ `*.together4forests` which matches all action types and just this campaign.
- We run one `mailchimp-sync` on this queue
- The other runs on normal `deliver` queue but with `-S together4forests` to skip this campaign.

