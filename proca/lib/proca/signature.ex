defmodule Proca.Signature do
  use Ecto.Schema
  import Ecto.Changeset

  schema "signatures" do
    field :campaign_id, :id
    
    many_to_many(
      :contacts,
      Contact,
      join_through: "contact_signatures",
      on_replace: :delete
    )


    timestamps()
  end

  @doc false
  def changeset(signature, attrs) do
    signature
    |> cast(attrs, [])
    |> validate_required([])
  end
end
