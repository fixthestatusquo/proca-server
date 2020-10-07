# Proca CLI[ent]

Library and CLI tool for querying Proca GraphQL API.

## Installation 

`npm install proca_cli`

## Usage 
### Setup

Proca CLI needs connection configuration, which is:
- url of proca backend
- org name you're connecting to
- user email
- user password

You can provide these attributes as:
- `.env` file, in dotfile format
- environment variables (same as in `.env` file)
- command line switches

Environment variables are:
```
ORG_NAME=someorg
AUTH_USER=user@domain.com
AUTH_PASSWORD=secret123
API_URL=https://api.proca.app
KEYS=publickey1:privatekey1,publickey2:privatekey2
```

Keys should be pasted in Base64url format (same as in Proca dashboard)

You can run `proca-cli setup` to create or update .env file interactively. At the moment only one keypair is supported.

### Commands

Common options:
- `-X` - CSV output
- `J` - JSON output
- 


`setup` - creates .env file with configuration variables 

`token` - show authorization header used

`campaigns` - list campaigns

`campaign id` - gets info about campaign

`pages` - lists action pages

`page id` - gets info about action page

`export` - exports actions.
- `-c campaignId` - just export for this campaign
- `-b number` - batch size
- `-s start` - start from id
- `-a date_time` - start from actions >= date_time (json format)




## Library usage

You can use this package as library, with:
```
import {api, crypto} from 'proca_cli'
```

First, create a client object: 

```
const c = api.client({api: "https://api.proca.foundation", user: 'me@lol.pe', password: 'qwerty1234'})
```

Methods accept client as first paramter, and are async:

`api.campaigns(client, org)` - fetch campaign list for client

`api.streamSignatures(client, org, campaignId, callback)` - downloads signatures for campaign `campaignId` and call `callback({publicKey: "source-public-key", list: [....]})` with proca server public key, and list of supporter data (contacts encrypted). 

To decrypt such stream pass `{publicKey, list}` to `crypto.decryptSignatures` method, which will return a list of supporter data with contact decrypted and JSON.parsed.
