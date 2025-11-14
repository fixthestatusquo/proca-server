defmodule Supporter.RejectionTest do
  use ProcaWeb.ConnCase
  alias Proca.{Repo, Supporter, Action}
  alias Proca.Factory
  import Proca.StoryFactory, only: [blue_story: 0]
  alias ProcaWeb.Router.Helpers, as: Routes

  @statuses [:new, :confirming, :accepted, :rejected, :delivered]
  @email_statuses [:none, :double_opt_in]

  setup %{conn: conn} do
    %{org: org, pages: [ap]} = blue_story()
    {:ok, conn: conn, ap: ap, org: org}
  end

  describe "Supporter rejection via URL" do
    for supporter_status <- @statuses do
      for action_status <- @statuses do
        email_statuses_to_test =
          case supporter_status do
            :accepted -> @email_statuses
            :delivered -> @email_statuses
            _ -> [:none]
          end

        for email_status <- email_statuses_to_test do
          test "supporter: #{supporter_status}, action: #{action_status}, email_status: #{email_status}, verb: reject",
               %{
                 conn: conn,
                 ap: ap
               } do
            supporter =
              Factory.insert(:basic_data_pl_supporter_with_contact,
                action_page: ap,
                processing_status: unquote(supporter_status),
                email_status: unquote(email_status)
              )

            action =
              Factory.insert(:action,
                supporter: supporter,
                action_page: ap,
                processing_status: unquote(action_status)
              )

            conn =
              get(
                conn,
                Routes.confirm_path(
                  conn,
                  :supporter,
                  action.id,
                  "reject",
                  Base.url_encode64(supporter.fingerprint)
                )
              )

            updated_supporter = Repo.get!(Supporter, supporter.id)
            updated_action = Repo.get!(Action, action.id)

            # Expected outcomes
            expected_supporter =
              case unquote(supporter_status) do
                :new -> :new
                :confirming -> :rejected
                :accepted -> :rejected
                :rejected -> :rejected
                :delivered -> :rejected
              end

            expected_email_status =
              case {unquote(supporter_status), unquote(email_status)} do
                {:accepted, :double_opt_in} -> :unsub
                {:delivered, :double_opt_in} -> :unsub
                _ -> unquote(email_status)
              end

            expected_action =
              case unquote(action_status) do
                :new -> :new
                :confirming -> :rejected
                :accepted -> :rejected
                :rejected -> :rejected
                :delivered -> :rejected
              end

            assert response(conn, 200) =~ "SUCCESS"
            assert updated_supporter.processing_status == expected_supporter
            assert updated_supporter.email_status == expected_email_status
            assert updated_action.processing_status == expected_action
          end
        end
      end
    end
  end
end
