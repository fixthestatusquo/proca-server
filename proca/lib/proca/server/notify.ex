defmodule Proca.Server.Notify do
  @moduledoc """
  Server that decides what actions should be done after different events
  """
  alias Proca.Repo
  alias Proca.{Action, Supporter, Org, PublicKey, Confirm, Service}
  alias Proca.Stage.Event
  alias Proca.Pipes
  import Logger


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
  def instance_org_updated(org) do
    Proca.Server.Instance.update(org)
  end

  def org_created(org = %Org{}) do
    start_org_pipes(org)
  end

  def org_updated(org = %Org{}, changeset) do
    restart_org_pipes(org, changeset)
    if org.name == Org.instance_org_name, do: instance_org_updated(org)
   end

  def org_deleted(org = %Org{}) do
    stop_org_pipes(org)
  end

  def org_confirm_created(cnf = %Confirm{}, org = %Org{}) do
    confirm_notify(cnf, org)
  end

  @spec action_created(%Action{}, %Supporter{} | nil) :: :ok
  def action_created(action, supporter \\ nil) do
    increment_counter(action, supporter)
    process_action(action)
    update_action_page_status(action)
    :ok
  end

  @spec public_key_created(Org, PublicKey) :: :ok
  def public_key_created(org, key) do
    :ok
  end

  @spec public_key_activated(Org, PublicKey) :: :ok
  def public_key_activated(org, key) do
    Proca.Server.Keys.update_key(org, key)
  end

  def action_page_added(action_page) do
    action_page_updated(action_page)
  end

  def action_page_updated(action_page) do
    action_page = Repo.preload(action_page, [:org, :campaign])
    publish_subscription_event(action_page, action_page_upserted: "$instance")
    if not is_nil(action_page.org) do
      publish_subscription_event(action_page, action_page_upserted: action_page.org.name)
    end
    :ok
  end

  # XXX add Campaign



  ##### SIDE EFFECTS ######

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

  def restart_org_pipes(org = %Org{}, %Ecto.Changeset{changes: changes}) do
    relevant_changes = Enum.any?([
      :email_backend_id, # transactional emails
      :email_template_id,
      :system_sqs_deliver,
      :custom_supporter_confirm,
      :custom_action_confirm,
      :custom_action_deliver,
      :email_opt_in,
      :email_opt_in_template,
      :event_backend_id,
      :event_processing,
      :confirm_processing
    ], fn prop -> Map.has_key?(changes, prop) end)

    if relevant_changes do
      Pipes.Supervisor.terminate_child(org)
      Pipes.Supervisor.start_child(org)
    end
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
