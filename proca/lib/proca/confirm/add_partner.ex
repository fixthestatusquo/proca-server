defmodule Proca.Confirm.AddPartner do 
  @moduledoc """
  Invite an org to join a campaign, by creating an action page based off action page subject_id

  """
  alias Proca.{Action, ActionPage, Confirm, Staffer, Auth}
  @behaviour Confirm.Operation
  import Proca.Changeset 
  import Proca.Repo
  import ProcaWeb.Helper, only: [has_error?: 3, cant_msg: 1, msg_ext: 2]
  import Proca.Permission, only: [can?: 2]

  @doc """
  # Inviting to a campaign (by email)
  
  add_partnern(action_page, nil, email) 
  - confirms this use     --- -----^   
  - times: 1
 
  # Inviting to a campaign (open)
  clone_action_page(action_page, nil)
  """
  def create(%ActionPage{id: id, campaign: _camp}, email) when is_bitstring(email) do
    %{
      operation: :add_partner, 
      subject_id: id,
      email: email
    } |> Confirm.create()
  end

  def try_create_copy(org, page, new_name, tryno \\ 0) do 
    name = if tryno > 0, do: new_name <> "-#{tryno}", else: new_name

    case ActionPage.create_copy_in(org, page, %{name: name}) do 
      {:ok, p} -> {:ok, p}
      {:error, ch = %{errors: errors}} -> 
        if has_error?(errors, :name, "has already been taken") do
          try_create_copy(org, page, new_name, tryno + 1)
        else 
          {:error, ch}
        end
    end
  end

  @impl true
  def run(%Confirm{operation: :add_partner}, :confirm, nil) do 
    {:error, "unauthorized"}
  end

  @impl true
  def run(%Confirm{operation: :add_partner, subject_id: ap_id}, :confirm, %Auth{staffer: st}) do
    org = Ecto.assoc(st, :org) |> one()
    with page = %ActionPage{} <- get(ActionPage, ap_id), 
         true <- can?(st, [:manage_action_pages])
    do
      new_name = org.name <> "/" <> ActionPage.name_path(page.name)
      try_create_copy(org, page, new_name) 
    else 
      nil -> {:error, msg_ext("action page not found", "not_found") }
      false -> {:error, cant_msg([:manage_action_pages])}
    end
  end

  @impl true
  def run(%Confirm{operation: :add_partner}, :reject, _), do: :ok

  @impl true
  def email_template(%Confirm{operation: :add_partner}), do: "add_partner"

  @impl true 
  def email_fields(_), do: %{}
end
