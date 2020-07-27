defmodule Proca.Supporter.Consent do
  defstruct [
    org: nil,
    communication_consent: false,
    communication_scopes: ["email"],
    delivery_consent: false
  ]
end
