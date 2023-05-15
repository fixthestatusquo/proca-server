# Trust sync

There are two apps in the folder for Lobby Control Trust CRM.

1. Sync to CRM app `trust-sync`.
  - Entry point is `index.ts`
  - Reads a RabbitMQ queue, and POST actions into Trust CRM
  
2. CRM lookup microservice `trust-lookup` 
  - Entry point is `http.ts`
  - Listens for POST requests with supporter email or contactRef
  - Does a lookup in Trust CRM and returns information in Proca-Server format


## Sync

- Reads actions from deliver queue.
- Transforms data in the format client requested (type TrustAction in data.ts) using formatAction function in `data.ts` file
- Posts formatted action to Trust using postAction in `client.ts`. If successful it returns a verification token
- Verifies posted data with another post request to Trust - verification function in `client.ts`.
  The payload for this request is an object with keys `subscribe_newsletter` and `data_handling_consent`. A verification token is used to sign the request.
- IMPORTANT: We add-and-verify in one go because Proca Server already did verify the supporter, through own DOI mechanism. So we short-circuit/skip Trust verification which normally involves sending the token to supporter, and only verify after they click they link. 

### Configuration environment:

- `TRUST_KEY` - Trust CRM API key
- `RABBITMQ_USER` and `RABBITMQ_PASSWORD` - RabbitMQ credentials
- `RABBITMQ_QUEUE` - The Queue name to read actions from (eg "cus.310.deliver")
- `POST_URL` - add signature API path, for LC: "https://lc-trust-prod.palasthotel.de/api/v1/petition_signatures"
- `VERIFICATION_URL` - verify signature API path, for LC: "https://lc-trust-prod.palasthotel.de/api/v1/petition_signatures/"



## Lookup

- Listens on a port PORT, for POST requests
- The request payload should be `{email: "some@email.com"}`
- It returns:
  - code 200 and payload `{action: {customFields: {isSubscribed: true}}}` if members is found and subscribed (All are, Trust does not hold unsubscribed members)
  - code 200 and payload `{}` when not found
  - failure code if Trust returns a failure code (same code)


### Configuration

- `TRUST_KEY` - Trust CRM API key
- `PORT` - port to listen on 
- `LOOKUP_URL` - lookup member in CRM, for LC: "https://lc-trust-prod.palasthotel.de/api/v1/lookup/newsletter_subscribers?email="


### Testing Lookup

```
curl -d '{"email":"test@example.org"}' -H "Content-Type: application/json" -X POST http://localhost:3000/lookup-trust
curl -d '{"email":"sebastian.srb@palasthotel.de"}' -H "Content-Type: application/json" -X POST http://localhost:3000/lookup-trust
```

