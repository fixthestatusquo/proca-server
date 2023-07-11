## Main concepts in Proca Server

### Action

Represents a single action done by supporter. Is the smallest action we track, it does not have parts.

It has a reference to a Supporter. The supporter is either newly created with the Action, or one of old Supporter records can be re-used.

### Supporter 

Represents a Supporter. For a real person, multiple duplicated Supporter records can exist. They will all have the same contact reference (`contact ref` or just `ref`, also called `fingerprint`). The Supporter data is never changed, so we create a new Supporter instead of updating the old one. When fetching Supporter by the contact ref, the latest one will be returned.

Contact ref is associated with unique-ish information  about the person, such as email, or national id, so a person with same email will have the same contact ref.

The personal data of Supporter is stored in separate Contact records, one per data-sharing party (Org).

Relevant modules: [Proca.Supporter](Proca.Supporter.html), [Proca.Contact](Proca.Contact.html)


### Org

Represents an Organization, Org for short. Org is a container for various resources in the system: campaigns, pages, contact data, users. If a particular real-world organisation benefits from breaking it down into two Org's, perhaps because they serve a different function, that can be done.

Relevant modules: [Proca.Org](Proca.Org.html), [Proca.Staffer](Proca.Staffer.html)

### Campaign

Campaign represents an advocacy campaign and stores its name, texts, defines duration, and other characteristics.


Relevant modules: [Proca.Campaign](Proca.Campaign.html)

### Action Page 

Action Page or Page for short represents a website page where a campaign widget is running. Action Page does not enforce that widget is not re-used on many pages, though for analytics purposes and flexibility it should be used on just single page.
Page belongs to a Campaign (runs that campaign), and to Org (on that org's website).

Relevant modules: [Proca.ActionPage](Proca.ActionPage.html)

### XXX
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






