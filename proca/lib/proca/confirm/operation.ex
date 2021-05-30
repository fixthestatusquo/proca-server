defmodule Proca.Confirm.Operation do 
  alias Proca.Confirm

  def run(%Confirm{operation: op} = cnf, verb, sup) do 
    apply(mod(op), :run, [cnf, verb, sup])
  end

  def mod(:add_partner), do: Proca.Confirm.AddPartner
  def mod(:confirm_action), do: Proca.Confirm.ConfirmAction
end 
