# Encryption features in Proca

Proca supports encrypting personal data at rest with public key crypto, where
only recipient (Organisation's CRM) can decrypt it.

All actions stored and processed by the app are split into personal identifiable
information (PII), and other action metadata (eg. action type, custom fields
like share medium, or a member's comment). The PII is encrypted using public key
crypto. Only public key used to encrypt is known to the app. The secret key
should be kept safe by the organization that is receiving action data, and PII
should be decrypted on their premises.

Some PII can be stored in clear, if it is needed for action processing. For
instance, Proca needs to know member's email, to send a double opt-in request,
but the email is removed as soon as it's not needed anymore. Currently fields which undergo such treatment are:

- `email` - E-mail is kept to: 1. send a double opt-in email 2. send a thank-you
  email
- `first_name` - First name is kept for personalisation of emails sent above.
  This PII should be treated same as email.

## Communication overview

Proca uses popular [NaCl](https://nacl.cr.yp.to/) crypto. It was chosen because
of ease of use and ubiquitous implementations. The communicating peers in Proca
are `Proca.Org`s. Each of them has one active key pair, stored in `Proca.PublicKey`. Proca
is multi-tenant app, and one organisation, called _Home Org_, is distinguished,
and has a role of _sender_ of all PII. All other Orgs in Proca are _recipient
Orgs_. Proca app only knows the secret key of _Home Org_, for _recipient Orgs_
secret key is empty (`nil`). The _Home Org_ should never run campaigns itself,
because the secret key is held within the app.


## Encryption procedure

PII is encrypted by `Proca.Server.Encrypt` server. On app initialization, it
reads _Home Org_ public and private keys, and generates a 24 byte nonce (using
`:crypto.strong_rand_bytes/1`). The server does not check whether random nonce
does not already exist for some {PII, recipient key} pair in database. It is
assumed that such event is unlikely.

It exposes `Proca.Server.Encrypt.encrypt` and `Proca.Server.Encrypt.decrypt`
methods. Encrypting a message entails incrementing of nonce (disregarding which
Org is the recipient). The cipher text and payload, along with sender and
recipient key reference, are stored in `Proca.Contact`. The server does not
check whether nonce will overflow and have produce same nonce for same recipient
key. This is considered an unlikely event with 24 bytes of nonce length.

## PII distribution

When running campaigns in coalition, two Orgs can be receiving PII of member. A typical scenario is one, where Org1 runs a _campaign_ but Org2 collected the petition signature on _action page_ they run. If member opted in to both of them, then both will receive PII. 

Proca splits action data from PII, and in such case petition signature will be a
single action, but it will reference two records holding PII, and each of them
will be encrypted with a key belonging to respective Org1 and Org2. This is a
similar way that PGP encrypted email is sent to many recipients - it's encrypted
multiple times with key of each recipient.

## Future: Full end-to-end encryption feature 

Proca currently supports storing encrypted PII at rest, but still the data is
processed by Proca back-end server, and in cases where some processing is
necessary PIIs like email or first name are stored for some time. We are trying
to strike a balance between going completely blind on data, and providing
features out of the box (like thank you emails, double opt-ins), as well as data
validation.

We plan to enable an extra secure e2e encryption, where the widget does encryption in the front-end. In this case:
1. Widget generates a throw-away key pair, and a nonce
2. Widget validates and encrypts PII with Orgs keys (this entails _no server side validation of data_)
3. Widget sends encrypted data with a nonce

Issue here: https://github.com/TechToThePeople/proca/issues/117


