defmodule ProcaWeb.Resolvers.Org do
  @moduledoc """
  Resolvers for org { } root query
  """
  # import Ecto.Query
  import Ecto.Query
  import Ecto.Changeset

  alias Proca.{ActionPage, Campaign, Action}
  alias Proca.{Org, Staffer, PublicKey, Service, Auth}
  alias ProcaWeb.{Error, Helper}
  alias ProcaWeb.Resolvers.ChangeAuth
  alias Ecto.Multi

  alias Proca.Repo
  import Logger

  def return_from_context(_, _, %{context: %{org: org}}) do
    {:ok, org}
  end

  def campaign_by_id(org, %{id: camp_id}, _) do
    c =
      Campaign.select_by_org(org)
      |> where([c], c.id == ^camp_id)
      |> preload([c], [:org])
      |> Repo.one()

    case c do
      nil -> {:error, %Error{message: "Cannot find campaign", code: "not_found"}}
      c -> {:ok, c}
    end
  end

  def action_pages_select(query, %{select: %{campaign_id: cid}}) do
    query
    |> where([ap], ap.campaign_id == ^cid)
  end

  def action_pages_select(query, _) do
    query
  end

  def action_pages(org, params, _) do
    c =
      Ecto.assoc(org, :action_pages)
      |> action_pages_select(params)
      |> preload([ap], [:org])
      |> Repo.all()

    {:ok, c}
  end

  def action_page(_, _, %{context: %{action_page: page}}), do: {:ok, page}

  def org_personal_data(org, _args, _ctx) do
    {
      :ok,
      Map.take(org, [
        :contact_schema,
        :supporter_confirm,
        :supporter_confirm_template,
        :high_security,
        :doi_thank_you,
        :reply_enabled
      ])
    }
  end

  def org_processing(org, _args, _ctx) do
    org =
      Repo.preload(org, [
        :email_backend,
        :event_backend,
        :storage_backend,
        :push_backend,
        :detail_backend
      ])

    email_backend =
      case org do
        %Org{email_backend: %{name: name}} -> name
        _ -> nil
      end

    event_backend =
      case org do
        %Org{event_backend: %{name: name}} -> name
        _ -> nil
      end

    storage_backend =
      case org do
        %Org{storage_backend: %{name: name}} -> name
        _ -> nil
      end

    detail_backend =
      case org do
        %Org{detail_backend: %{name: name}} -> name
        _ -> nil
      end

    push_backend =
      case org do
        %Org{push_backend: %{name: name}} -> name
        _ -> nil
      end

    # Refactor to use Map.take - watch out sqs name is different
    r =
      %{
        org: org,
        email_backend: email_backend,
        event_backend: event_backend,
        storage_backend: storage_backend,
        push_backend: push_backend,
        detail_backend: detail_backend
      }
      |> Map.merge(
        Map.take(
          org,
          ~w(email_from supporter_confirm supporter_confirm_template doi_thank_you custom_supporter_confirm custom_action_confirm custom_action_deliver custom_event_deliver system_sqs_deliver)a
        )
      )

    {:ok, r}
  end

  def org_processing_templates(%{org: org}, _, _) do
    org = Repo.preload(org, [:email_backend])

    case Proca.Service.EmailTemplateDirectory.list_names(org) do
      lst -> {:ok, lst}
    end
  end

  def update_org_processing(_, args, %{context: %{org: org}}) do
    args =
      args
      |> Helper.rename_key(:sqs_deliver, :system_sqs_deliver)

    Org.changeset(org, args)
    |> Repo.update_and_notify()
  end

  def upsert_template(_, %{input: params}, %{context: %{org: org}}) do
    alias Proca.Service.EmailTemplate

    tmpl =
      EmailTemplate.one(org: org, name: params.name, locale: Map.get(params, :locale)) ||
        %EmailTemplate{org: org}

    tmpl =
      tmpl
      |> EmailTemplate.changeset(params)
      |> Repo.insert_or_update()

    case tmpl do
      {:error, _} = e ->
        e

      {:ok, t} ->
        Proca.Server.Notify.updated(t, [])
        {:ok, :success}
    end
  end

  def add_org(_, %{input: params}, %{context: %{auth: %Auth{user: user}}}) do
    %{email_backend: instance_email_backend} = Org.one([:instance] ++ [preload: [:email_backend]])

    defaults = %{
      email_from: user.email,
      email_backend: instance_email_backend
    }

    result =
      Multi.new()
      |> Multi.insert(:org, Org.changeset(%Org{}, Map.merge(defaults, params)))
      |> Multi.insert(:staffer, fn %{org: org} ->
        Staffer.changeset(%{user: user, org: org, role: :owner})
      end)
      |> Repo.transaction_and_notify(:user_created_org)

    case result do
      {:ok, %{org: org, staffer: staffer}} ->
        %Auth{user: user, staffer: staffer}
        |> ChangeAuth.return({:ok, org})

      {:error, _error} = e ->
        e
    end
  end

  def delete_org(_, _, %{context: %{org: org}}) do
    # Try to delete campaigns of this org but do not fail if you can't
    campaigns = Campaign.all(org: org)

    for c <- campaigns do
      Repo.transaction_and_notify(Campaign.delete(c), :delete_campaign)
    end

    action_pages = ActionPage.all(org: org)

    for ap <- action_pages do
      Repo.transaction_and_notify(ActionPage.delete(ap), :delete_action_page)
    end

    case Repo.delete_and_notify(Org.delete(org)) do
      {:ok, _removed} -> {:ok, :success}
      e -> e
    end
  end

  def update_org(_p, %{input: attrs}, %{context: %{org: org}}) do
    Org.changeset(org, attrs)
    |> Repo.update_and_notify()
  end

  def list_keys(org_id, criteria) do
    from(pk in PublicKey,
      where: pk.org_id == ^org_id,
      select: %{
        id: pk.id,
        name: pk.name,
        public: pk.public,
        active: pk.active,
        expired: pk.expired,
        updated_at: pk.updated_at
      },
      order_by: [desc: :inserted_at]
    )
    |> PublicKey.filter(criteria)
  end

  def list_keys(%{id: org_id}, params, _) do
    {
      :ok,
      list_keys(org_id, Map.get(params, :select, []))
      |> Repo.all()
      |> Enum.map(&format_key/1)
    }
  end

  def format_key(pk) do
    pk
    |> Map.put(:public, PublicKey.base_encode(pk.public))
    |> Map.put(
      :private,
      if Map.get(pk, :private, nil) do
        PublicKey.base_encode(pk.private)
      else
        nil
      end
    )
    |> Map.put(
      :expired_at,
      if pk.expired do
        pk.updated_at
      else
        nil
      end
    )
  end

  def list_services(org_id) when is_number(org_id) do
    from(s in Service,
      where: s.org_id == ^org_id,
      order_by: s.id
    )
  end

  def list_services(%{id: org_id}, _, _) do
    {
      :ok,
      list_services(org_id)
      |> Repo.all()
    }
  end

  def get_key(%{id: org_id}, %{select: criteria}, _) do
    case list_keys(org_id, criteria) |> Repo.one() do
      nil -> {:error, "not_found"}
      k -> {:ok, format_key(k)}
    end
  end

  # XXX fix error handling
  def sample_email(%{action_id: id}, email) do
    with a when not is_nil(a) <-
           Repo.one(
             from(a in Action,
               where: a.id == ^id,
               preload: [action_page: [org: [email_backend: :org]], supporter: :contacts]
             )
           ),
         ad <- Proca.Stage.Support.action_data(a),
         recp <-
           Proca.Service.EmailBackend.make_email({a.supporter.first_name, email}, {:action, a.id})
           |> Proca.Service.EmailMerge.put_action_message(ad),
         %{thank_you_template: tm} <- a.action_page,
         {:ok, tmpl} <- Proca.Service.EmailTemplateDirectory.by_name_reload(a.action_page.org, tm) do
      Proca.Service.EmailBackend.deliver([recp], a.action_page.org, tmpl)
    else
      e -> error("sample email", e)
    end
  end

  def add_key(_, %{input: %{name: name, public: public}}, %{context: %{org: org}}) do
    with ch = %{valid?: true} <- PublicKey.import_public_for(org, public, name),
         {:ok, key} <- Repo.insert(ch) do
      {:ok, format_key(key)}
    else
      ch = %{valid?: false} -> {:error, Helper.format_errors(ch)}
      {:error, ch} -> {:error, Helper.format_errors(ch)}
    end
  end

  # If we modify the instance org, keep the private key
  defp dont_store_private(%Org{name: name}, pk) do
    if Application.get_env(:proca, Proca)[:org_name] == name do
      pk
    else
      change(pk, private: nil)
    end
  end

  def generate_key(_, %{input: %{name: name}}, %{context: %{org: org}}) do
    with pk = %{valid?: true} <- PublicKey.build_for(org, name),
         pub_prv_pk <- apply_changes(pk),
         {:ok, pub_pk} <- dont_store_private(org, pk) |> Repo.insert() do
      {:ok, format_key(%{pub_prv_pk | id: pub_pk.id})}
    else
      ch = %{valid?: false} -> {:error, Helper.format_errors(ch)}
      {:error, ch} -> {:error, Helper.format_errors(ch)}
    end
  end

  def activate_key(_, %{id: id}, %{context: %{org: org}}) do
    case Repo.get_by(PublicKey, id: id, org_id: org.id) do
      nil ->
        {:error,
         %{
           message: "Public key not found",
           extensions: %{code: "not_found"}
         }}

      %{expired: true} ->
        {:error,
         %{
           message: "Public key expired",
           extensions: %{code: "expired"}
         }}

      %PublicKey{} ->
        PublicKey.activate_for(org, id)
        |> Repo.transaction_and_notify(:key_activated)

        {:ok, %{status: :success}}
    end
  end

  def join_org(_, _, %{context: %{org: org, auth: %Auth{user: user}}}) do
    joining =
      case Staffer.one(user: user, org: org, preload: [:org, :user]) do
        nil -> Staffer.changeset(%{user: user, org: org, role: :owner})
        st = %Staffer{} -> Staffer.changeset(st, %{role: :owner})
      end

    case Repo.insert_or_update(joining) do
      {:ok, joined} ->
        %Auth{user: user, staffer: joined}
        |> ChangeAuth.return({:ok, %{status: :success, org: org}})

      {:error, _} = e ->
        e
    end
  end
end
