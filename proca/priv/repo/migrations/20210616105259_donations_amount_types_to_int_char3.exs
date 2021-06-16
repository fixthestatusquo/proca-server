defmodule Proca.Repo.Migrations.DonationsAmountTypesToIntChar3 do
  use Ecto.Migration

  def change do
    amount_up = "alter table donations alter column amount type int using (amount*100)::int"
    amount_dn = "alter table donations alter column amount type numeric using (amount/100)::numeric"
    currency_up = "alter table donations alter column currency type char(3)"
    currency_dn = "alter table donations alter column currency type text"

    execute amount_up, amount_dn 
    execute currency_up, currency_dn
  end
end
