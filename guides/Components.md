# Components and subprocesses

Proca server runs various internal processes.

## Web server

Module: `ProcaWeb.Router`, `ProcaWeb.Endpoint`

The web server serving API, webhooks and a minimal user registration UI (disabled on production).

## Stats

Module: `Proca.Server.Stats`

Calculates the statistics for all action pages and all campaigns every `SYNC_INTERVAL` ms.
The calculation is deduplicating on supporter fingerprint

The calculation scans ALL actions in database.

Besides, it receives metrics about real-time actions between intervals, and adjusts the counter. Caveat: in this case, if a metric came from a duplicate action, the counter will be incremented; this error will be removed on next interval re-calculation.

## MTT 

Module: `Proca.Server.MTT` and `Proca.Server.MTTWorker`

Sends the mail to target emails. The MTT process runs the deduplication (calculates `dupe_rank`) on messages and runs a `MTTWorker` for each running MTT campaign.

The MTTWorker calculates how many messages should be send in proportion to duration of the campaign (2 week campaign, after end of 1st week, 50% of messages should have been sent) and sends them.

## Notify

Module: `Proca.Server.Notify`

Process which receives information about different events in the server, and triggers actions based on them.


## Queue topology

Module: `Proca.Pipes.Topology`

Configures the queues for all the Org, and runs enabled queue workers.

Reacts to RabbitMQ server availability - if it's not possible to connect, it shuts down all the workers, and checks every 5 minutes if RabbitMQ is back online - in which case workers are started again.

## Less important components

These processes exist to speed things up; provide a smart cache for various subsystems. 

### Encryption Key cache
Module: `Proca.Server.Keys`

Process which contains a dictionary of encryption keys for orgs. It also generates unique `nonce` values it is guaranteed they are not re-used if multiple actions are encrypted in parallel.

### Jwks certificates cache

Module: `Proca.Server.Jwks`

Holds JWKS certificates used to check authentication of API requests.

### ActionPage Status cache

Module: `Proca.ActionPage.Status`.

Stores statuses of action pages - whether they are active or stale, and what was
the last website url (based on `HTTP_REFERER`) where the action came in from.

### Template directory cache

Module: `Proca.Service.EmailTemplateDirectory`

Stores the compiled email templates, as well as lists of template names in remote APIs (Mailjet, SES).

### User API token status cache

Module: `Proca.Users.Status`

Stores `token_last_seen` timestamps to `user_tokens` table.
    
