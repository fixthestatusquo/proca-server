defmodule Proca.Signature do
  use Ecto.Schema
  import Ecto.Changeset

  schema "signatures" do
    belongs_to :campaign, Proca.Campaign
    belongs_to :action_page, Proca.ActionPage
    belongs_to :source, Proca.Source
    
    many_to_many(
      :contacts,
      Proca.Contact,
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
