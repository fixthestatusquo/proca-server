
3.0 RELEASE
2.11.2021

The release brings consistency in how action data looks like in API and processing messages (JSON format in AMQP)

- New format (v2) of action represented as JSON message used in all action
  processing. It is closer to format of `addActionContact` and `addAction` APIs.
- Action fields are now a JSON, named `customFields` in API fields. `fields` key-value pairs still work, but are deprecated.
- Replaced POW with stock Phoenix Auth
- New authentication context allows for auth scopes: Administrators, Organisation, Campaign group
- Removed the legacy frontend code to just have a simple frontpage (hidden for only SSO instances)
- Some Org management APIs like users, service, processing management were added
