defmodule Proca.Repo.Migrations.AddSchemaComments do
  @moduledoc """
  Documentation-only migration: adds COMMENT ON to tables and to columns whose
  meaning is not obvious from the name. No schema change.

  Kept data-driven so comments stay readable and easy to extend. Comments are
  picked up by tbls and shown in guides/database. Prefer explaining *why* over
  restating the name.
  """
  use Ecto.Migration

  @tables %{
    "orgs" =>
      "Organisation (coordinators and partners). Container for campaigns, action pages(widgets), users, services and contacts/supporters data. org 1 is the system org and contains the default services (eg mailer)",
    "campaigns" => "Advocacy campaign. Groups action pages. Defines the campaign tactic and configuration (mtt, petition) and validation behaviour (required confirmation of email...)",
    "action_pages" =>
      "Widget for and org/campaign; usually one per org,campaign,locale (one per webpage)",
    "supporters" =>
      "One submission by a person. Never updated by other actions: repeat submissions create new rows linked by fingerprint. No durable PII here - the email/name/address copies are transient, kept while the action is being processed and cleared at delivery; durable PII lives in contacts",
    "public_keys" =>
      "to encrypt the PII of a contact, owned by an org. One active key at a time, older keys stay for decryption",
    "contacts" =>
      "Per-org supporter's personal data (optionally encrypted), plus the gdpr consents that org holds. This is where PII is durably retained",
    "sources" =>
      "Deduplicated tracking tuple (utm_*) and widget location, attached to a supporter or action",
    "staffers" => "Membership of a user in an org, with that user's role/permissions in the org",
    "actions" => "One action taken through a widget (signature, share, donation, MTT message...)",
    "services" =>
      "Credentials and endpoint of a remote API an org owns. Referenced from orgs as a particular backend (email, push, storage...)",
    "confirms" =>
      "Pending operation gated by a code, e.g. joining a campaign, launching a page, adding a staffer",
    "donations" => "Payment details extracted from a donation action",
    "users" => "Instance user account; authentication only. Org membership lives in staffers",
    "users_tokens" => "Issued session and email tokens for a user",
    "targets" => "Campaign target supporters can send MTT messages to (e.g. an MP, a company)",
    "target_emails" =>
      "Email addresses of a target, with the deliverability state of each address",
    "message_contents" =>
      "Email subject and body for one MTT action; shared by that action's messages, one per target",
    "messages" => "One email to one target, part of an action's MTT",
    "mtt" =>
      "Mail-To-Target configuration of a campaign: schedule and sending limits for supporter emails",
    "email_templates" =>
      "Named per-org email template used for thank-you, confirm, duplicate and MTT emails",
    "audit_log" => "Append-only record of privileged changes"
  }

  @columns %{
    {"orgs", "custom_supporter_confirm"} =>
      "Route supporter confirmation via this org's cus.* queue for external/custom gdpr validation workflow",
    {"orgs", "custom_action_confirm"} =>
      "Route action confirmation via this org's cus.* queue instead of the default queue",
    {"orgs", "custom_action_deliver"} => "deliver actions to the org CRM cus.* queue",
    {"orgs", "custom_event_deliver"} => "deliver events to the CRM cus.* queue",
    {"orgs", "contact_schema"} =>
      "Contact data shape collected for this org (Enums.ContactSchema); decides which PII fields exist",
    {"orgs", "action_schema_version"} =>
      "Proca action payload format this org uses. 2 for everyone for now",
    {"orgs", "high_security"} =>
      "Never store transient action fields on the supporter record; only the org holding the contact key may keep them, can break features!",
    {"orgs", "doi_thank_you"} => "Only send the thank-you email when the supporter gdpr opt-in",
    {"orgs", "email_from"} => "Default From address for this org's emails",
    {"orgs", "supporter_confirm"} =>
      "Require double opt-in before a supporter is treated as active",
    {"orgs", "supporter_confirm_template"} =>
      "Email template used for the supporter confirmation message",
    {"orgs", "config"} =>
      "Free-form settings, e.g. config[\"reminder\"] configures DOI reminder emails",
    {"orgs", "transactional_email_backend_id"} =>
      "Backend for transactional (non-MTT) email; falls back to email_backend. Capped by services.transactional_email_budget",
    {"orgs", "reply_enabled"} => "Add a Reply-To header to mtt sent for this org's campaigns",
    {"orgs", "sender_rewrite"} =>
      "Rewrite the envelope sender onto the backend's sending_from domain (SRS); disable for cleaner confirmation emails",
    {"campaigns", "force_delivery"} =>
      "Also deliver the contact to the campaign-owning org when the page-owning org already delivers; without it the lead only receives data when the page does not deliver",
    {"campaigns", "external_id"} =>
      "Id from an external system, used to find and upsert the campaign",
    {"campaigns", "public_actions"} =>
      "Action types whose fields are published with campaign statistics (last actions taken)",
    {"campaigns", "config"} =>
      "default widget config and locale texts, exposed as `config` in the API",
    {"campaigns", "contact_schema"} => "Overrides orgs.contact_schema for this campaign",
    {"campaigns", "transient_actions"} =>
      "Action types whose fields are never stored on the supporter, only passed downstream",
    {"campaigns", "status"} =>
      "Lifecycle state: draft/live/closed/ignored (Enums.CampaignStatus)",
    {"campaigns", "supporter_confirm"} => "Overrides orgs.supporter_confirm; NULL inherits",
    {"campaigns", "supporter_confirm_template"} =>
      "Overrides orgs.supporter_confirm_template; NULL inherits",
    {"campaigns", "start_date"} => "Start of the campaign window",
    {"campaigns", "end_date"} => "End of the campaign window",
    {"campaigns", "action_confirm"} => "Overrides whether actions need confirming; NULL inherits",
    {"action_pages", "delivery"} =>
      "When the widget's org and the campaign's org differ, whether the widget-owning org is the one that delivers (and so receives the contact with delivery consent). Same-org widgets always deliver",
    {"action_pages", "extra_supporters"} =>
      "Offset added to the campaign total, for instance for paper or external campaign tools",
    {"action_pages", "thank_you_template"} =>
      "Template for the thank-you email; falls back to the campaign/org default",
    {"action_pages", "config"} => "Free-form widget settings, e.g. journey steps and page texts",
    {"action_pages", "live"} => "Whether the widget is publicly active",
    {"action_pages", "supporter_confirm_template"} =>
      "Template for this page's supporter confirmation (DOI) email",
    {"action_pages", "duplicate_template"} =>
      "Template for the email sent when a supporter repeats an action on this page",
    {"supporters", "fingerprint"} =>
      "Hash of the person's identifying data; rows sharing a fingerprint are the same person",
    {"supporters", "email"} =>
      "Transient: used to send confirmation and thank-you email during processing, cleared at delivery (kept for MTT campaigns, which email supporters later). Durable PII lives in contacts",
    {"supporters", "first_name"} =>
      "Kept for email personalisation; by default it survives delivery and is only cleared for high_security orgs. Durable PII lives in contacts",
    {"supporters", "last_name"} =>
      "Transient: cleared at delivery (kept for MTT campaigns, which need names to send later). Durable PII lives in contacts",
    {"supporters", "address"} =>
      "Transient: cleared at delivery (kept for MTT campaigns, which need it to send later). Durable PII lives in contacts",
    {"supporters", "processing_status"} =>
      "State: 0 new, 1 confirming (awaiting double opt-in or moderation), 2 rejected (not counted), 3 accepted (valid, counted). Enums.SupporterProcessingStatus",
    {"supporters", "area"} =>
      "Area recorded on the action; kept because statistics need it and it is not PII",
    {"supporters", "email_status"} =>
      "Deliverability and opt-in state, shared by all orgs holding this supporter: 0 none (unknown), 1 double_opt_in (consented), 2 bounce, 3 blocked, 4 spam, 5 unsub, 6 inactive (do not contact), 7 active. Enums.EmailStatus",
    {"supporters", "email_status_changed"} =>
      "When email_status last changed; decides whether a status event is emitted",
    {"supporters", "dupe_rank"} =>
      "0 for the first submission by this person on the page, N for the Nth duplicate",
    {"public_keys", "public"} =>
      "Public half of the org's contact-data keypair (raw 32-byte key)",
    {"public_keys", "private"} =>
      "Private half, kept so the org can decrypt its own contact data",
    {"public_keys", "active"} => "Key currently used to encrypt new contact data for this org",
    {"public_keys", "expired"} =>
      "Retired after key rotation; old contacts encrypted with it can still be decrypted",
    {"contacts", "payload"} =>
      "Encrypted personal data; only a holder of the matching key can decrypt it",
    {"contacts", "crypto_nonce"} => "Nonce used to encrypt and decrypt payload",
    {"contacts", "public_key_id"} =>
      "Key that can decrypt payload (the org's active key at capture time)",
    {"contacts", "sign_key_id"} =>
      "Key that signed the payload; may differ from the encryption key",
    {"contacts", "communication_consent"} =>
      "Whether the supporter agreed to receive communication from this org",
    {"contacts", "communication_scopes"} => "Channels the consent covers; currently only email",
    {"contacts", "delivery_consent"} =>
      "Whether the supporter's data was delivered to this org (see action_pages.delivery and campaigns.force_delivery)",
    {"sources", "campaign"} => "utm_campaign value; not a reference to campaigns",
    {"sources", "location"} =>
      "utm_location value; empty string when the widget did not report one",
    {"staffers", "perms"} =>
      "Permission bit flags of this user in this org (see Proca.Staffer.Role)",
    {"staffers", "last_signin_at"} => "Last time the user signed in while acting as this org",
    {"actions", "ref"} =>
      "Opaque reference used to attach a supporter to an action created before the personal data was collected",
    {"actions", "action_type"} => "Type of action taken, e.g. sign, share, donate, mtt",
    {"actions", "with_consent"} =>
      "Whether this action carried a communication consent, used when building downstream messages",
    {"actions", "fields"} => "Action-specific custom fields; capped at 5 KB",
    {"actions", "processing_status"} =>
      "State: 0 new, 1 confirming (awaiting confirmation or moderation), 2 rejected (refused, not delivered), 3 accepted (valid, queued for delivery), 4 delivered (sent downstream), 5 repeat (duplicate action on the same page). Enums.ActionProcessingStatus",
    {"actions", "testing"} => "Test submission; excluded from delivery and statistics",
    {"services", "name"} =>
      "Service type/provider (Enums.ExternalService), e.g. mailjet, webhook, ses",
    {"services", "host"} => "Hostname, or a type-specific container: for AWS it holds the region",
    {"services", "user"} => "Account id, client id, or whatever credential the service uses",
    {"services", "password"} => "Secret credential (password, key, token)",
    {"services", "path"} => "Type-dependent resource selector, e.g. AWS bucket name or URL path",
    {"services", "sending_from"} =>
      "Verified sending address used as envelope From when rewriting the sender (SRS); falls back to orgs.email_from",
    {"services", "transactional_email_budget"} =>
      "How many transactional emails to route via this service before falling back to email_backend; NULL means no limit",
    {"confirms", "operation"} => "Operation being confirmed (Enums.ConfirmOperation)",
    {"confirms", "subject_id"} => "Id of the acting subject, e.g. the org that joined a campaign",
    {"confirms", "object_id"} => "Id of the object the operation acts on, e.g. the campaign",
    {"confirms", "email"} =>
      "If set, the code is sent to this address and may be used without authentication, like a one-time password",
    {"confirms", "code"} => "Secret code that accepts or rejects the confirm",
    {"confirms", "charges"} => "How many times the code may still be used",
    {"confirms", "message"} => "Optional message attached to the confirm",
    {"confirms", "creator_id"} => "User who created the confirm",
    {"donations", "schema"} => "How to interpret payload (Enums.DonationSchema)",
    {"donations", "payload"} =>
      "Raw payment provider object that amount and currency are extracted from",
    {"donations", "amount"} => "Amount in the smallest currency unit, e.g. cents",
    {"donations", "currency"} => "ISO 4217 currency code",
    {"donations", "frequency_unit"} =>
      "one_off/weekly/monthly/daily (Enums.DonationFrequencyUnit)",
    {"users", "perms"} => "Instance-level permission flags",
    {"users", "external_id"} =>
      "Same user in an external identity provider; used to match them on login",
    {"users", "hashed_password"} => "Password hash; never the password itself",
    {"users_tokens", "token"} => "Hashed token; the plaintext is only ever sent to the user",
    {"users_tokens", "context"} => "What the token is for, e.g. session or reset_password",
    {"users_tokens", "sent_to"} => "Address the token was delivered to when sent out of band",
    {"targets", "external_id"} => "Stable id from the target list, used to upsert targets",
    {"targets", "area"} => "Area the target belongs to, for filtering message lists",
    {"targets", "fields"} => "Free-form target attributes imported from the target list",
    {"targets", "locale"} => "Language to use for messages to this target",
    {"target_emails", "email_status"} =>
      "Deliverability of this address: 0 none (not tried yet), 2 bounce, 3 blocked, 4 spam, 5 unsub, 7 active (last delivery succeeded). Enums.EmailStatus",
    {"target_emails", "error"} => "Last delivery error reported by the mail provider",
    {"target_emails", "soft_bounce_count"} =>
      "Consecutive soft bounces; address is marked bounced once the threshold is passed",
    {"message_contents", "subject"} => "Subject template, with supporter/target merge fields",
    {"message_contents", "body"} => "Body template, with supporter/target merge fields",
    {"messages", "delivered"} => "Whether the provider accepted the message for delivery",
    {"messages", "sent"} => "Whether Proca has already sent it; used to pick up unsent messages",
    {"messages", "opened"} => "Whether the recipient opened the email, from provider webhooks",
    {"messages", "clicked"} =>
      "Whether the recipient clicked in the email, from provider webhooks",
    {"messages", "dupe_rank"} =>
      "0 for the first message by this supporter to this target, N for later duplicates; used to avoid re-mailing targets",
    {"messages", "files"} => "Attached file keys in the org's storage backend",
    {"mtt", "start_at"} => "Start of the window in which emails may be sent",
    {"mtt", "end_at"} => "End of the window in which emails may be sent",
    {"mtt", "stats"} => "Aggregated send statistics for this MTT",
    {"mtt", "message_template"} =>
      "Template used for MTT emails; when unset, the raw action text is sent",
    {"mtt", "test_email"} => "Address test MTT actions are sent to instead of the real targets",
    {"mtt", "max_emails_per_hour"} => "Throttle on outbound emails for this MTT",
    {"mtt", "timezone"} => "Timezone used to interpret the send window and drip schedule",
    {"mtt", "cc_contacts"} => "Addresses copied on every MTT email",
    {"mtt", "cc_sender"} => "Also copy the supporter's own address on the email",
    {"mtt", "drip_delivery"} =>
      "Spread emails over the window instead of sending them all at the start",
    {"email_templates", "external_id"} =>
      "Template id at the external provider; when set, the provider template is used instead of local html/subject/text",
    {"audit_log", "actor_id"} => "Who made the change: a user id or an API client id",
    {"audit_log", "resource"} => "Type of the changed resource",
    {"audit_log", "resource_id"} => "Id of the changed resource",
    {"audit_log", "changeset"} => "The recorded change, including before/after values"
  }

  def up do
    Enum.each(@tables, fn {table, comment} ->
      execute(comment_table(table, comment))
    end)

    Enum.each(@columns, fn {{table, column}, comment} ->
      execute(comment_column(table, column, comment))
    end)
  end

  def down do
    Enum.each(@tables, fn {table, _} -> execute(comment_table(table, nil)) end)

    Enum.each(@columns, fn {{table, column}, _} -> execute(comment_column(table, column, nil)) end)
  end

  defp comment_table(table, comment),
    do: "COMMENT ON TABLE public.#{table} IS #{literal(comment)}"

  defp comment_column(table, column, comment),
    do: "COMMENT ON COLUMN public.#{table}.#{column} IS #{literal(comment)}"

  defp literal(nil), do: "NULL"
  defp literal(text), do: "'" <> String.replace(text, "'", "''") <> "'"
end
