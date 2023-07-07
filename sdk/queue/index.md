## process the events from the queue

Proca uses rabbitMQ queues as the main tool to synchronise to external services. It provides several benefits in terms of synchronizing and integrating with external services effectively:

- Asynchronous Communication: RabbitMQ supports asynchronous communication patterns, allowing your application to send messages to external services without waiting for a response immediately. This enables your application to continue processing other tasks while the message is being handled by the external service.

-  Reliable Message Delivery: RabbitMQ ensures reliable message delivery by providing features like acknowledgments and message persistence. When sending messages to external services, RabbitMQ can track the delivery status and provide feedback to the sender, ensuring that the message is successfully delivered or handled appropriately.

-  Decoupling and Scalability: RabbitMQ acts as an intermediary between your application and external services. By decoupling the components, RabbitMQ allows them to evolve independently. This enhances the scalability of your system, as you can add or remove services without impacting other components, as long as they adhere to the messaging protocol.

- Fault Tolerance: RabbitMQ is designed to handle failures gracefully. It provides features like message acknowledgment, durable queues, and automatic recovery, which ensure that messages are not lost even in the event of system failures or service outages. This makes RabbitMQ a reliable choice for synchronizing with external services.

However, it is a rather complex system to use and handle properly every type of error that can happen.

The default behaviour is to process one message after another (concurrency param) and pre-fetch twice as many.

when a message can't be processed (eg you are trying to push it to a REST API that doesn't respond), it does put it back in front of the queue to be re-processed later, if you can't process it again, it is put as the back of the queue so other messages can be processed first.

this is a lower level interface, you probably should use one of our other higher level tools.


