# Proca SDK: encryption helpers

Proca server pushes actions to AMQP service in format defined in `@proca/queue` package.
The action or event data can contain Personal Identifiable Information (PII) in encrypted form.
This package provides helpers to decrypt the NaCL encrypted payload.

## TypeScript types

- `KeyStore` - Contains NaCL key pairs used to decrypt PII.


## Functions

- `loadKeyStoreFromFile(filename : string)` - load `KeyStore` from a file.

- `loadKeyStoreFromString(content : string)` - load `KeyStore` from a string

- `storeKeyStoreToFile(keystore : KeyStore, filename? : string)` - store `KeyStore` into file

- `decryptPersonalInfo(pii : PersonalInfo | undefined, keyStore : KeyStore) :
  any` - decrypt `PersonalInfo` record (see @proca/queue definitions) using a provided `KeyStore`
