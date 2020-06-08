defmodule Proca.Users.User do
  use Ecto.Schema
  use Pow.Ecto.Schema

  schema "users" do
    pow_user_fields()

    has_many :staffers, Proca.Staffer

    timestamps()
  end
end
