defmodule Proca.Server.Notify do
  @moduledoc """
  Server that decides what actions should be done after different events
  """
  alias Proca.Repo
  alias Proca.{Action, Supporter, Org, PublicKey, Confirm, Service, ActionPage, Campaign}
  alias Proca.Stage.Event
  alias Proca.Pipes
  import Logger

  # Instance wide notification settings

  @type global_confirm_processing?() :: {boolean, number}
  defp global_confirm_processing?() do
    instance = Proca.Server.Instance.org()
    if instance != nil do
      {instance.confirm_processing, instance.id}
    else
      {false, nil}
    end
  end

  ####################

  @doc """
  Notifications on creation of record
  """
  def created(org = %Org{}) do
    start_org_pipes(org)
  end

  def created(%ActionPage{} = action_page) do
    updated(action_page)
  end

  def created(%Confirm{operation: :launch_page, subject_id: campaign_id} = cnf) do
    case Campaign.one(id: campaign_id, preload: [:org]) do
      nil -> :ok
      %Campaign{org: %Org{} = org} -> confirm_notify(cnf, org)
    end
  end


  def created(_), do: :ok


  @doc """
  Notifications on update of record
  """
  def updated(org = %Org{}) do
    restart_org_pipes(org)
    if org.name == Org.instance_org_name, do: instance_org_updated(org)
  end

  def updated(%ActionPage{} = action_page) do
    action_page = Repo.preload(action_page, [:org, :campaign])
    publish_subscription_event(action_page, action_page_upserted: "$instance")
    if not is_nil(action_page.org) do
      publish_subscription_event(action_page, action_page_upserted: action_page.org.name)
    end
    :ok
  end

  def updated(%PublicKey{active: true} = key) do
    key_activated(key)
  end

  def updated(_), do: :ok



  @doc """
  Notifications on deletion of record
  """
  def deleted(org = %Org{}) do
    stop_org_pipes(org)
  end
  def deleted(_), do: :ok


  def multi(op, %{action: action})
  when op in [:add_action, :add_action_contact] do
    increment_counter(action, action.supporter)
    process_action(action)
    update_action_page_status(action)
    :ok
  end

  def multi(:key_activated, %{active_key: key}) do
    key_activated(key)
  end

  def multi(:upsert_campaign, records) do
    {campaign, pages_map} = Map.pop(records, :campaign)

    updated(campaign)
    Enum.each(pages_map, fn {_k, page} ->
      updated(page)
    end)
  end

  def multi(:user_created_org, %{org: org}) do
    created(org)
  end

  ##### SIDE EFFECTS ######
  def instance_org_updated(org) do
    Proca.Server.Instance.update(org)
  end

  def key_activated(%PublicKey{active: true, org: org} = key) do
    Proca.Server.Keys.update_key(org, key)
  end

  def confirm_notify(cnf, org) do
    {global, instance_org_id} = global_confirm_processing?()

    if not global and not org.confirm_processing do
      send_confirm_by_email(cnf, org)
    else
      if global, do: send_confirm_as_event(cnf, instance_org_id)
      if org.confirm_processing, do: send_confirm_as_event(cnf, org.id)
    end
  end

  def send_confirm_as_event(cnf, org_id) do
      Event.emit(:confirm_created, cnf, org_id)
  end

  def send_confirm_by_email(cnf, org) do
    recipients =
      Repo.preload(org, [staffers: :user]).staffers
      |> Enum.map(fn %{user: user} -> user.email end)


    cnf = Repo.preload(cnf, [:creator])
    Proca.Confirm.notify_by_email(cnf, recipients)
   end


  def start_org_pipes(org = %Org{}) do
      Pipes.Supervisor.start_child(org)
  end

  def restart_org_pipes(org = %Org{}) do
    Pipes.Supervisor.reload_child(org)
  end

  def stop_org_pipes(org = %Org{}) do
    Pipes.Supervisor.terminate_child(org)
  end


  defp process_action(action) do
    Proca.Server.Processing.process_async(action)
  end

  defp update_action_page_status(action) do 
    Proca.ActionPage.Status.track_action(action)
  end

  defp increment_counter(%Action{campaign_id: cid, action_page: %{org_id: org_id}, action_type: atype}, nil) do
    Proca.Server.Stats.increment(cid, org_id, atype, nil, false)
  end

  defp increment_counter(%Action{campaign_id: cid, action_page: %{org_id: org_id}, action_type: atype}, %Supporter{area: area}) do
    Proca.Server.Stats.increment(cid, org_id, atype, area, true)
  end


  defp publish_subscription_event(record, routing_key) do
    Absinthe.Subscription.publish(ProcaWeb.Endpoint, record, routing_key)
  end
end
