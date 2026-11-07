# proca

## guides

Human-written docs live in [`guides/`](guides/); read the relevant one before
changing code it covers.

- `Concepts.md` — core domain terms (Action, Supporter, Campaign, …)
- `Processing.md` — action lifecycle: confirmation, duplicate detection, delivery
- `Components.md` — processes that make up the server (web, stats, …)
- `API.md` / `APISchema.md` — GraphQL auth + full generated schema
- `Encryption.md`, `Telemetry.md` — crypto flow, Prometheus metrics
- `Developing.md` — mix tasks and db setup; `starting.md` — minimal dev setup
- `DesignPrinciples.md`, `HowToSyncActionsData.md`, `XOther.md`, `asdf.md`
- `database/` — generated per-table schemas and ER diagram; start at
  [`database/README.md`](guides/database/README.md)

## conventions

- **Migrations**: give every new table, and every column whose meaning is not
  obvious from its name, a Postgres `COMMENT`. Explain *why* it exists, don't
  restate the name. 
- **After every schema change**, regenerate the db docs from the test database:
  `MIX_ENV=test mix ecto.migrate && mix proca.gen_db_docs`
- **Never hand-edit generated files** — change the source and regenerate:
  - `guides/database/*` → `mix proca.gen_db_docs`
  - `schema.graphql` → `mix gen.schema`
  - `guides/APISchema.md` → generated from the GraphQL schema
- **Enums live in two places**: `lib/proca/ecto_enum.ex` and the GraphQL enums in
  `lib/proca_web/schema/data_types.ex`. Change both together.
- **Domain vocabulary**: use the terms in `guides/Concepts.md` (Supporter, Contact,
  Action, Action Page, Campaign, Org, Staffer, Service/backend). Key invariant:
  `supporters` holds no durable PII — only a transient copy until delivery —
  while per-org PII and consent live in `contacts`.
- Run `mix format` before finishing.

## Agent skills

### Issue tracker

Issues live in GitHub Issues for `fixthestatusquo/proca-server`, driven by the `gh` CLI.

