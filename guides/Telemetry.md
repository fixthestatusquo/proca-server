# MTT Telemetry / Prometheus Metrics

All MTT-related metrics are emitted via `:telemetry.execute/3` and exposed as Prometheus
metrics on the port configured by `config :proca, ProcaWeb.Telemetry, port: 9568`
(default `9568`).

There are two MTT subsystems, each with its own metric namespace:

- **`proca.mtt.*`** — drip delivery worker (runs every ~3 minutes, per campaign via `MTTWorker`) plus RabbitMQ delivery outcomes
- **`proca.mtt_new.*`** — hourly per-target scheduler lifecycle (`MTTScheduler`, launched by `MTTHourlyCron`)

---

## `proca.mtt.*` — Drip worker + RabbitMQ delivery

Emitted from `Proca.Server.MTTWorker.process_mtt_campaign/1`,
`ProcaWeb.Telemetry.count_sendable_messages/0` (polled every 60s), and
`Proca.Server.MTTContext.emit_delivery/2`.

| Metric                        | Type      | Tags                                  | Description                                               |
|-------------------------------|-----------|---------------------------------------|-----------------------------------------------------------|
| `proca.mtt.campaigns_running` | Gauge     | `drip_delivery` (`true`/`false`)      | Number of active MTT campaigns, split by delivery mode    |
| `proca.mtt.sendable_messages` | Gauge     | `campaign_id`, `campaign_name`        | Total unsent messages for a campaign (polled)             |
| `proca.mtt.sendable_targets`  | Gauge     | `campaign_id`, `campaign_name`        | Number of targets with a good email address               |
| `proca.mtt.current_cycle`     | Gauge     | `campaign_id`, `campaign_name`        | Current send cycle number within the sending window       |
| `proca.mtt.all_cycles`        | Gauge     | `campaign_id`, `campaign_name`        | Total cycles in the sending window                        |
| `proca.mtt.messages_published`| Counter   | `campaign_id`, `campaign_name`        | Messages published to RabbitMQ in this drip cycle         |
| `proca.mtt.messages_sent`     | Counter   | `campaign_id`, `campaign_name`        | Same as `messages_published` (legacy name; not SMTP send) |
| `proca.mtt.delivery.count`    | Counter   | `kind`, `result`, `reason`, `org_id`, `campaign_id`, `drip_delivery` | Per delivery attempt outcome |

### `proca.mtt.delivery` results

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
proca_mtt_campaigns_running{drip_delivery="true"}

# Queue publishes per campaign (not SMTP)
rate(proca_mtt_messages_published_total[5m])

# Successful SMTP deliveries vs retries vs permanent discards
sum by (result) (rate(proca_mtt_delivery_count_total[5m]))

# Permanent retry exhaustion (should stay near zero)
rate(proca_mtt_delivery_count_total{result="discarded",reason="retry_limit_exceeded"}[15m])
```

---

## `proca.mtt_new.*` — Per-target scheduler (`MTTScheduler`)

Emitted from lifecycle events in `Proca.Server.MTTScheduler` (start / stop / skip).
Successful sends also increment `proca.mtt.delivery` with `result="sent"`.

### `[:proca, :mtt_new, :scheduler, :start]`

Emitted in `MTTScheduler.init/1` when a scheduler process starts. Contains the
number of messages queued for this hour.

```
measurements: %{pending_count: integer}
metadata:     %{target_id: integer, campaign_id: integer,
                campaign_name: string}
```

| Metric                                | Type    | Tags            | Description                    |
|---------------------------------------|---------|-----------------|--------------------------------|
| `proca.mtt_new.scheduler.start`      | Counter | `campaign_id`   | One per scheduler start        |

### `[:proca, :mtt_new, :scheduler, :skip]`

Emitted when a scheduler for a target is requested but already registered.

| Metric                               | Type    | Tags                         | Description                         |
|--------------------------------------|---------|------------------------------|-------------------------------------|
| `proca.mtt_new.scheduler.skip`      | Counter | `campaign_id`, `reason`      | One per suppressed duplicate start  |

### `[:proca, :mtt_new, :scheduler, :stop]`

| Metric                                    | Type          | Tags                                            | Description                        |
|-------------------------------------------|---------------|-------------------------------------------------|------------------------------------|
| `proca.mtt_new.scheduler.stop`            | Counter       | `campaign_id`, `stop_reason`                    | One per scheduler termination      |
| `proca.mtt_new.scheduler.duration`        | Distribution  | `campaign_id`, `stop_reason`                    | Wall-clock runtime (milliseconds)  |
| `proca.mtt_new.scheduler.pending_count`   | Gauge         | `campaign_id`                                   | Messages queued at start           |

**`stop_reason` taxonomy:** `:no_messages`, `:all_sent`, `:shutdown`, `:crashed`

**Duration buckets** (milliseconds): `1_000, 5_000, 30_000, 60_000, 300_000, 600_000, 3_600_000`

---

## Email backend events

| Metric                          | Type    | Tags     | Source                       |
|---------------------------------|---------|----------|------------------------------|
| `proca.mailjet.events.count`   | Counter | `reason` | `Proca.Service.Mailjet`      |
| `proca.mailjet.bounces.count`  | Counter | `reason` | `Proca.Service.Mailjet`      |
| `proca.brevo.events.count`     | Counter | `reason` | `Proca.Service.Brevo`        |
| `proca.brevo.bounces.count`    | Counter | `reason` | `Proca.Service.Brevo`        |

---

## Exporter metrics

| Metric                                        | Type    | Tags      | Description                          |
|-----------------------------------------------|---------|-----------|--------------------------------------|
| `proca.exporter.export_actions.export_time`  | Gauge   | `org_id`  | Duration of an action export (ms)    |
| `proca.exporter.export_actions.count`        | Counter | `org_id`  | Number of export operations          |

---

## Dashboard ideas (Grafana / VictoriaMetrics)

App metrics are on `:9568/metrics`. RabbitMQ queue depth needs the
[RabbitMQ Prometheus plugin](https://www.rabbitmq.com/docs/prometheus) (or the
exporter exporter) scraped into the same VictoriaMetrics/Prometheus.

### Panels to add

1. **MTT delivery outcomes** — stacked `rate(proca_mtt_delivery_count_total[5m])` by `result`
2. **Retry exhaustion** — `rate(proca_mtt_delivery_count_total{result="discarded",reason="retry_limit_exceeded"}[15m])`
3. **Drip publish rate** — `rate(proca_mtt_messages_published_total[5m])` by `campaign_id`
4. **MTT fail queue depth** (RabbitMQ) — `rabbitmq_queue_messages{queue=~"org\\..*\\.mtt\\.fail"}`
5. **MTT work queue depth** — `rabbitmq_queue_messages{queue=~"wrk\\..*\\.mtt"}`
6. **Shared fail park** — `rabbitmq_queue_messages{queue=~"org\\..*\\.fail"}` (transactional emails, webhooks, SQS)

Endless DLX loops show up as: fail-queue depth oscillating while
`proca_mtt_delivery_count_total{result="retry"}` keeps rising and `sent` stays flat.

### MTT Scheduler Health

- **Scheduler starts** — `rate(proca_mtt_new_scheduler_start_total[1h])`
- **Stop reason breakdown** — `rate(proca_mtt_new_scheduler_stop_total[5m])` by `stop_reason`
- **Duration heatmap** — `proca_mtt_new_scheduler_duration_milliseconds_bucket`

### Example queries

```promql
sum by (result) (rate(proca_mtt_delivery_count_total[5m]))

rabbitmq_queue_messages{queue=~"org\\..*\\.mtt\\.fail"}

histogram_quantile(0.95,
  sum(rate(
    proca_mtt_new_scheduler_duration_milliseconds_bucket{stop_reason="all_sent"}[5m]
  )) by (le)
)
```
