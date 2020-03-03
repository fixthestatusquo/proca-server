defmodule Proca.Staffer do
  use Ecto.Schema
  import Ecto.Changeset

  schema "staffers" do
    field :perms, :integer
    belongs_to :org, Proca.Org
    belongs_to :user, Proca.Users.User

    timestamps()
  end

  @doc false
  def changeset(staffer, attrs) do
    staffer
    |> cast(attrs, [:perms])
    |> validate_required([:perms])
  end
end
