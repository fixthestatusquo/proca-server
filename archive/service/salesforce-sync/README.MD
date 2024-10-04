# Salesforce Sync

A syncer that reads RabbitMQ queue for actions and synces them to SalesForce CRM.

## Build and install

- `yarn build`, `yarn publish`
- installs `salesforce-sync` command into system

## Configuration

SaleForce url and credentails

- `SALESFORCE_URL` - https://eurogroupforanimals.my.salesforce.com/
- `AUTH_USER` - email of account
- `AUTH_PASSWORD` - password
- `AUTH_TOKEN` - api token (yes you need both)


- `QUEUE_URL` - An AMQP url with credentials eg `amqp://user:password@localhost/proca_live`
- `CAMPAIGN_RECORD_TYPE` - eg. `0120J00000079AEQAY` if salesforce is configured with a plugin which has a custom type for a campaign, put its record type id here. You must find it somewhere deep in SF admin panel (entity explorer or similar). I am no expert in this and found this id by plain luck.

Run with options: `salesforce-sync -q cus.320.deliver -l -O Opt_In__c -D -T`


```
 -h - show this help

 Diagnostics:
 -t - test sign in to SalesForce
 -c campaignName - fetch campaign info
 -e email - lookup contact and lead by email


 Syncing:
 -q - run sync of queue, with these options:
 -u - queue url amqps://user:password@api.proca.app/proca_live (or QUEUE_URL env)
 -l - add as leads not contacts
 -L - language custom field
 -O - Opt in custom field (eg Email_Opt_In__c)
 -D - double opt in (set opt in only if supporter has DOI)
 -T - use proca campaign title instead of name
```

- Some orgs want to store supporters as sales leads, some as campaign contacts. I think later is saner, but some wish to have them as leads. Use `-l` to switch.


- Every SF is different. Opt in field, language field are custom fields, not built in. You need to pass their names with `-O`, `-L`




