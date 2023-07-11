# Components and subprocesses

Proca server runs various internal processes.

## Stats

Module: [Proca.Server.Stats](Proca.Server.Stats.html)

Calculates the statistics for all action pages and all campaigns every `SYNC_INTERVAL` ms.
The calculation is deduplicating on supporter fingerprint

The calculation scans ALL actions in database.

Besides, it receives metrics about real-time actions between intervals, and adjusts the counter. Caveat: in this case, if a metric came from a duplicate action, the counter will be incremented; this error will be removed on next interval re-calculation.


## Encryption Key process
Module: [Proca.Server.Keys](Proca.Server.Keys.html)

Process which contains a dictionary of encryption keys for orgs. It also generates unique `nonce` values it is guaranteed they are not re-used if multiple actions are encrypted in parallel.

## Jwks 

Module: [Proca.Server.Jwks](Proca.Server.Jwks.html)

Holds JWKS certificates used to check authentication of API requests.


## MTT 

Module: [Proca.Server.MTT](Proca.Server.MTT.html) and [Proca.Server.MTTWorker](Proca.Server.MTTWorker.html)

Sends the mail to target emails. The MTT process runs the deduplication (calculates `dupe_rank`) on messages and runs a `MTTWorker` for each running MTT campaign.

The MTTWorker calculates how many messages should be send in proportion to duration of the campaign (2 week campaign, after end of 1st week, 50% of messages should have been sent) and sends them.


## Notify

Module: [Proca.Server.Notify](Proca.Server.Notify.html)

Process which receives information about different events in the server, and triggers actions based on them.

## ActionPage Status

Module: [Proca.ActionPage.Status](Proca.ActionPage.Status.html).

Stores statuses of action pages - whether they are active or stale, and what was
the last website url (based on `HTTP_REFERER`) where the action came in from.


## Template directory 

Module: [Proca.Service.EmailTemplateDirectory](Proca.Service.EmailTemplateDirectory.html)

Stores the compiled email templates, as well as lists of template names in remote APIs (Mailjet, SES).

## User API token status

Module: [Proca.Users.Status](Proca.Users.Status.html)

Stores `token_last_seen` timestamps to `user_tokens` table.

## Queue topology

Module: [Proca.Pipes.Topology](Proca.Pipes.Topology.html)

Configures the queues for all the Org, and runs enabled queue workers.

Reacts to RabbitMQ server availability - if it's not possible to connect, it shuts down all the workers, and checks every 5 minutes if RabbitMQ is back online - in which case workers are started again.
