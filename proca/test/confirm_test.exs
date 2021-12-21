defmodule ConfirmTest do
  use ProcaWeb.ConnCase
  import Ecto.Query
  alias Proca.Repo
  alias Proca.Confirm
  alias Proca.Factory
  import Proca.StoryFactory, only: [red_story: 0]

  describe "Confirm schema" do
    test "has 1 charge normally" do
      action = Factory.insert(:action)
      cnf = Confirm.insert!(Confirm.ConfirmAction.changeset(action))
      assert cnf.charges == 1
      assert cnf.subject_id == action.id
      assert is_nil(cnf.object_id)
      assert is_nil(cnf.email)
      assert not is_nil(cnf.code)
      assert String.length(cnf.code) >= 8
    end

    test "can't go under 0 charges" do
      action = Factory.insert(:action, processing_status: :confirming)

      cnf = Confirm.insert!(Confirm.ConfirmAction.changeset(action))
      assert :ok == Confirm.confirm(cnf)

      # reload with charge == 0 
      cnf = Repo.reload(cnf)
      assert cnf.charges == 0
      assert {:error, "expired"} == Confirm.confirm(cnf)
    end
  end

  describe "confirm add partner" do
    setup do
      red_story()
    end

    test "via api", %{conn: conn, red_org: red_org, red_bot: red_bot, yellow_ap: yellow_ap} do
      cnf = Confirm.AddPartner.changeset(yellow_ap, red_bot.user.email) |> Confirm.insert!()
      assert not is_nil(cnf.code)
      assert is_nil(cnf.object_id)
      assert cnf.subject_id == yellow_ap.id

      query = """
        mutation Conf {
          acceptOrgConfirm(
            name: "#{red_org.name}", 
            confirm: {code: "#{cnf.code}", email: "#{cnf.email}"}
          )
          { status, actionPage {id, name} }
        } 
      """

      res = conn |> auth_api_post(query, red_bot.user)
      data = Jason.decode!(res.resp_body)

      assert data["data"]["acceptOrgConfirm"]["actionPage"]["name"] == "#{red_org.name}/sign"

      new_ap =
        from(ap in Proca.ActionPage,
          where: ap.org_id == ^red_org.id,
          order_by: [desc: :id],
          limit: 1
        )
        |> Repo.one()

      assert new_ap.id == data["data"]["acceptOrgConfirm"]["actionPage"]["id"]
    end
  end
end
