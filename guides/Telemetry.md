# MTT Telemetry / Prometheus Metrics

All MTT-related metrics are emitted via `:telemetry.execute/3` and exposed as Prometheus
metrics on the port configured by `config :proca, ProcaWeb.Telemetry, port: 9568`
(default `9568`).

There are two MTT subsystems, each with its own metric namespace:

- **`proca.mtt.*`** — the "drip delivery" worker (runs every 30s, per campaign via `MTTWorker`)
- **`proca.mtt_new.*`** — the "hourly" per-target scheduler (runs every hour via `MTTScheduler`,
  launched by `MTTHourlyCron`)

---

## `proca.mtt.*` — Drip-delivery worker (`MTTWorker`)

Emitted from `Proca.Server.MTTWorker.process_mtt_campaign/1` and
`ProcaWeb.Telemetry.count_sendable_messages/0` (polled every 60s).

| Metric                        | Type      | Tags                                  | Description                                               |
|-------------------------------|-----------|---------------------------------------|-----------------------------------------------------------|
| `proca.mtt.campaigns_running` | Gauge     | `drip_delivery` (`true`/`false`)      | Number of active MTT campaigns, split by delivery mode    |
| `proca.mtt.sendable_messages` | Gauge     | `campaign_id`, `campaign_name`        | Total unsent messages for a campaign (polled)             |
| `proca.mtt.sendable_targets`  | Gauge     | `campaign_id`, `campaign_name`        | Number of targets with a good email address               |
| `proca.mtt.current_cycle`     | Gauge     | `campaign_id`, `campaign_name`        | Current send cycle number within the sending window       |
| `proca.mtt.all_cycles`        | Gauge     | `campaign_id`, `campaign_name`        | Total cycles in the sending window                        |
| `proca.mtt.messages_sent`     | Counter   | `campaign_id`, `campaign_name`        | Cumulative messages sent in this cycle                    |

### Example PromQL

```promql
# How many campaigns are currently running (drip delivery)
proca_mtt_campaigns_running{drip_delivery="true"}

# Messages sent per campaign over time
rate(proca_mtt_messages_sent_total[5m])
```

---

## `proca.mtt_new.*` — Per-target scheduler (`MTTScheduler`)

Emitted from `Proca.Server.MTTContext.deliver_message/2` (per-message) and
lifecycle events in `Proca.Server.MTTScheduler` (start / stop / skip).

### `[:proca, :mtt_new, :deliver_message]`

Emitted once per successfully delivered message in `MTTContext.deliver_message/2`.

```
measurements: %{}
metadata:     %{target_id: integer}
```

| Metric                                    | Type    | Tags          | Description                    |
|-------------------------------------------|---------|---------------|--------------------------------|
| `proca.mtt_new.deliver_message.count`     | Counter | `target_id`   | One per delivered message      |

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

Emitted in `MTTSupervisor.start_mtt_scheduler/2` when a scheduler for a target
is requested but a process for that target is already registered (duplicate
suppression via Registry).

```
measurements: %{}
metadata:     %{target_id: integer, campaign_id: integer, reason: :already_running}
```

| Metric                               | Type    | Tags                         | Description                         |
|--------------------------------------|---------|------------------------------|-------------------------------------|
| `proca.mtt_new.scheduler.skip`      | Counter | `campaign_id`, `reason`      | One per suppressed duplicate start  |

### `[:proca, :mtt_new, :scheduler, :stop]`

Emitted in `MTTScheduler.terminate/2` when a scheduler process stops, for
whatever reason.

```
measurements: %{duration: native_time, messages_sent: integer}
metadata:     %{target_id: integer, campaign_id: integer,
                campaign_name: string,
                stop_reason: atom}
```

**`stop_reason` taxonomy:**

| Reason            | Meaning                                                                 |
|-------------------|-------------------------------------------------------------------------|
| `:no_messages`    | `get_pending_messages/2` returned zero — nothing to do                  |
| `:all_sent`       | All queued messages were delivered, queue drained normally              |
| `:shutdown`       | Supervisor shut down the scheduler (e.g. hourly cron restart)           |
| `:crashed`        | Unhandled exception caused the process to exit                          |

| Metric                                    | Type          | Tags                                            | Description                        |
|-------------------------------------------|---------------|-------------------------------------------------|------------------------------------|
| `proca.mtt_new.scheduler.stop`            | Counter       | `campaign_id`, `stop_reason`                    | One per scheduler termination      |
| `proca.mtt_new.scheduler.duration`        | Distribution  | `campaign_id`, `stop_reason`                    | Wall-clock runtime (milliseconds)  |
| `proca.mtt_new.scheduler.pending_count`   | Gauge         | `campaign_id`                                   | Messages queued at start           |

**Duration buckets** (milliseconds):

```
1_000, 5_000, 30_000, 60_000, 300_000, 600_000, 3_600_000
```

---

## Email backend events

Metrics for email provider events (bounces, spam, deliveries).

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

## Dashboard ideas

### MTT Scheduler Health

- **Scheduler starts** — `rate(proca_mtt_new_scheduler_start_total[1h])`
- **Stop reason breakdown** — stacked area of
  `rate(proca_mtt_new_scheduler_stop_total[5m])` by `stop_reason`
- **Duration heatmap** — heatmap of
  `proca_mtt_new_scheduler_duration_milliseconds_bucket` over time
- **Duplicate skips** —
  `rate(proca_mtt_new_scheduler_skip_total{reason="already_running"}[1h])`

### MTT Throughput

- **Messages delivered** —
  `rate(proca_mtt_new_deliver_message_count_total[5m])`
- **Pending messages (gauge)** — `proca_mtt_sendable_messages` by campaign
- **Campaigns running** — `proca_mtt_campaigns_running`

### Example queries

```promql
# How many schedulers started per campaign
rate(proca_mtt_new_scheduler_start_total[1h])

# What fraction finished all messages vs found none
sum by (stop_reason) (proca_mtt_new_scheduler_stop_total)

# P50 / P95 duration of successful schedulers only
histogram_quantile(0.5,
  sum(rate(
    proca_mtt_new_scheduler_duration_milliseconds_bucket{stop_reason="all_sent"}[5m]
  )) by (le)
)

# Schedulers killed by hourly restart before finishing
proca_mtt_new_scheduler_stop_total{stop_reason="shutdown"}
```
