defmodule ProcaWeb.Resolvers.Org do
  @moduledoc """
  Resolvers for org { } root query
  """
  # import Ecto.Query
  import Ecto.Query
  import Ecto.Changeset

  alias Proca.{ActionPage, Campaign, Action}
  alias Proca.{Org, Staffer, PublicKey, Service}
  alias ProcaWeb.Helper
  alias Ecto.Multi
  alias Proca.Server.Notify

  alias Proca.Repo
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

  def action_pages_select(query, %{select: %{campaign_id: cid}}) do
    query
    |> where([ap], ap.campaign_id == ^cid)
  end

  def action_pages_select(query, _) do
    query
  end

  def action_pages(org, params, _) do
    c = Ecto.assoc(org, :action_pages)
    |> action_pages_select(params)
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
    perms = Staffer.Role.permissions(:owner)

    op = Multi.new()
    |> Multi.insert(:org, Org.changeset(%Org{}, params))
    |> Multi.insert(:staffer, fn %{org: org} ->
      Staffer.build_for_user(user, org.id, perms)
    end)

    case Repo.transaction(op) do
      {:ok, %{org: org}} ->
        Proca.Server.Notify.org_created(org)
        {:ok, org}
      {:error, _fail_op, fail_val, _ch} -> {:error, Helper.format_errors(fail_val)}
    end
  end

  def delete_org(_, _, %{context: %{org: org}}) do
    case Repo.delete(org) do
      {:ok, _} ->
        Proca.Server.Notify.org_deleted(org)
        {:ok, true}
      {:error, ch} -> {:error, Helper.format_errors(ch)}
    end
  end

  def update_org(_p, %{input: attrs}, %{context: %{org: org}}) do
    changeset = Org.changeset(org, attrs)
    case changeset |> Repo.update()
      do
      {:error, ch} -> {:error, Helper.format_errors(ch)}
      {:ok, org} ->
        Proca.Server.Notify.org_updated(org, changeset)
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
    |> Map.put(:private, if Map.get(pk, :private, nil) do PublicKey.base_encode(pk.private) else nil end)
    |> Map.put(:expired_at, if pk.expired do pk.updated_at else nil end)
  end

  def list_services(org_id) when is_number(org_id) do 
    from(s in Service, 
      where: s.org_id == ^org_id, 
      order_by: s.id)
  end

  def list_services(%{id: org_id}, _, _) do 
    {
      :ok,
      list_services(org_id)
      |> Repo.all()
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
      %PublicKey{} ->
        pk = PublicKey.activate_for(org, id)
        Notify.public_key_activated(org, pk)
        {:ok, %{status: :success}}
    end
  end

  def join_org(_, %{name: org_name}, %{context: %{user: user}}) do 
    with {:admin, 
          admin = %Staffer{perms: admin_perms}} <- {:admin, 
            Staffer.for_user_in_org(user, Org.instance_org_name)},
         true <- Staffer.Permission.can?(admin, :join_orgs),
         {:org, org = %Org{id: org_id}} <- {:org, Org.get_by_name(org_name)}  do 

    joining = 
    case Staffer.for_user_in_org(user, org_id) do 
      nil -> Staffer.build_for_user(user, org_id, admin_perms) |> Repo.insert()
      st = %Staffer{} -> change(st, perms: admin_perms) |> Repo.update()
    end

    case joining do 
      {:ok, _} -> {:ok, %{status: :success, org: org}}
      {:error, chg} -> {:error, Helper.format_errors(chg)}
    end 

    else
      {:org, nil} -> {:error, %{
        message: "Org not found",
        extensions: %{
          code: "not_found"
        }}}

      false -> {:error, %{
        message: "You need to have join_orgs permission to join orgs",
        extensions: %{
          code: "permission_denied"
        }}}

      {:admin, nil} -> {:error, %{
        message: "Only members of #{Org.instance_org_name} can join organisations",
        extensions: %{
          code: "permission_denied"
        }}}

    end 
  end
end
