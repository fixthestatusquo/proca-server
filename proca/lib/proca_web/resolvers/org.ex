defmodule ProcaWeb.Resolvers.Org do
  @moduledoc """
  Resolvers for org { } root query
  """
  # import Ecto.Query
  import Ecto.Query
  import Ecto.Changeset

  alias Proca.{ActionPage, Campaign, Action}
  alias Proca.{Org, Staffer, PublicKey}
  alias ProcaWeb.Helper
  alias Ecto.Multi
  alias Proca.Server.Notify

  alias Proca.Repo
  import Proca.Staffer.Permission
  import Logger

  def get_by_name(_, _, %{context: %{org: org}}) do
    {
      :ok,
      Repo.preload(org, [[campaigns: :org], :action_pages])
    }
  end

  def campaign_by_id(org, %{id: camp_id}, _) do
    c =
      Campaign.select_by_org(org)
      |> where([c], c.id == ^camp_id)
      |> Repo.one()

    case c do
      nil -> {:error, "not_found"}
      c -> {:ok, c}
    end
  end

  def campaigns(org, _, _) do
    cl =
      Campaign.select_by_org(org)
      |> preload([c], [:org])
      |> Repo.all()

    {:ok, cl}
  end

  def action_pages(org, _, _) do
    c = Ecto.assoc(org, :action_pages)
    |> preload([ap], [:org])
    |> Repo.all

    {:ok, c}
  end

  def action_page(%{id: org_id}, params, _) do
    case ProcaWeb.Resolvers.ActionPage.find(nil, params, nil) do
      {:ok, %ActionPage{org_id: ^org_id}} = ret ->
        ret

      {:ok, %ActionPage{}} ->
        {:error,
         %{
           message: "Action page not found",
           extensions: %{code: "not_found"}
         }}

      {:error, x} ->
        {:error, x}
    end
  end

  def org_personal_data(org, _args, _ctx) do
    {
      :ok,
      %{
        contact_schema: org.contact_schema,
        email_opt_in: org.email_opt_in,
        email_opt_in_template: org.email_opt_in_template
      }
    }
  end

  def add_org(_, %{input: params}, %{context: %{user: user}}) do
    with {:ok, org} <- Org.changeset(%Org{}, params) |> Repo.insert(),
         perms <- Staffer.Role.permissions(:owner),
         {:ok, _staffer} <- Staffer.build_for_user(user, org.id, perms) |> Repo.insert()
      do
      {:ok, org}
    else
      {:error, changeset} -> {:error, Helper.format_errors(changeset)}
    end
  end

  def delete_org(_, _, %{context: %{org: org}}) do
    case Repo.delete(org) do
      {:ok, _} -> {:ok, true}
      {:error, ch} -> {:error, Helper.format_errors(ch)}
    end
  end

  def update_org(_p, %{input: attrs}, %{context: %{org: org}}) do
    case Org.changeset(org, attrs) |> Repo.update()
      do
      {:error, ch} -> {:error, Helper.format_errors(ch)}
      {:ok, org} 
    end
  end

  def list_keys(org_id, criteria) do
    from(pk in PublicKey,
      where: pk.org_id == ^org_id,
      select: %{id: pk.id,
                name: pk.name,
                public: pk.public,
                active: pk.active,
                expired: pk.expired,
                updated_at: pk.updated_at},
      order_by: [desc: :inserted_at]
    )
    |> PublicKey.filter(criteria)
  end

  def format_key(pk) do
    pk
    |> Map.put(:public, PublicKey.base_encode(pk.public))
    |> Map.put(:private, if Map.get(pk, :private, nil) do PublicKey.base_encode(pk.private) else nil end)
    |> Map.put(:expired_at, if pk.expired do pk.updated_at else nil end)
  end

  def list_keys(%{id: org_id}, params, _) do
    {
      :ok,
      list_keys(org_id, Map.get(params, :select, []))
      |> Repo.all()
      |> Enum.map(&format_key/1)
    }
  end

  def get_key(%{id: org_id}, %{select: criteria}, _) do
    case list_keys(org_id, criteria) |> Repo.one do
      nil -> {:error, "not_found"}
      k -> {:ok, format_key(k)}
    end
  end

  def sample_email(%{action_id: id}, email) do
    with a when not is_nil(a) <- Repo.one(from(a in Action, where: a.id == ^id,
                 preload: [action_page:
                           [org:
                            [email_backend: :org]
                           ]
                          ])),
         ad <- Proca.Stage.Support.action_data(a),
           recp <- %{Proca.Service.EmailRecipient.from_action_data(ad) | email: email},
           %{thank_you_template_ref: tr} <- a.action_page,
           tmpl <- %Proca.Service.EmailTemplate{ref: tr}
      do
      Proca.Service.EmailBackend.deliver([recp], a.action_page.org, tmpl)
      else
        e -> error("sample email", e)
    end

  end

  def add_key(_, %{input: %{name: name, public: public}}, %{context: %{org: org}}) do
    with ch = %{valid?: true} <- PublicKey.import_public_for(org, public, name),
         {:ok, key} <- Repo.insert(ch)
      do
      {:ok, key}
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
         {:ok, pub_pk} <- dont_store_private(org, pk) |> Repo.insert()
      do
      {:ok,
       format_key(%{pub_prv_pk | id: pub_pk.id})
      }
      else
        ch = %{valid?: false} -> {:error, Helper.format_errors(ch)}
        {:error, ch} -> {:error, Helper.format_errors(ch)}
    end
  end

  def activate_key(_, %{id: id}, %{context: %{org: org}}) do
    case Repo.get_by PublicKey, id: id, org_id: org.id do
      nil ->
        {:error, %{
            message: "Public key not found",
            extensions: %{code: "not_found"}
         }}
      %{expired: true} ->
        {:error, %{
            message: "Public key expired",
            extensions: %{code: "expired"}
         }}
      pk = %PublicKey{} ->
        pk = PublicKey.activate_for(org, id)
        Notify.public_key_activated(org, pk)
        {:ok, %{status: :success}}
    end
  end
end
