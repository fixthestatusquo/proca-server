# Proca SDK: queue helpers

Proca server pushes actions through AMQP queues, to which you can plug in your microservice.
This module provides few helpers to work with queues.

if you intend to sync with a crm, you might want to start [with this higher level template](https://github.com/fixthestatusquo/proca-sync-template/)

## TypeScript types

- `ActionMessageV2` - a type describing message with an action data
- `EventMessageV2` - a type describing message with an event data

## Functions

- `syncQueue(url, queueName, callback, options)` - Start reading actions and events from `queueName` queue from AMQP server at `url`. For each action or event, `callback` is called.

  - options is a map with:

    - `concurrency` - if set, set number of messages to be processed at the same time
    - `keyStore` - decryption key store (see `@proca/crypto` module) if PII of supporters is to be decrypted

  - Callback signature is: `async callback(action : ActionMessageV2 | EventMessageV2)`
  
  - it returns boolean (or {processed:boolean{) if false, the message is nacked and processed later

  - if this function throw an error, we are going to close the connection

- `testQueue(url, queueName)` - If queue `queueName` exists on AMQP server `url`, return its stats

## AMQP authentication

Use HTTP Basic Auth inlined in url to authenticate to AMQP server (eg. `amqps://username:password@example.com:1572`).

## Version 5.0.0

Function syncQueue is updated to manage the case when it needs to nack a message without closing the channel. It will fail if the callback does not return the boolean. All the apps that use version 3 of this function should be adapted before updating, or they will break.
