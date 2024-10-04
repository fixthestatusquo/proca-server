# Confirm reminder

Action taken from the queue can have two kinds of records in the Level database.

- Action record - key: 'action + actionId', value: action;
- Retry record - key: 'retry+ actionId', value: retry date, attempts
- Done record - key: 'done + actionId', value: done (true if the action gets confirmed, false if not)

If the action gets confirmed or reminders have been sent max times, retry and the action record will be deleted.

## How it works

### 1. The Cron job runs every minute and goes through "retry" records in the Level database.

#### If retry record with max retries\* is found

- adds done record: false
- deletes action record
- deletes retry record

#### If the retry date is < today and there are fewer than max retries

- gets the action record from DB
- requeues the action to queueConfirm
- changes retry date and retries count in the retry record

### 2. syncQueue reads from queueConfirm, when action with dupe 0 found

looks for action record in DB, if found, then nothing, if new action: - creates action record - creates retry record

### 3. syncQueue reads from queueConfirmed\* when action found

- adds done: true record
- deletes action record
- deletes retry record

## Answer to the Ultimate Question of Life, the Universe, and Everything

If we successfully restart the service reminders will be sent to all supporters from the queueConfirm queue. They will receive max 3 reminders 2 and 3 days apart (as expected). We have a safety mechanism against sending more reminders.
**Problem**: we don't know when the service stopped working, so we may remind supporters from past campaigns. Can be solved by adding another condition - date > something

\*max retries value is 3 by default, can be defined in ENV

\*queueConfirm - cus.ORG_ID.confirm.supporter

\*queueConfirmed - cus.ORG_ID.confirmed
