defmodule Proca.Repo do
  use Ecto.Repo,
    otp_app: :proca,
    adapter: Ecto.Adapters.Postgres
end
