defmodule Proca.Users.User do
  use Ecto.Schema
  use Pow.Ecto.Schema
  alias Proca.Users.StrongPassword

  schema "users" do
    pow_user_fields()

    has_many :staffers, Proca.Staffer

    timestamps()
  end

  def params_for(email) do
    pwd = StrongPassword.generate()
    %{
      email: email,
      password: pwd,
      password_confirmation: pwd
    }
  end
end
