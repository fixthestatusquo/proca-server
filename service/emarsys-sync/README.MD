# Emarsys Sync

A syncer that reads RabbitMQ queue for actions and synces them to Emarsys CRM.

- Will create a list for each campaign, using campaign name
- as an exception, `fur_free_europe` campaign will create a list `Proca ECI FUR` (hardcoded, as per request of client)


## Build and install

- `yarn build`, `yarn publish`
- installs `emarsys-sync` command into system


## Configuration

- `EMARSYS_USER`, `EMARSYS_PASSWORD` - Emarsys CRM credentials
- `QUEUE_URL` - An AMQP url with credentials eg `amqp://user:password@localhost/proca_live`

Run with delivery queue name to read: `emarsys-sync -q cus.527.deliver`



## Mini CLI

The `emarsys-sync cli` subcommand has some CLI tools to work with emarsys:

Get into env where it's installed and load env vars:

```
env NODE_VERSION=18.1.0 /opt/nvm/nvm-exec bash -i # Steinem does not have modern nodejs in main user space
set -a
source /etc/emarsys-sync-vier_pfoten_at.env
```
            
Then use `emarsys cli` with:
            
```
  -L       - list contactlists
  -l name  - get contactlist by name
  -e email - get contact by email
  -i id    - get contact by id
  -r ref   - get contact by ref
  -D name  - delete contactlist by name
  -C name  - add sample contact to list name (always same contact data)
  -s       - list all contact ids (first page)
  -m       - print out contact fields model
```
