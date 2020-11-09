defmodule Proca.Supporter.Consent do
  @moduledoc """
  Models a consent for entered personal data, for an Org.
  Ultimately stored in Contact record.

  XXX move to Proca.Contact.Consent
  """
  defstruct org: nil,
            communication_consent: false,
            communication_scopes: ["email"],
            delivery_consent: false
end
