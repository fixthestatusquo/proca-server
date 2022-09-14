defmodule Proca.Stage.Support do
  @moduledoc """
  Support functions for job processing in Broadway. Most imporatntly functions
  to build RabbitMQ events containing enough data to be processed internally
  (system) or externally (custom).
  """

  alias Proca.{Action, Supporter, PublicKey, Contact, Field, Confirm}
  alias Proca.Repo
  import Ecto.Query, only: [from: 2]
  alias Broadway.Message
  import Logger

  # XXX for now we assume that only ActionPage owner does the processing, but i think it should be up to
  # the AP.delivery flag
  #

  def action_stage(%Action{
        processing_status: :delivered,
        supporter: %{processing_status: :accepted}
      }) do
    :deliver
  end

  def action_stage(%Action{processing_status: :new, supporter: %{processing_status: :confirming}}) do
    :supporter_confirm
  end

  def action_stage(%Action{
        processing_status: :confirming,
        supporter: %{processing_status: :accepted}
      }) do
    :action_confirm
  end

  def action_stage(%Action{supporter: %Supporter{}}), do: nil

  def bulk_actions_data(action_ids, stage \\ :deliver, org_id \\ nil) do
    from(a in Action,
      where: a.id in ^action_ids,
      preload: [
        [supporter: [contacts: [:public_key, :sign_key, :org]]],
        [action_page: :org],
        :campaign,
        :source
      ]
    )
    |> Repo.all()
    |> Enum.map(fn a -> action_data(a, stage, org_id) end)
  end

  def action_data(action, stage \\ :deliver, org_id \\ nil) do
    org_id = org_id || action.action_page.org_id

    contact = Enum.find(action.supporter.contacts, fn c -> c.org_id == org_id end)

    mod =
      case contact.org.action_schema_version do
        1 -> Proca.Stage.MessageV1
        2 -> Proca.Stage.MessageV2
      end

    apply(mod, :action_data, [action, stage, org_id])
  end

  def ignore(message = %Broadway.Message{}, reason \\ "ignored") do
    message
    |> Message.configure_ack(on_failure: :ack)
    |> Message.failed(reason)
  end

  def failed_partially(messages, statuses) do
    Enum.zip(messages, statuses)
    |> Enum.map(fn
      {m, :ok} ->
        m

      {m, {:error, reason}} ->
        error("Cannot sent email: #{inspect(reason)}")
        Message.failed(m, reason)
    end)
  end

  def to_iso8601(naivedatetime) do
    naivedatetime
    |> DateTime.from_naive!("Etc/UTC")
    |> DateTime.to_iso8601()
  end

  defp link_verb(:confirm), do: "accept"
  defp link_verb(:reject), do: "reject"

  def double_opt_in_link(%Action{id: action_id, supporter: %{fingerprint: fpr}}) do
    ref = Supporter.base_encode(fpr)

    double_opt_in_link(action_id, ref)
  end

  def double_opt_in_link(action_id, contact_ref)
      when is_integer(action_id) and is_bitstring(contact_ref) do
    ProcaWeb.Router.Helpers.confirm_url(
      ProcaWeb.Endpoint,
      :double_opt_in,
      action_id,
      contact_ref
    )
  end

  def supporter_link(%Action{id: action_id, supporter: %{fingerprint: fpr}}, op) do
    ref = Supporter.base_encode(fpr)

    supporter_link(action_id, ref, op)
  end

  def supporter_link(action_id, contact_ref, op)
      when is_integer(action_id) and is_bitstring(contact_ref) do
    ProcaWeb.Router.Helpers.confirm_url(
      ProcaWeb.Endpoint,
      :supporter,
      action_id,
      link_verb(op),
      contact_ref
    )
  end

  def confirm_link(%Confirm{code: code, email: email}, op)
      when is_bitstring(code) and is_bitstring(email) do
    ProcaWeb.Router.Helpers.confirm_url(ProcaWeb.Endpoint, :confirm, link_verb(op), code,
      email: email
    )
  end

  def confirm_link(%Confirm{code: code, object_id: id}, op)
      when is_bitstring(code) and is_number(id) do
    ProcaWeb.Router.Helpers.confirm_url(ProcaWeb.Endpoint, :confirm, link_verb(op), code, id: id)
  end

  def confirm_link(%Confirm{code: code}, op) when is_bitstring(code) do
    ProcaWeb.Router.Helpers.confirm_url(ProcaWeb.Endpoint, :confirm, link_verb(op), code)
  end

  @doc """
  Flattens the nested map keys so that there is only one nesting level of keys and values.
  The resulting keys are joined by underscore to form a snake-case key name.
  """
  def flatten_keys(map, nil_to \\ nil) when is_map(map) do
    map
    |> Enum.map(fn x -> flatten_keys_entry(x, nil_to) end)
    |> List.flatten()
    |> Map.new()
  end

  defp flatten_keys_entry(entry, nil_to, path \\ [])

  defp flatten_keys_entry({k, map}, nil_to, path) when is_map(map) do
    map
    |> Enum.map(fn entry -> flatten_keys_entry(entry, nil_to, [k | path]) end)
  end

  defp flatten_keys_entry({k, other}, nil_to, path) do
    full_key =
      [k | path]
      |> Enum.map(&ensure_string/1)
      |> Enum.reverse()
      |> Enum.join("_")
      |> ProperCase.camel_case()

    value =
      case other do
        nil -> nil_to
        x -> x
      end

    {full_key, value}
  end

  @doc """
  Convert map atom keys to strings
  """
  def stringify_keys(nil), do: nil

  def stringify_keys(map = %{}) do
    map
    |> Enum.map(fn {k, v} -> {Atom.to_string(k), stringify_keys(v)} end)
    |> Enum.into(%{})
  end

  # Walk the list and stringify the keys of
  # of any map members
  def stringify_keys([head | rest]) do
    [stringify_keys(head) | stringify_keys(rest)]
  end

  def stringify_keys(not_a_map) do
    not_a_map
  end

  def ensure_string(a) when is_atom(a), do: Atom.to_string(a)
  def ensure_string(s) when is_bitstring(s), do: s

  @doc """
  Turn the case of keys in the map to camel case
  """
  def camel_case_keys(map) when is_map(map) do
    map
    |> Enum.map(fn {key, val} ->
      {ProperCase.camel_case(key), camel_case_keys(val)}
    end)
    |> Map.new()
  end

  def camel_case_keys(other), do: other
end
