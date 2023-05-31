defmodule Proca.Stage.Requeue do
  @moduledoc """
  Tools to re-queue action directly into custom or delivery queue

  """

  alias Proca.{Org, Action}
  alias Proca.Stage.Processing
  alias Proca.Pipes.Connection
  import Proca.Stage.Support, only: [action_stage: 1, action_data: 3]

  @doc """
  Destinations:
   - :email_supporter - either confirmation or thank you email depending on processing status
   - :custom_supporter_confirm
   - :custom_action_confirm
   - :custom_action_deliver
   - :sqs
   - :webhook
  """
  def requeue(%Action{} = action, destination, %Org{} = org) when is_atom(destination) do
    action = Processing.preload(action)
    stage = action_stage(action)

    case routing_key(action, stage, destination) do
      rk when is_bitstring(rk) ->
        Connection.publish(action_data(action, stage, org.id), "", rk)

      :bad_stage_destination ->
        {:error,
         %{
           code: :bad_stage_destination,
           context: [
             stage: stage || :transient,
             destination: destination
           ]
         }}
    end
  end

  @spec routing_key(%Action{action_page: %{org: %Org{}}}, atom(), atom()) ::
          String.t() | :bad_stage_destination
  def routing_key(%{action_page: %{org: org}}, :supporter_confirm, :email_supporter) do
    Proca.Pipes.Topology.wqn(org, "email.supporter")
  end

  def routing_key(%{action_page: %{org: org}}, :deliver, :email_supporter) do
    Proca.Pipes.Topology.wqn(org, "email.supporter")
  end

  def routing_key(%{action_page: %{org: org}}, :supporter_confirm, :custom_supporter_confirm) do
    Proca.Pipes.Topology.cqn(org, "confirm.supporter")
  end

  def routing_key(%{action_page: %{org: org}}, :action_confirm, :custom_action_confirm) do
    Proca.Pipes.Topology.cqn(org, "confirm.action")
  end

  def routing_key(%{action_page: %{org: org}}, :deliver, :custom_action_deliver) do
    Proca.Pipes.Topology.cqn(org, "deliver")
  end

  def routing_key(%{action_page: %{org: org}}, :deliver, :sqs) do
    Proca.Pipes.Topology.wqn(org, "sqs")
  end

  def routing_key(%{action_page: %{org: org}}, :deliver, :webhook) do
    Proca.Pipes.Topology.wqn(org, "webhook")
  end

  def routing_key(_action, _stage, _destination) do
    :bad_stage_destination
  end
end
