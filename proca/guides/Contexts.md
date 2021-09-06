## List of contexts in Proca

For a planned code re-organisation post v3 release, we want to organise modules into following contexts.
Contexts are [module groups](https://hexdocs.pm/phoenix/contexts.html) of related functionality.

For now, some more thought needs to be put into this.

In doubt: should we stick to all names in plural vs singular? The case of mixed naming is that full module name can be better. Against singular names is fact that it will clash with model name (Proca.Org.Org?). 

- Actions - action, contact, supporter, field, sources, Actions.Message
- Contact - all things related to contact validation
- Stage - all things processing actions 
- Pipes - proca queues integration
- Orgs - org, staffer, public_key, encryption
- Campaign
- ActionPage - (maybe under campaign? OTOH action page is a very central model)
- Server - stats, health, notifications - (diff name? Monitors?)
- Users - (POW)
- Confirms - actions that need two actors to perform (actor + confirmer, can be same person as in double opt in)






