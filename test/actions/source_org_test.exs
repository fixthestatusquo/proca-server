defmodule Proca.Actions.SourceOrgTest do
  use Proca.DataCase

  alias Proca.Source

  @tracking %{
    source: "newsletter",
    medium: "email",
    campaign: "weekly",
    content: "",
    location: "https://saveoceans.org/reefmiracle"
  }

  test "the same tracking codes give one source per org" do
    org = insert(:org)
    other = insert(:org)

    {:ok, source} = Source.get_or_create_by(Map.put(@tracking, :org_id, org.id))
    {:ok, again} = Source.get_or_create_by(Map.put(@tracking, :org_id, org.id))
    {:ok, other_source} = Source.get_or_create_by(Map.put(@tracking, :org_id, other.id))

    assert source.id == again.id
    assert source.org_id == org.id
    assert other_source.id != source.id
    assert other_source.org_id == other.id
  end

  test "sources without an org are not mixed into an org source" do
    org = insert(:org)

    {:ok, orphan} =
      Source.get_or_create_by(%{@tracking | source: "twitter"} |> Map.put(:org_id, nil))

    {:ok, source} =
      Source.get_or_create_by(%{@tracking | source: "twitter"} |> Map.put(:org_id, org.id))

    assert orphan.org_id == nil
    assert source.org_id == org.id
    assert orphan.id != source.id
  end
end
