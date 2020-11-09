ExUnit.start()
Ecto.Adapters.SQL.Sandbox.mode(Proca.Repo, :auto)
{:ok, _} = Application.ensure_all_started(:ex_machina)
{:ok, _} = Application.ensure_all_started(:amqp_client)

Absinthe.Test.prime(ProcaWeb.Schema)
