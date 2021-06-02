defmodule Proca.Confirm.Operation do 
  alias Proca.Confirm
  alias Proca.Staffer
  alias Proca.{ActionPage, Campaign, Org}

  def run(%Confirm{operation: op} = cnf, verb, sup) do 
    apply(mod(op), :run, [cnf, verb, sup])
  end

  def mod(%Confirm{operation: op}), do: mod(op)

  def mod(:add_partner), do: Proca.Confirm.AddPartner
  def mod(:confirm_action), do: Proca.Confirm.ConfirmAction
  def mod(:launch_page), do: Proca.Confirm.LaunchPage

  @callback run(%Confirm{}, :confirm | :reject, Staffer) :: 
    :ok | {:ok, %ActionPage{}} | {:ok, %Campaign{}}, {:ok, %Org{}} | {:error, any()}

  @callback email_template(%Confirm{}) :: string()
  @callback email_fields(%Confirm{}) :: map()

end 
