defmodule Proca.Service.EmailRecipient do
  @moduledoc """
  Represents an email recipient, for email templates that can be persnonalized.
  """
  alias Proca.Service.EmailRecipient
  import Proca.Repo, only: [preload: 2]

  defstruct first_name: "", email: "", ref: "", fields: %{}, custom_id: ""

  def from_action_data(action_data) do
    action_id = get_in(action_data, ["action", "id"])
    rcpt = %EmailRecipient{
      first_name: get_in(action_data, ["contact", "firstName"]),
      email: get_in(action_data, ["contact", "email"]),
      custom_id: "action:#{action_id}",
      ref: case action_data do 
        %{"schema" => "proca:action:1"} -> get_in(action_data, ["contact", "ref"])
        %{"schema" => "proca:action:2"} -> get_in(action_data, ["contact", "contactRef"])
      end
    }


    fields = get_in(action_data, ["action", "fields"])

    # add also ref field. I guess email and name are implemented in template render (by Mailjet etc)?
    fields = Map.merge(fields, Map.take(rcpt, [:first_name, :email, :ref]))

    fields =
      Map.merge(fields, %{
        campaign: %{
          name: get_in(action_data, ["campaign", "name"]),
          title:  get_in(action_data, ["campaign", "title"])
        },
        action_page: %{
          name: get_in(action_data, ["actionPage", "name"]),
        },
        tracking: get_in(action_data, ["tracking"])
      })

    fields =
      fields
      |> Enum.reject(fn {_, v} -> is_nil(v) end)
      |> Map.new()

    %{rcpt | fields: fields}
  end

  # XXX deprecate
  def put_confirm(
    rcpt = %EmailRecipient{fields: fields}, 
    cnf = %Proca.Confirm{code: confirm_code, email: email, message: message, object_id: obj_id, subject_id: subj_id}
    ) do

    fields2 = Map.merge(fields, Proca.Confirm.notify_fields(cnf))

    %{rcpt | fields: fields2}
  end

  def put_fields(rcpt = %EmailRecipient{fields: fields}, fields2) when is_map(fields2) do 
    %{rcpt | fields: Map.merge(fields, fields2)}
  end

  def put_fields(rcpt, []), do: rcpt
  def put_fields(rcpt = %EmailRecipient{fields: fields}, [{key, val} | rest]) do
    %{rcpt | fields: Map.put(fields, Atom.to_string(key), val)}
    |> put_fields(rest)
  end
end
