defmodule ProcaWeb.Resolvers.TransactionalEmail do
  @moduledoc """
  Resolvers for transactional email settings. See `Proca.TransactionalEmail`.

  A setting can only be changed by the org that owns where it is stored:
  the org itself, the org leading the campaign, or the org of the page.
  The org is always the one in `orgName`, so rows of other orgs are refused.
  An existing setting is picked by its id, or by role + level
  (campaignName / actionPageId, neither = the org).
  Org-level settings additionally need `change_org_settings`.
  """

  alias Proca.{Org, Campaign, ActionPage, Permission}
  alias Proca.TransactionalEmail, as: TE
  alias ProcaWeb.Error

  @doc "Field `transactionalEmails` on org, campaign and action page"
  def list(scope, args, _ctx) do
    case get_in(args, [:select, :role]) do
      nil -> {:ok, TE.chain_all(scope)}
      role -> {:ok, TE.chain(role, scope)}
    end
  end

  def add(_, args = %{role: role, input: input}, %{context: %{org: org, auth: auth}}) do
    with {:ok, scope} <- find_scope(org, args),
         :ok <- can_change(scope, auth) do
      TE.add(scope, role, input)
    end
  end

  @doc "Field `transactionalEmail` on org: one stored setting, by id or by role + level"
  def get(%Org{} = org, args, _ctx), do: find_existing(org, args)

  def update(_, args = %{input: input}, %{context: %{org: org, auth: auth}}) do
    with {:ok, te} <- find_existing(org, args),
         :ok <- can_change(te, auth) do
      TE.update(te, input)
    end
  end

  def delete(_, args, %{context: %{org: org, auth: auth}}) do
    with {:ok, te} <- find_existing(org, args),
         :ok <- can_change(te, auth),
         {:ok, _} <- TE.delete(te) do
      {:ok, :success}
    end
  end

  # --- Scope and ownership ------------------------------------------------

  # A stored setting is picked either by its id, or by role + level
  # (no campaignName/actionPageId = the org level), never both.
  defp find_existing(org, args) do
    id = args[:id]
    by_key? = Enum.any?([:role, :campaign_name, :action_page_id], &(not is_nil(args[&1])))

    cond do
      not is_nil(id) and by_key? ->
        error("bad_arg", "Give id, or role (with campaignName or actionPageId), not both")

      not is_nil(id) ->
        find_row(org, id)

      is_nil(args[:role]) ->
        error("bad_arg", "Give id, or role (with campaignName or actionPageId)")

      true ->
        with {:ok, scope} <- find_scope(org, args) do
          case TE.get(scope, args.role) do
            nil ->
              error(
                "not_found",
                "No #{role_name(args.role)} setting at this level, use addTransactionalEmail"
              )

            te ->
              {:ok, te}
          end
        end
    end
  end

  defp role_name(role), do: role |> Atom.to_string() |> String.upcase()

  defp find_scope(_org, %{campaign_name: c, action_page_id: ap})
       when not is_nil(c) and not is_nil(ap),
       do: error("bad_arg", "Give campaignName or actionPageId, not both")

  defp find_scope(%Org{id: org_id}, %{campaign_name: name}) when not is_nil(name) do
    case Campaign.one(name: name) do
      nil ->
        error("not_found", "Campaign \"#{name}\" not found")

      %Campaign{org_id: ^org_id} = campaign ->
        {:ok, campaign}

      _ ->
        error(
          "permission_denied",
          "Campaign \"#{name}\" belongs to another org. Only the owner can manage its transactional emails."
        )
    end
  end

  defp find_scope(%Org{id: org_id}, %{action_page_id: id}) when not is_nil(id) do
    case ActionPage.one(id: id) do
      nil ->
        error("not_found", "Action page #{id} not found")

      %ActionPage{org_id: ^org_id} = ap ->
        {:ok, ap}

      _ ->
        error(
          "permission_denied",
          "Action page #{id} belongs to another org. Only that org can manage its transactional emails. " <>
            "To set it for every page of the campaign, use campaignName."
        )
    end
  end

  defp find_scope(org, _args), do: {:ok, org}

  defp find_row(%Org{id: org_id}, id) do
    case TE.one(id: id) do
      nil ->
        error("not_found", "Transactional email #{id} not found")

      %TE{org_id: ^org_id} = te ->
        {:ok, te}

      _ ->
        error("permission_denied", "Transactional email #{id} belongs to another org.")
    end
  end

  # Field-level allow already required change_campaign_settings.
  defp can_change(%Org{}, auth), do: org_level_allowed(auth)

  defp can_change(%TE{} = te, auth) do
    if TE.level(te) == :org, do: org_level_allowed(auth), else: :ok
  end

  defp can_change(_campaign_or_page, _auth), do: :ok

  defp org_level_allowed(auth) do
    if Permission.can?(auth, [:instance_owner]) or Permission.can?(auth, [:change_org_settings]) do
      :ok
    else
      error(
        "permission_denied",
        "You need change_org_settings to change org-level transactional emails"
      )
    end
  end

  defp error(code, message), do: {:error, %Error{code: code, message: message}}
end
