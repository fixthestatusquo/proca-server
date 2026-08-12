```
   ,,\\\\\\,,
  ,\\\\\\\\\\\
 ▲▲▲▲▲▲\\\\\\\\  FIX THE STATUS QUO
▲▲▲▲▲▲▲▲\\\\\\`  PROCA SERVER v3
▼▼▼▼▼▼▼▼\\\\\`
 ▼▼▼▼▼▼\\\^``    https://proca.app
```

# 🌍 [Proca server](https://docs.proca.app)

**Proca Server** is an [Elixir](https://elixir-lang.org/) application that uses **PostgreSQL** as a datastore and **RabbitMQ** for asynchronous data processing. It serves as the backend for the [Proca Widget](https://github.com/FixTheStatusQuo/proca), providing campaign infrastructure for NGO and non-profit movements.

This is a (mostly headless) [Phoenix Framework](https://www.phoenixframework.org/) app, built using standard Phoenix practices. If you're new to Phoenix, we recommend reading up on its conventions to contribute effectively — see the [development guide](https://hexdocs.pm/phoenix/up_and_running.html) and [deployment guide](https://hexdocs.pm/phoenix/deployment.html).

Made with ❤️, Elixir, and the belief that we can build tools to make the world a better place.

---

## 📢 Code of Conduct

This project is released under a [Contributor Code of Conduct](code_of_conduct.md). By participating, you agree to uphold its principles.

[![Contributor Covenant](https://img.shields.io/badge/Contributor%20Covenant-v2.0%20adopted-ff69b4.svg)](code_of_conduct.md)

---

## ✨ Features

- **Headless architecture** – Built to serve apps via APIs.
- **GraphQL API** – Flexible and efficient data querying.
- **Fine-grained permission system** – Users are organized into _Organizations (Orgs)_ with specific roles and access scopes.
- **Authentication** – Supports HTTP Basic Auth or JWT tokens (ideal for external identity providers).
- **Campaign tree model** – Organizes action pages into campaigns; multiple orgs can collaborate in coalitions.
- **End-to-end encrypted data** – Member personal data is stored encrypted at rest. Only the controlling Org can decrypt it.
- **Schema-based personal data validation** – Supports various formats.
- **GDPR compliance** – Includes consent management, optional double opt-in, and action staging (moderation/filtering before acceptance).
- **Email delivery** – Sends thank-you, opt-in, and email-to-target messages via Mailjet, AWS SES, and more.
- **Pluggable processing** – Asynchronous action processing via RabbitMQ.
- **Flexible forwarding** – Pushes actions to AWS SQS or CRMs via a decryption gateway deployed by the Org.
- **CSV export** – Action data can be exported in spreadsheet-friendly format.

---

## 📦 Prerequisites

To develop and run the Proca server, you’ll need:

- **[PostgreSQL](https://www.postgresql.org/download/)**
- **[RabbitMQ](https://www.rabbitmq.com/download.html)**
- **[asdf](https://asdf-vm.com/guide/getting-started.html)**
- **[Node.js](https://nodejs.org/)**

> We **recommend using `asdf`** to install Erlang and Elixir. Other installation methods may lead to version conflicts you'll need to resolve manually.

### 🔗 Helpful resources

- [Our asdf setup guide for Ubuntu](/guides/asdf.md)
- [Script for RabbitMQ installation on Ubuntu](https://www.rabbitmq.com/docs/install-debian#apt-quick-start-cloudsmith)

---

## ⚙️ Installation

1. **Clone your fork of the repo**.

2. Run the following setup commands:

```bash
sudo apt install automake libssl-dev autoconf libncurses5-dev
asdf plugin add erlang
asdf plugin add elixir
asdf install
mix local.rebar
mix local.hex
```

---

## 🧪 Development Setup

1. Ensure **PostgreSQL** and **RabbitMQ** are installed and running.

2. Set the environment variables:

```bash
export MIX_ENV=dev
export ADMIN_EMAIL=your_admin_email@example.com
```

3. Run the configuration script:

```bash
./utils/configure-development-env.sh
```

This script:

- Sets up PostgreSQL
- Installs Erlang, Elixir, Phoenix and RabbitMQ dependencies
- Runs `npm install` inside the `assets/` directory

> You'll be prompted for `sudo` during parts that configure PostgreSQL.

> You'll be prompted for setting the ADMIN_EMAIL variable if you failed on reading this manual.
> The script will print out your login and password:

```
#####
#####   Created Admin user your_admin_email@example.com  #####
#####   Password: VERY_RANDOM_PASSWORD
#####
```

---

## 🥳 Boom! Everything's ready. Go make some impact. 💥

---

## 🚀 Running the Development Server

```bash
mix phx.server
```

By default, the development webserver is located at:
http://localhost:4000/

---

## 🛠️ From building to server

To build:

```bash
./build
```

The build script uses `mix release --overwrite` and `strip_beams: true` for
smaller, faster-loading releases. The built release is placed in
`_build/prod/rel/proca/`.

Read more in [Developing](/guides/Developing).

---

## 🚢 Deploying

### 1. Build + release

```bash
./scripts/release [version]
```

Builds the release, copies it to `/srv/proca/releases/proca-<version>`,
and cleans up old releases. Shared step — run once, then deploy to staging
and/or live.

### 2. Deploy to staging

```bash
./scripts/deploy-staging [version]
```

Runs `release`, symlinks `/srv/proca/current`, migrates, and restarts `proca`.

### 3. Deploy to live

**Simple (brief downtime):**
```bash
./scripts/deploy-live [version]
```

Assumes `release` was already run. Checks the `/srv/proca/live` symlink,
migrates, and restarts `proca-live`.

**Zero-downtime (blue-green):**

Eliminates restart downtime by running two instances behind nginx. Only **one**
instance runs at a time during normal operation. During a deploy, the standby
starts briefly, nginx swaps the upstream port, and the old instance is stopped.

Install both systemd services:

```bash
sudo cp deploy/proca-blue.service /etc/systemd/system/proca-live-blue.service
sudo cp deploy/proca-green.service /etc/systemd/system/proca-live-green.service
sudo systemctl daemon-reload
sudo systemctl enable proca-live-blue && sudo systemctl start proca-live-blue
```

Configure nginx upstream with primary + backup (see `deploy/proca-nginx.conf`):

```nginx
upstream proca_live {
    server 127.0.0.1:4001;
    server 127.0.0.1:4011 backup;
}
```

Deploy:
```bash
./scripts/deploy-bluegreen [version]
```

This will:
1. Verify the release exists and the symlink
2. Run database migrations
3. **Start the standby** instance and wait for `/health`
4. **Swap the nginx upstream** — standby becomes primary, old becomes backup
5. `nginx -s reload`
6. **Stop the old instance**

The two instances overlap only during the switch.

---

## 🔍 Health Check

After deploying, both routers (main and ECI) expose a readiness endpoint:

```
GET /health
```

Returns `{"status":"ok"}` (HTTP 200) when the database is reachable, or
`{"status":"error","message":"database unreachable"}` (HTTP 503) otherwise.

Use this for nginx `proxy_pass` health checks, load balancer probes, or
manual verification after deployment:

```bash
curl http://localhost:4000/health
```

---

## ⏱️ Startup Optimisation

The production release compresses BEAM bytecode (`strip_beams: true`) for
faster loading. Additionally, background daemon servers (MTT, Stats,
OldActions, Jwks, etc.) are started with a **configurable delay** so the
HTTP endpoint and database pool come up first:

| Config | Env var | Default | Description |
|---|---|---|---|
| `daemon_start_delay` | `DAEMON_START_DELAY` | `5000` (ms) | Delay before starting non-critical background services. Set to `0` for synchronous startup. |
| `start_daemon_servers` | — | `true` | Set to `false` to disable all background services entirely (useful in development). |

---

## 🧰 Optional Environment Variables

You can use the following environment variables to customize server behavior during development:

- `ENABLE_TELEMETRY`
  If set to `true`, the server will expose Prometheus metrics on port `9568`.
  **Disabled by default in development.**

- `START_DAEMON_SERVERS`
  If set to `true`, the server will start background processes.
  Disable this to speed up development server startup (e.g., if you're not working on MTT).
  **Enabled by default**, disable with:

```bash
export START_DAEMON_SERVERS=false
```

---
