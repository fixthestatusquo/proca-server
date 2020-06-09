# Action data processing

Proca provides a versatile system for processing action data, which supports:

1. Confirmation - whether PII needs to be confirmed by double opt-in (user
   clicks on email link to confirm or reject message), or action should be
   moderated (open letter signatory, or mail to target moderation for content),
   Proca can put supporter and action data in _confirming_ stage, before they
   are delivered.
   
   Out of the box, Proca supports sending double opt-in emails and confirming
   supporter data this way. However, you can _plug in_ to this mechanism and
   provide your own Supporter or Action confirmation mechanism. For instance,
   you could build a volunteer based, crowd-source moderation app that checks
   content of submitted actions (like signups, or mail to targets).


2. Delivery - Actions can be deliverd using internal and external mechanisms,
   all running in parallel and with batching for performance.
   The Action can be delivered by:
   - Thank you e-mail with templated, personalized content (including
     `firstName`, or custom field replacement)
   - Forwarding to CRM - using a decrypting gateway under your control, you can deliver decrypted member data to CRM of choice.
   - Forwarding to SQS - where you can do whatever SQS is used for!
   - Stored in your Org's queue (AMQP), where you can fetch actions from and process in a custom way. 

## Queues

Supporter and action data is based on AMQP queues (we use Rabbitmq). `Proca.Server.Plumbing` server is responsible to set up and maintain the queue setup. The stages of processing data is implemented by `Proca.Server.Processing` server.
