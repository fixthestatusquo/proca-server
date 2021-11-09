defmodule Proca.Confirm.Operation do 
  alias Proca.Confirm
  alias Proca.Auth
  alias Proca.{ActionPage, Campaign}

  def run(%Confirm{operation: op} = cnf, verb, sup) do 
    apply(mod(op), :run, [cnf, verb, sup])
  end

  def mod(%Confirm{operation: op}), do: mod(op)

  def mod(:add_partner), do: Proca.Confirm.AddPartner
  def mod(:confirm_action), do: Proca.Confirm.ConfirmAction
  def mod(:launch_page), do: Proca.Confirm.LaunchPage
  def mod(:add_staffer), do: Proca.Confirm.AddStaffer

  @callback run(%Confirm{}, :confirm | :reject, Auth) :: 
    :ok | {:ok, %ActionPage{}} | {:ok, %Campaign{}}, {:ok, %Org{}} | {:error, any()}

  @callback email_template(%Confirm{}) :: String.t()
  @callback notify_fields(%Confirm{}) :: map()

end 
