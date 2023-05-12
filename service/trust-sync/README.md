test

curl -d '{"email":"test@example.org"}' -H "Content-Type: application/json" -X POST http://localhost:3000/lookup-trust
curl -d '{"email":"sebastian.srb@palasthotel.de"}' -H "Content-Type: application/json" -X POST http://localhost:3000/lookup-trust

# Trust sync

There are two apps in the folder: Lobby Control (Trust) sync (index.ts) and lookup (http.ts).

## Sync

- Reads actions from deliver queue.
- Transforms data in the format client requested (type TrustAction in data.ts) using formatAction function in `data.ts` file
- Posts formatted action to Trust using postAction in `client.ts`. If successful it returns a verification token
- Verifies posted data with another post request to Trust - verification function in `client.ts`.
  The payload for this request is an object with keys `subscribe_newsletter` and `data_handling_consent`. A verification token is used to create an API URL.
