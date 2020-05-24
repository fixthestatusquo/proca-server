defmodule Proca.Action  do
  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query
  alias Proca.{Action, Supporter, Field}
  alias Proca.Repo


  schema "actions" do
    field :ref, :binary
    belongs_to :supporter, Proca.Supporter

    field :action_type, :string
    field :delivery, :boolean

    belongs_to :campaign, Proca.Campaign
    belongs_to :action_page, Proca.ActionPage
    belongs_to :source, Proca.Source

    has_many :fields, Proca.Field

    timestamps()
  end

  defp put_supporter_or_ref(ch, supporter = %Supporter{}, _action_page) do
    ch
    |> put_assoc(:supporter, supporter)
  end

  defp put_supporter_or_ref(ch, contact_ref, action_page) when is_bitstring(contact_ref) do
    case Supporter.find_by_fingerprint(contact_ref, action_page.org_id) do
      %Supporter{} = supporter -> put_assoc(ch, :supporter, supporter)
      nil -> put_change(ch, :ref, contact_ref)
    end
  end

  def create_for_supporter(attrs, supporter, action_page) do
    %Action{}
    |> cast(attrs, [:action_type])
    |> put_supporter_or_ref(supporter, action_page)
    |> put_assoc(:action_page, action_page)
    |> put_change(:campaign_id, action_page.campaign_id)
    |> put_assoc(:fields, Field.changesets(attrs.fields))
  end

  def link_refs_to_supporter(refs, %Supporter{id: id}) when not is_nil(id) and is_list(refs) do
    from(a in Action, where: is_nil(a.supporter_id) and a.ref in ^refs)
    |> Repo.update_all(set: [supporter_id: id, ref: nil])
  end
end
