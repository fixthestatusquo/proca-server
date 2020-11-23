defmodule ProcaWeb.Resolvers.Org do
  @moduledoc """
  Resolvers for org { } root query
  """
  # import Ecto.Query
  import Ecto.Query

  alias Proca.{ActionPage, Campaign, Action}
  alias Proca.{Org, Staffer, PublicKey}

  alias Proca.Repo
  import Proca.Staffer.Permission
  import Logger

  def get_by_name(_, %{name: name}, %{context: %{user: user}}) do
    with %Org{} = org <- Org.get_by_name(name, [[campaigns: :org], :action_pages]),
         %Staffer{} = s <- Staffer.for_user_in_org(user, org.id),
         true <- can?(s, :use_api) do
      {:ok, org}
    else
      _ -> {:error, "Access forbidden"}
    end
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
    c =
      Ecto.assoc(org, :action_pages)
      |> preload([ap], [:org])
      |> Repo.all()
      |> Enum.map(&ActionPage.stringify_config(&1))

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

  def update_org(_p, attrs = %{name: name}, %{context: %{user: user}}) do
    with %Org{} = org <- Org.get_by_name(name),
         %Staffer{} = s <- Staffer.for_user_in_org(user, org.id),
         true <- can?(s, :use_api) do
      Org.changeset(org, attrs)
      |> Repo.update()
    else
      _ -> {:error, "Access forbidden"}
    end
  end

  def list_keys(%{id: org_id}, _, %{context: %{user: user}}) do
    with %Staffer{} = s <- Staffer.for_user_in_org(user, org_id),
         true <- can?(s, [:use_api, :export_contacts]) do
      {
        :ok,
        from(pk in PublicKey,
          where: pk.org_id == ^org_id,
          select: %{id: pk.id, name: pk.name, public: pk.public, expired_at: pk.expired_at}
        )
        |> Repo.all()
        |> Enum.map(&Map.put(&1, :public, PublicKey.base_encode(&1.public)))
      }
    else
      _ -> {:error, "Access forbidden"}
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
end
