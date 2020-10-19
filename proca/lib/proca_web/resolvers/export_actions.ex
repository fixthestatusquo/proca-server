defmodule ProcaWeb.Resolvers.ExportActions do
  import Ecto.Query
  import Ecto.Changeset
  alias Ecto.Multi

  import Proca.Staffer.Permission

  alias Proca.{Supporter, Action, ActionPage, Campaign, Contact, Source, Org, Staffer, PublicKey}
  alias Proca.Contact.Data
  alias Proca.Supporter.Privacy
  alias Proca.Repo
  alias Proca.Server.Notify

  alias ProcaWeb.Helper


  def filter_start(q, %{start: start}) do
    q
    |> where([a], a.id >= ^start)
  end
  def filter_start(q, _), do: q

  def filter_after(q, %{after: after_dt}) do
    q
    |> where([a], a.inserted_at >= ^after_dt)
  end
  def filter_after(q, _), do: q

  def filter_campaign(q, %{campaign_name: name}) do
    q
    |> join(:inner, [a], camp in assoc(a, :campaign), on: camp.name == ^name)
  end

  def filter_campaign(q, %{campaign_id: cid}) do
    q
    |> where([a], a.campaign_id == ^cid)
  end

  def filter_campaign(q, _), do: q



  def format_contact(
    %Supporter{fingerprint: ref},
    %Contact{
      payload: payload, crypto_nonce: nonce,
      public_key: %PublicKey{id: pk_id, public: pk_key},
      sign_key: %PublicKey{id: sk_id, public: sk_key}
    }) do
    %{
      contact_ref: Supporter.base_encode(ref),
      payload: Contact.base_encode(payload),
      nonce: Contact.base_encode(nonce),
      public_key: %{id: pk_id, public: PublicKey.base_encode(pk_key)},
      sign_key: %{id: sk_id, public: PublicKey.base_encode(sk_key)}
    }
  end

  def format_contact(
    %Supporter{fingerprint: ref},
    %Contact{
      payload: payload
    }) do
    %{
      contact_ref: Supporter.base_encode(ref),
      payload: payload,
    }
  end

  def format_privacy(%Contact{communication_consent: cc}) do
    %{
      opt_in: cc
    }
  end

  def format(action) do
    [contact] = action.supporter.contacts

    %{
      action_id: action.id,
      action_type: action.action_type,
      created_at: action.inserted_at,
      contact: format_contact(action.supporter, contact),
      fields: Enum.map(action.fields, &Map.take(&1, [:key, :value])),
      privacy: format_privacy(contact),
      trackng: action.source,
      campaign: Map.take(action.campaign, [:name, :external_id]),
      action_page: Map.take(action.action_page, [:id, :name, :locale])
    }
  end

  @default_limit 100
  def export_actions(_parent, %{org_name: org_name} = params, %{context: %{user: user}}) do
    with %Org{} = org <- Org.get_by_name(org_name),
         %Staffer{} = staffer <- Staffer.for_user_in_org(user, org.id),
           true <- can?(staffer, [:use_api, :export_contacts])
      do

      lim = Map.get(params, :limit, @default_limit)

      from(a in Action,
        join: s in Supporter, on: a.supporter_id == s.id,
        join: c in Contact, on: c.supporter_id == s.id and c.org_id == ^org.id,
        left_join: pk in assoc(c, :public_key),
        left_join: sk in assoc(c, :sign_key),
        limit: ^lim,
        preload: [
          [supporter: [contacts: [:public_key, :sign_key]]],
          :action_page, :campaign,
          :source,
          :fields
        ])
      |> filter_start(params)
      |> filter_after(params)
      |> filter_campaign(params)
      |> Repo.all()
      |> Enum.map(&format/1)
      |> ok()

      else
        _ -> {:error, "Access forbidden"}
    end
  end

  defp ok(val) do
    {:ok, val}
  end
end
