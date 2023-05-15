# Confirm reminder

This service is used to re-send the DOI if supporters ignore a previous one.

- It can work with any org (not bound to any CRM etc)
- It watches how Proca Server is processing actions and injects actions again if they need to send another confirm email.

## Do you understand RabbitMQ queue vs exchange?

In RabbitMQ, an exchange is a message routing agent that receives messages from producers and routes them to message queues. It's like a post office, where the exchange decides where to deliver messages based on the message's routing key. Exchanges come in several types, such as direct, topic, fanout, and headers, which determine how messages are routed.

When a message is sent to an exchange, the exchange will route the message to one or more queues that are bound to it. Queues are like buffers that hold messages until they can be processed. A message can be routed to multiple queues if they are bound to the same exchange. This is useful in scenarios where multiple consumers need to receive the same message for processing.

For example, let's say we have two queues, Queue A and Queue B, that are both bound to the same exchange. When a message is sent to the exchange, the exchange will route a copy of the message to both Queue A and Queue B, allowing multiple consumers to process the same message simultaneously.

In summary, when two queues are bound to the same exchange, they will both receive a copy of any message that is sent to that exchange, allowing multiple consumers to receive and process the same message.

## How does it work

Normal Proca Server workflow:

1. New action for DOI goes into `confirm supporter` queue.
2. Build in email worker sends a DOI email
3. Supporter clicks a link which results in adding the action to `delivery` queue and `email supporter`, as ACCEPTED.
4. Delivery queue is read by CRM syncer, it synces to CRM; the `email supporter` is read by build in email worker, it sends a thank you email.


Proca Workflow with this confirm reminder:


1. New action for DOI goes into `confirm supporter` queue.
1a. The action *also* goes to `cus.310.confirm.supporter` because custom supporter confirm was enabled on org.
2. Build in email worker sends a DOI email
2a. Confirm Reminder reads the `cus.310.confirm.supporter` and saves it in local database (LavelDB) - to remember it's due to for confirmation
3. Supporter clicks a link which results in adding the action to `delivery` queue and `email supporter`, as ACCEPTED
3a. A copy of action goes into `cus.310.confirmed ` queue, which was created by hand in RabbitMQ admin and connected to `deliver` exchange for that org.
4. Delivery queue is read by CRM syncer, it synces to CRM; the `email supporter` is read by build in email worker, it sends a thank you email.
4a. `cus.310.confirmed` queue is read by Confirm Reminder, and the action is marked as confirmed in local DB. We are not interested about it any more, because it is confirmed.

5. Every minute, we check the local DB to see which actions were unconfirmed and when. We use a `RETRY_INTERVAL=2,3` to wait first 2 days, and then for 3 days, to perform 1st and 2nd attempt to send the email. 
  - If the time is right to re-send the confirm email, we inject the action into supporter confirm exchange `org.310.confirm.supporter`, so the email is send as in point 2.
  - If too many attempts were done already, we mark the action as done but not confirmed.
  
  
## Configuration

- `DB_PATH` - Path to LevelDB (it's a directory) eg `/srv/confirm-reminder/lobbycontrol`
- `RABBIT_USER`, `RABBITMQ_PASSWORD` - RabbitMQ credentials
- `CONFIRM_QUEUE` - custom supporter confirm queue, eg `cus.X.confirm.supporter`
- `CONFIRMED_QUEUE` - a copy of delivery queue, eg `cus.310.confirmed`, must be connected to `org.X.deliver` exchange to get copies of accepted actions
- `REMIND_EXCHANGE` - confirm supporter stage exchange `org.310.confirm.supporter`
- `RETRY_INTERVAL` - interval in days between consecutive attempts to send confirm email: `2,3` = try after 2 days and then again after 3 days.




