## Main concepts in Proca Server

### Action

Represents a single action done by supporter. Is the smallest action we track, it does not have parts.

It has a reference to a Supporter. The supporter is either newly created with the Action, or one of old Supporter records can be re-used.

Relevant modules: `Proca.Action`

### Supporter 

Represents a Supporter. For a real person, multiple duplicated Supporter records can exist. They will all have the same contact reference (`contact ref` or just `ref`, also called `fingerprint`). The Supporter data is never changed, so we create a new Supporter instead of updating the old one. When fetching Supporter by the contact ref, the latest one will be returned.

Contact ref is associated with unique-ish information  about the person, such as email, or national id, so a person with same email will have the same contact ref.

The personal data of Supporter is stored in separate Contact records, one per data-sharing party (Org).

Relevant modules: `Proca.Supporter`, `Proca.Contact`


### Org

Represents an Organization, Org for short. Org is a container for various resources in the system: campaigns, pages, contact data, users. If a particular real-world organisation benefits from breaking it down into two Org's, perhaps because they serve a different function, that can be done.

Relevant modules: `Proca.Org`, `Proca.Staffer`

### Campaign

Campaign represents an advocacy campaign and stores its name, texts, defines duration, and other characteristics.


Relevant modules: `Proca.Campaign`

### Action Page 

Action Page or Widget for short represents a website page where a campaign widget is running. Action Page does not enforce that widget is not re-used on many pages, though for analytics purposes and flexibility it should be used on just single page.
Page belongs to a Campaign (runs that campaign), and to Org (on that org's website).

Relevant modules: `Proca.ActionPage`

### Users and Staffers 


User holds credentials to access one or more org they are part of. Staffer is a record that specifies roles and permissions of user in particular org.

Relevant modules: `Proca.Users.User`, `Proca.Staffer`

### Services and Backends


Services are remote SaaS/APIs that belong to particular Org and can be used by it. A service is best understood as *some API*. Eg. HTTP POST Webhook service, Mailjet service

When a Service is *used* for some goal, it's a *Backend* for that goal, usually specified as `xxxxBackend`. Eg. HTTP POST Webhook *service* can be used to push actions (and then it is used as *pushBackend*) or as supporter details lookup source (and then it is used as *detailBackend*). Mailjet *Service* can be used to send emails (*emailBackend*) or fetch email template names (*templateBackend*) (recently the emailBackend and templateBackend have been merged, but for a while they were separate, so theoretically you could fetch tempalte from SES and send the email into Mailjet...).

For some services, an org can use a special `SYSTEM` service for a backend, and this will use a service owned by instance org. This is a way of orgs to "borrow" a service from the instance org, and it seems to be mostly the default way orgs send emails (initially we wanted them to use their own email accounts).


Relevant modules: `Proca.Service`, `Proca.Org`



