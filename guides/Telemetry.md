# Telemetry / Prometheus Metrics

Metrics are emitted via `:telemetry.execute/3`, plus Phoenix/Plug and Ecto telemetry, and
exposed as Prometheus metrics on the port configured by
`config :proca, ProcaWeb.Telemetry, port: 9568` (default `9568`).

Namespaces:

- **`web.duration`** — full HTTP request processing duration
- **`api.*`** — call counts / duration for the main API operations (`addAction`, `addActionContact`, supporter-count widget)
- **`sql.*`** — Ecto database query timings (execution, decode, connection-queue wait)
- **`mtt.pacing.*`** — drip delivery worker (runs every ~3 minutes, per campaign via `MTTWorker`) plus RabbitMQ delivery outcomes
- **`mtt.throttle.*`** — hourly per-target scheduler lifecycle (`MTTScheduler`, launched by `MTTHourlyCron`)
- **`email.*`** — transactional email send lag (`supporter_confirm`, `thank_you`) and `reminder_confirm` clicks
 - **`mailer.*`** — email provider delivery results (all providers) and webhook events/bounces (`mailjet`, `brevo`)
- **`webhook.*`** — outbound webhook delivery results (`Proca.Stage.Webhook`)


## API / HTTP metrics

Emitted by `Plug.Telemetry` in `ProcaWeb.Endpoint`, `ProcaWeb.Resolvers.Action.add_action_contact/3`
and `add_action/3`, and `ProcaWeb.Resolvers.Campaign.stats/3` (`supporter_count`).

| Metric                            | Type         | Tags | Description                                                              |
|-----------------------------------|--------------|------|--------------------------------------------------------------------------|
| `web.duration`                    | Distribution | —    | Full HTTP request processing time (ms), from `Plug.Telemetry`            |
| `api.add_action_contact.duration` | Distribution | —    | GraphQL resolver duration (ms) for `addActionContact`; its `_count` series is the call count |
| `api.add_action.count`            | Counter      | —    | Number of `addAction` calls                                              |
| `api.supporter_count.count`       | Counter      | —    | Number of `campaign { stats { supporter_count } }` resolutions           |

**Duration buckets** (milliseconds):
- `web.duration`: `10, 25, 50, 100, 250, 500, 750, 1000, 1500, 2000, 3000, 5000, 10000`
- `api.add_action_contact.duration`: `5, 10, 20, 50, 100, 200, 300, 500, 750, 1000, 2000, 5000`

**Note:** `api.add_action_contact.duration` measures only the resolver; the
`web.duration` histogram covers the whole HTTP request end-to-end (the client-side k6
`http_req_duration` also includes network + proxy on top of this).

Example PromQL:

```promql
# HTTP request rate and p95 latency
rate(web_duration_count[5m])
histogram_quantile(0.95,
  sum by (le) (rate(web_duration_bucket[5m]))
)

# addActionContact calls/sec (histogram _count) + p95 resolver duration
rate(api_add_action_contact_duration_count[5m])
histogram_quantile(0.95,
  sum by (le) (rate(api_add_action_contact_duration_bucket[5m]))
)

# addAction and supporter-count widget call rates
rate(api_add_action_count_total[5m])
rate(api_supporter_count_count_total[5m])
```

---

## Database metrics

Emitted by Ecto for every query (`[:proca, :repo, :query]`), exposed under the `sql.*`
names. Together these break the DB part of a request into actual execution vs. waiting
for a pooled connection (`sql.queue_time` is the main pool-saturation signal).

| Metric              | Type  | Tags | Description                                            |
|---------------------|-------|------|--------------------------------------------------------|
| `sql.query_time`    | Gauge | —    | Time spent executing the query (ms)                    |
| `sql.queue_time`    | Gauge | —    | Time spent waiting to check out a DB connection (ms)   |
| `sql.idle_time`     | Gauge | —    | Time the connection sat idle in the transaction (ms)   |
| `sql.decode_time`   | Gauge | —    | Time decoding the result rows (ms)                     |
| `sql.total_time`    | Gauge | —    | query_time + queue_time + decode_time + idle_time (ms) |

---

## `mtt.pacing.*` — Drip worker + RabbitMQ delivery

Emitted from `Proca.Server.MTTWorker.process_mtt_campaign/1`,
`ProcaWeb.Telemetry.count_sendable_messages/0` (polled every 60s), and
`Proca.Server.MTTContext.emit_delivery/2`.

| Metric                        | Type      | Tags                                  | Description                                               |
|-------------------------------|-----------|---------------------------------------|-----------------------------------------------------------|
| `mtt.pacing.campaigns_running` | Gauge     | `drip_delivery` (`true`/`false`)      | Number of active MTT campaigns, split by delivery mode    |
| `mtt.pacing.sendable_messages` | Gauge     | `campaign_id`, `campaign_name`        | Total unsent messages for a campaign (polled)             |
| `mtt.pacing.sendable_targets`  | Gauge     | `campaign_id`, `campaign_name`        | Number of targets with a good email address               |
| `mtt.pacing.current_cycle`     | Gauge     | `campaign_id`, `campaign_name`        | Current send cycle number within the sending window       |
| `mtt.pacing.all_cycles`        | Gauge     | `campaign_id`, `campaign_name`        | Total cycles in the sending window                        |
| `mtt.pacing.messages_published`| Counter   | `campaign_id`, `campaign_name`        | Messages published to RabbitMQ in this drip cycle         |
| `mtt.pacing.delivery.count`    | Counter   | `kind`, `result`, `reason`, `org_id`, `campaign_id`, `drip_delivery` | Per delivery attempt outcome |

### `mtt.pacing.delivery` results

| `result` | Meaning |
|----------|---------|
| `published` | Scheduler successfully published to `wrk.N.mtt` |
| `sent` | Provider accepted the email; DB row marked sent |
| `retry` | Provider failed; message rejected → MTT fail/retry DLX |
| `discarded` | Permanently skipped (`retry_limit_exceeded`, `mtt_ended`, …) |
| `dry_run` / `publish_failed` | Mode / topology publish failures |

### Example PromQL

```promql
# How many campaigns are currently running (drip delivery)
mtt_pacing_campaigns_running{drip_delivery="true"}

# Queue publishes per campaign (not SMTP)
rate(mtt_pacing_messages_published_total[5m])

# Successful SMTP deliveries vs retries vs permanent discards
sum by (result) (rate(mtt_pacing_delivery_count_total[5m]))

# Permanent retry exhaustion (should stay near zero)
rate(mtt_pacing_delivery_count_total{result="discarded",reason="retry_limit_exceeded"}[15m])
```

---

## `mtt.throttle.*` — Per-target scheduler (`MTTScheduler`)

Emitted from lifecycle events in `Proca.Server.MTTScheduler` (start / stop / skip).
Successful sends also increment `mtt.pacing.delivery` with `result="sent"`.

### `[:mtt, :throttle, :scheduler, :start]`

Emitted in `MTTScheduler.init/1` when a scheduler process starts. Contains the
number of messages queued for this hour.

```
measurements: %{pending_count: integer}
metadata:     %{target_id: integer, campaign_id: integer,
                campaign_name: string}
```

| Metric                                | Type    | Tags            | Description                    |
|---------------------------------------|---------|-----------------|--------------------------------|
| `mtt.throttle.scheduler.start`      | Counter | `campaign_id`   | One per scheduler start        |

### `[:mtt, :throttle, :scheduler, :skip]`

Emitted when a scheduler for a target is requested but already registered.

| Metric                               | Type    | Tags                         | Description                         |
|--------------------------------------|---------|------------------------------|-------------------------------------|
| `mtt.throttle.scheduler.skip`      | Counter | `campaign_id`, `reason`      | One per suppressed duplicate start  |

### `[:mtt, :throttle, :scheduler, :stop]`

| Metric                                    | Type          | Tags                                            | Description                        |
|-------------------------------------------|---------------|-------------------------------------------------|------------------------------------|
| `mtt.throttle.scheduler.stop`            | Counter       | `campaign_id`, `stop_reason`                    | One per scheduler termination      |
| `mtt.throttle.scheduler.duration`        | Distribution  | `campaign_id`, `stop_reason`                    | Wall-clock runtime (milliseconds)  |
| `mtt.throttle.scheduler.pending_count`   | Gauge         | `campaign_id`                                   | Messages queued at start           |

**`stop_reason` taxonomy:** `:no_messages`, `:all_sent`, `:shutdown`, `:crashed`

**Duration buckets** (milliseconds): `1_000, 5_000, 30_000, 60_000, 300_000, 600_000, 3_600_000`

---

## Email backend events

| Metric                          | Type    | Tags     | Source                       |
|---------------------------------|---------|----------|------------------------------|
| `mailer.mailjet.events.count`   | Counter | `reason` | `Proca.Service.Mailjet`      |
| `mailer.mailjet.bounces.count`  | Counter | `reason` | `Proca.Service.Mailjet`      |
| `mailer.brevo.events.count`     | Counter | `reason` | `Proca.Service.Brevo`        |
| `mailer.brevo.bounces.count`    | Counter | `reason` | `Proca.Service.Brevo`        |

Mailjet and Brevo are the only providers with webhook callbacks (`handle_event` /
`handle_bounce`), so they emit `events` and `bounces` counters tagged by the raw
`reason` reported by the provider.

## Mailer delivery

Send-path telemetry, emitted once per email from the common `EmailBackend.deliver/3`
funnel — so it covers every provider (Mailjet, Brevo, SES, SMTP) automatically.
`result` is `:ok` when the provider accepted the message and `:error` otherwise.

| Metric                  | Type    | Tags                                  | Source                    |
|-------------------------|---------|---------------------------------------|---------------------------|
| `mailer.delivery.count` | Counter | `provider`, `kind`, `result`, `org_id` | `Proca.Service.EmailBackend.deliver/3` |

- `provider` ∈ `:mailjet | :brevo | :ses | :smtp`
- `kind` ∈ `:transactional | :mtt | :user | :unknown` (derived from the email's `custom_id`)
- `result` ∈ `:ok | :error`

> All four providers emit `delivery`. Only Mailjet and Brevo additionally emit the
> webhook `events` / `bounces` counters above, since SES and SMTP have no provider
> webhooks.

### Example PromQL

```promql
# per-provider send success/failure rate
sum by (provider, result) (rate(mailer_delivery_count_total[5m]))

# MTT vs transactional send volume
sum by (kind) (rate(mailer_delivery_count_total[5m]))
```

---

## Transactional email metrics

Emitted by `Proca.Stage.EmailSupporter` (the `supporter_confirm` and `thank_you`
stages) and `ProcaWeb.ConfirmController` (`reminder_confirm`).

The `*.duration` histograms measure the send lag: the time from an action's
`createdAt` until the provider accepted the message (`EmailBackend.deliver/3`
returning `:ok`). It does not include the provider's own delivery time to the
recipient's inbox. Messages whose action has a missing/invalid `createdAt` are
reported to Sentry rather than counted as a metric.

| Metric                                        | Type         | Tags     | Description                                             |
|-----------------------------------------------|--------------|----------|---------------------------------------------------------|
| `email.supporter_confirm.duration`           | Distribution | `org_id` | Supporter-confirm email send lag (ms)                   |
| `email.thank_you.duration`                   | Distribution | `org_id` | Thank-you email send lag (ms)                           |
| `email.reminder_confirm.count`               | Counter      | `org_id` | Reminder-confirm confirmation clicks                    |

**Duration buckets** (milliseconds): `100, 250, 500, 1_000, 2_500, 5_000, 10_000, 30_000, 60_000, 300_000`

### Example PromQL

```promql
# p95 supporter-confirm send lag
histogram_quantile(0.95,
  sum by (le) (rate(email_supporter_confirm_duration_bucket[5m]))
)

# thank-you lag same, per org
sum by (org_id) (rate(email_thank_you_duration_count[5m]))
```

---

## Webhook delivery

Emitted by `Proca.Stage.Webhook` for each outbound webhook push (org-owned
webhooks only). `result` is `:ok` when the push returned HTTP 200, `:error`
otherwise (404, unexpected HTTP codes, transport errors, or no backend
configured for the schema).

| Metric                   | Type    | Tags                    | Description                    |
|--------------------------|---------|-------------------------|--------------------------------|
| `webhook.delivery.count` | Counter | `org_id`, `kind`, `result` | Per-webhook-push outcome |

- `kind` ∈ `:action | :event | :unknown` (derived from the message `schema`)
- `result` ∈ `:ok | :error`

### Example PromQL

```promql
# webhook push failure rate, per org
sum by (org_id, result) (rate(webhook_delivery_count_total[5m]))

# action pushes vs event pushes
sum by (kind) (rate(webhook_delivery_count_total[5m]))
```

---

## Exporter metrics

| Metric                                        | Type    | Tags      | Description                          |
|-----------------------------------------------|---------|-----------|--------------------------------------|
| `export.action.duration`                  | Gauge   | `org_id`  | Duration of an action export (ms)    |
| `export.action.count`                     | Counter | `org_id`  | Number of export operations          |

---

## Dashboard ideas (Grafana / VictoriaMetrics)

App metrics are on `:9568/metrics`. RabbitMQ queue depth needs the
[RabbitMQ Prometheus plugin](https://www.rabbitmq.com/docs/prometheus) (or the
exporter exporter) scraped into the same VictoriaMetrics/Prometheus.

### Panels to add

1. **MTT delivery outcomes** — stacked `rate(mtt_pacing_delivery_count_total[5m])` by `result`
2. **Retry exhaustion** — `rate(mtt_pacing_delivery_count_total{result="discarded",reason="retry_limit_exceeded"}[15m])`
3. **Drip publish rate** — `rate(mtt_pacing_messages_published_total[5m])` by `campaign_id`
4. **MTT fail queue depth** (RabbitMQ) — `rabbitmq_queue_messages{queue=~"org\\..*\\.mtt\\.fail"}`
5. **MTT work queue depth** — `rabbitmq_queue_messages{queue=~"wrk\\..*\\.mtt"}`
6. **Shared fail park** — `rabbitmq_queue_messages{queue=~"org\\..*\\.fail"}` (transactional emails, webhooks, SQS)

Endless DLX loops show up as: fail-queue depth oscillating while
`mtt_pacing_delivery_count_total{result="retry"}` keeps rising and `sent` stays flat.

### MTT Scheduler Health

- **Scheduler starts** — `rate(mtt_throttle_scheduler_start_total[1h])`
- **Stop reason breakdown** — `rate(mtt_throttle_scheduler_stop_total[5m])` by `stop_reason`
- **Duration heatmap** — `mtt_throttle_scheduler_duration_milliseconds_bucket`

### Example queries

```promql
sum by (result) (rate(mtt_pacing_delivery_count_total[5m]))

rabbitmq_queue_messages{queue=~"org\\..*\\.mtt\\.fail"}

histogram_quantile(0.95,
  sum(rate(
    mtt_throttle_scheduler_duration_milliseconds_bucket{stop_reason="all_sent"}[5m]
  )) by (le)
)
```
