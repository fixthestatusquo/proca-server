# Proca SDK: queue helpers

Proca server pushes actions through AMQP queues, to which you can plug in your microservice.
This module provides few helpers to work with queues.

## TypeScript types

- `ActionMessageV2` - a type describing message with an action data
- `EventMessageV2` - a type describing message with an event data

## Functions

- `syncQueue(url, queueName, callback, options)` - call with a callback to bind it to message stream

  - options is a map with:
    - `prefetch` - if set, set number of messages to prefetch from queue
    - `keyStore` - decryption key store (see `@proca/crypto` module) if PII of supporters is to be decrypted


- `testQueue(url, queueName)` - return queue stats if it exists
