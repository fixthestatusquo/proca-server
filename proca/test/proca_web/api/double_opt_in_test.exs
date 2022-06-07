defmodule ProcaWeb.Api.DoubleOptInTest do
  use ProcaWeb.ConnCase
  import Proca.StoryFactory, only: [blue_story: 0]
  import Ecto.Query
  import Ecto.Changeset
  alias Proca.Factory
  alias Absinthe.Resolution

  use Proca.TestEmailBackend

  alias Proca.{Repo, Action, Supporter}

  @basic_data %{}

  setup do
    assert Proca.Pipes.Connection.is_connected?()

    %{
      proc: Proca.Server.Processing.start_link([])
    }
  end

  describe "Double opt in" do
    setup ctx do
      story =
        blue_story()
        |> Map.merge(ctx)
    end

    test "for action with opt_in", %{conn: conn, pages: [ap]} do
      {ref, email} = add_action_contact(ap, true)

      s = check_supporter(ref, status: :accepted, email_status: :none, consent: {true, true})
      a = check_action(s, status: :delivered)

      click_doi_link(conn, %{a | supporter: s}, "y")

      s =
        check_supporter(ref,
          status: :accepted,
          email_status: :double_opt_in,
          consent: {true, true}
        )

      a = check_action(s, status: :delivered)
    end
  end

  describe "Supporter confirm action:" do
    setup ctx do
      story = blue_story()

      %{
        story
        | org:
            Repo.update!(
              change(story.org,
                supporter_confirm: true,
                supporter_confirm_template: "confirm_your_signature"
              )
            )
      }
      |> Map.merge(ctx)
    end

    test "Confirm but not double opt in", %{conn: conn, pages: [ap]} do
      {ref, email} = add_action_contact(ap, false)

      s = check_supporter(ref, status: :confirming, email_status: :none, consent: {true, false})
      a = check_action(s, status: :new)

      click_supporter_link(conn, %{a | supporter: s}, :confirm)

      s = check_supporter(ref, status: :accepted, email_status: :none, consent: {true, false})
      a = check_action(s, status: :delivered)
    end

    test "Confirm but do double opt in", %{conn: conn, pages: [ap]} do
      {ref, email} = add_action_contact(ap, false)

      s = check_supporter(ref, status: :confirming, email_status: :none, consent: {true, false})
      a = check_action(s, status: :new)

      click_supporter_link(conn, %{a | supporter: s}, :confirm, "doi=1")

      s =
        check_supporter(ref,
          status: :accepted,
          email_status: :double_opt_in,
          consent: {true, false}
        )

      a = check_action(s, status: :delivered)
    end

    test "Confirm but do form opt in and double opt in", %{conn: conn, pages: [ap]} do
      {ref, email} = add_action_contact(ap, true)

      s = check_supporter(ref, status: :confirming, email_status: :none, consent: {true, true})
      a = check_action(s, status: :new)

      click_supporter_link(conn, %{a | supporter: s}, :confirm, "doi=1")

      s =
        check_supporter(ref,
          status: :accepted,
          email_status: :double_opt_in,
          consent: {true, true}
        )

      a = check_action(s, status: :delivered)
    end

    test "Reject and not double opt in", %{conn: conn, pages: [ap]} do
      {ref, email} = add_action_contact(ap, false)

      s = check_supporter(ref, status: :confirming, email_status: :none, consent: {true, false})
      a = check_action(s, status: :new)

      click_supporter_link(conn, %{a | supporter: s}, :reject)

      s = check_supporter(ref, status: :rejected, email_status: :none, consent: {true, false})
      a = check_action(s, status: :new)

      # after process old kicks in...
      Proca.Server.Processing.process(a)
      s = check_supporter(ref, status: :rejected, email_status: :none, consent: {true, false})
      a = check_action(s, status: :rejected)
    end
  end

  # ----------- HELPERS -------------------
  #
  def check_supporter(ref, status: status, email_status: es, consent: {dc, cc}) do
    added =
      Supporter.one(
        contact_ref: ref,
        limit: 1,
        order_by: [desc: :id],
        preload: [:actions, :contacts]
      )

    assert added.processing_status == status
    assert [%{delivery_consent: dc, communication_consent: cc}] = added.contacts
    assert added.email_status == es

    added
  end

  def check_action(supporter, status: status) do
    [act] = supporter.actions
    assert act.processing_status == status

    %{act | supporter: supporter}
  end

  def click_doi_link(conn, action, doi) do
    refbase = Supporter.base_encode(action.supporter.fingerprint)
    link = "/link/d/#{action.id}/#{refbase}"
    link = link <> "?redir=https://landingpage.com"
    res = get(conn, link, %{})
    Proca.Server.Processing.sync()
  end

  def click_supporter_link(conn, action, verb, qa \\ nil) do
    link = Proca.Stage.Support.supporter_link(action, verb)
    # strip http://localhost
    link =
      "/" <>
        (link |> String.split("/") |> Enum.slice(3..-1) |> Enum.join("/")) <>
        "?redir=https://landingpage.com"

    link = link <> if qa == nil, do: "", else: "&" <> qa
    res = get(conn, link, %{})
    Proca.Server.Processing.sync()
  end

  def add_action_contact(ap, opt_in) do
    contact =
      Map.from_struct(Factory.build(:basic_data_pl))
      |> Map.delete(:name)

    {:ok, %{contact_ref: ref}} =
      ProcaWeb.Resolvers.Action.add_action_contact(
        :none,
        %{
          action_page_id: ap.id,
          action: %{
            action_type: "register"
          },
          contact: contact,
          privacy: %{opt_in: opt_in}
        },
        %Resolution{context: %{}, extensions: %{}}
      )

    Proca.Server.Processing.sync()

    {:ok, ref2} = Supporter.base_decode(ref)
    {ref2, contact.email}
  end
end
