# [Proca - Progressive Campaigning](https://proca.app)

**Installation & Development Setup Guide**

---

## 📦 Prerequisites

To develop and run the Proca server, you’ll need:

- **[PostgreSQL](https://www.postgresql.org/download/)**
- **[RabbitMQ](https://www.rabbitmq.com/download.html)**
- **[asdf](https://asdf-vm.com/guide/getting-started.html)**
- **[Node.js](https://nodejs.org/)**

> We **recommend using `asdf`** to install Erlang and Elixir. Other installation methods may lead to version conflicts you'll need to resolve manually.

### 🔗 Helpful resources

- [Our asdf setup guide for Ubuntu](guides/asdf.md)
- [Script for RabbitMQ installation on Ubuntu](https://www.rabbitmq.com/docs/install-debian#apt-quick-start-cloudsmith)

---

## ⚙️ Installation

1. **Clone your fork of the repo**.

2. Run the following setup commands:

   ```bash
   $ sudo apt install automake libssl-dev autoconf libncurses5-dev
   $ asdf plugin add erlang
   $ asdf plugin add elixir
   $ asdf install
   $ mix local.rebar
   $ mix local.hex
   ```

---

## 🧪 Development Setup

1. Ensure **PostgreSQL** and **RabbitMQ** are installed and running.

2. Set the environment variables:

   ```bash
   export MIX_ENV=dev
   ```

   and

   `export ADMIN_EMAIL=your_admin_email@example.com`

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

    #####
    #####   Created Admin user your_admin_email@example.com  #####
    #####   Password: VERY_RANDOM_PASSWORD
    #####

##🚀 Running the Development Server

```bash
$ mix phx.server
```

By default, the development webserver is located at:
http://localhost:4000/

---

## From building to server

This is a [must read on development of Phoenix apps](https://hexdocs.pm/phoenix/up_and_running.html)

This is a [must read on deployment of Phoenix apps](https://hexdocs.pm/phoenix/deployment.html)

To build:

```bash
$ ./build
```

Read more in [Developing](guides/Developing).

---

## Optional environment variables

For development purposes, you can use the following environment variables to customize server behavior:

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
