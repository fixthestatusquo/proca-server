defmodule ProcaWeb.Api.ActionTest do
  use Proca.DataCase
  import Proca.StoryFactory, only: [blue_story: 0]
  import Ecto.Query

  alias Proca.{Repo, Action, Supporter}

  @basic_data %{}

  def make_petition_action(org, ap, action_info) do
    ref = Supporter.base_encode("fake_reference")

    params = %{
      action: action_info,
      action_page_id: ap.id,
      contact_ref: ref
    }

    result = ProcaWeb.Resolvers.Action.add_action(:unused, params, :unused)
    assert result = {:ok, %{contact_ref: ref}}
  end

  def make_signup_action(org, ap, action_info, contact_info) do
    params = %{
      action: action_info,
      action_page_id: ap.id,
      contact: contact_info
    }
  end

  test "create petition action without custom fields" do
    %{org: org, pages: [ap]} = blue_story()
    make_petition_action(org, ap, %{action_type: "petiton"})

    [action] =
      Repo.all(
        from(a in Action, order_by: [desc: :inserted_at], limit: 1, preload: [:fields, :supporter])
      )

    assert action.fields == []
    assert action.processing_status == :new
    assert action.action_page_id == ap.id
    assert action.campaign_id == ap.campaign_id
    assert is_nil(action.supporter)
  end

  test "create petition action with custom fields" do
    %{org: org, pages: [ap]} = blue_story()

    make_petition_action(org, ap, %{
      action_type: "petition",
      fields: [
        %{key: "extra_supporters", value: "5"},
        %{key: "card_url", value: "https://bucket.s3.amazon.com/1234/file.pdf"}
      ]
    })

    [action] =
      Repo.all(
        from(a in Action, order_by: [desc: :inserted_at], limit: 1, preload: [:fields, :supporter])
      )

    assert length(action.fields) == 2
    assert action.processing_status == :new
    assert action.action_page_id == ap.id
    assert action.campaign_id == ap.campaign_id
  end
end
