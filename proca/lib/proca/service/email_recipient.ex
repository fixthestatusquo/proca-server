defmodule Proca.Service.EmailRecipient do
  @moduledoc """
  Represents an email recipient, for email templates that can be persnonalized.
  """
  alias Proca.Service.EmailRecipient

  defstruct first_name: "", email: "", ref: "", fields: %{}

  def from_action_data(action_data) do
    rcpt = %EmailRecipient{
      first_name: get_in(action_data, ["contact", "firstName"]),
      email: get_in(action_data, ["contact", "email"]),
      ref: get_in(action_data, ["contact", "ref"])
    }

    fields = get_in(action_data, ["action", "fields"])

    # add also ref field. I guess email and name are implemneted in template render (by Mailjet etc)?
    fields = Map.merge(fields, Map.take(rcpt, [:first_name, :email, :ref]))

    fields =
      Map.merge(fields, %{
        "campaign_name" => get_in(action_data, ["campaign", "name"]),
        "campaign_title" => get_in(action_data, ["campaign", "title"]),
        "action_page_name" => get_in(action_data, ["actionPage", "name"]),
        "utm_source" => get_in(action_data, ["tracking", "source"]),
        "utm_medium" => get_in(action_data, ["tracking", "medium"]),
        "utm_campaign" => get_in(action_data, ["tracking", "campaign"]),
        "utm_content" => get_in(action_data, ["tracking", "content"])
      })

    fields =
      fields
      |> Enum.reject(fn {_, v} -> is_nil(v) end)
      |> Map.new()

    %{rcpt | fields: fields}
  end
end

defimpl Bamboo.Formatter, for: Proca.Service.EmailRecipient do
  def format_email_address(recipient, _opts) do
    {recipient.first_name, recipient.email}
  end
end
