```

   ,,\\\\\\,,
  ,\\\\\\\\\\\
 ▲▲▲▲▲▲\\\\\\\\  FIX THE STATUS QUO 
▲▲▲▲▲▲▲▲\\\\\\`  PROCA SERVER v3
▼▼▼▼▼▼▼▼\\\\\`   
 ▼▼▼▼▼▼\\\^``    https://proca.app

```

# Proca server & satelite packages

## About this repository

the vast majority of this repo is the [elixir server](./proca). However, we have put as well some client api code that often needs to stay in sync with the server.

- Monorepo for [Proca server](https://docs.proca.app)
- SDK libraries in Typescript and Javascript, and common microservices (Managed by Lerna, JS monorepo manager)

- Included packages:
  - proca - the core proca api server and processing engine
  - sdk/api - thin GraphQL api client
  - sdk/cli - client and CLI tool containing more top level operations
  - skd/crypto (planned) - code refactored out from sdk/cli concerning decrypting supporter data
  - sdk/queue (planned) - code refactored out from sdk/cli concerning reading from AMQP and message action format (slightly differing from api action format)
  - service/action-gw - action data decrypting gateway to decrypt actions on premises

To add a new repository into this one, use `lerna import` tool. It will import all the commit history. Recommended way is:

```
yarn lerna import --flatten --dest service ../path/to/service-repo-on-disk
```
Make sure the dir name of repo is the same as one you want to be created under `service/`

### Caveats 

1. Proca server is an Elixir project and tasks for it are run using `mix` tool. It contains `package.json` so lerna will treat it as a project; however, it is set to private and will not be published to npm repositories.

2. You need to use Yarn and not NPM, as this is our choice and Yarn devs did not bother to implement lifecycle events in the same way as NPM `¯\_(ツ)_/¯`. We are using yarn.

## Available top level commands

Word of warning: NPM 7 changed the lifecycle evens most notably splitting the `prepublish` into `prepare` and `prepareOnly`. However, Yarn and Lerna differ. Lerna uses two lifecycle events: `bootstrap` and `publish`. Yarn uses a simpler events model so `install` runs `preinstall`, `install`, `postinstall`, `prepublish`, `prepare`.


- `yarn lerna bootstrap` - installs, inter-links and compiles dependencies in all projects
- `yarn lerna publish` - publishes all packages (and bumps versions)
- `yarn test` runs tests

### lifecycle details

- `yarn lerna bootstrap` runs
  - npm install all external dependencies of each package.
  - Symlink together all Lerna packages that are dependencies of each other.
  - npm run prepublish in all bootstrapped packages (unless --ignore-prepublish is passed).
  - npm run prepare in all bootstrapped packages.

## Build systems

- lerna manages interdependencies, especially in JS projects 
  - yarn (not npm) for individual packages
    - make - used by AWS SAM in lambda projects
  - mix - builder for Elixir
