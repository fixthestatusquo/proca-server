defmodule Proca.Confirm.Operation do
  @moduledoc """

  Each confirmable operation works a bit differently, so modules in
  Proca.Confirm.* implement the spefics. Thye fallow this behaviour.

  """

  alias Proca.Confirm
  alias Proca.Auth
  alias Proca.{ActionPage, Campaign}

  @doc """
  Run the operation, after it is accepted (verb = :confirm) or rejected (verb = :reject).
  auth contains current Proca.Auth context.
  """
  def run(%Confirm{operation: op} = cnf, verb, auth) do
    apply(mod(op), :run, [cnf, verb, auth])
  end

  @doc "Select the module implementing behaviour for operation op"
  def mod(%Confirm{operation: op}), do: mod(op)

  def mod(:add_partner), do: Proca.Confirm.AddPartner
  def mod(:confirm_action), do: Proca.Confirm.ConfirmAction
  def mod(:launch_page), do: Proca.Confirm.LaunchPage
  def mod(:add_staffer), do: Proca.Confirm.AddStaffer

  @callback run(%Confirm{}, :confirm | :reject, Auth) :: 
    :ok | {:ok, %ActionPage{}} | {:ok, %Campaign{}}, {:ok, %Org{}} | {:error, any()}

  @doc "Return name of email template used in notification about this confirmable operation"
  @callback email_template(%Confirm{}) :: String.t()

  @doc "Return map of fields used in notification about this confirmable operation (email or event)"
  @callback notify_fields(%Confirm{}) :: map()
end
