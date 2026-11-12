defmodule ProcaWeb.Api.DoubleOptInTest do
  use ProcaWeb.ConnCase
  import Proca.StoryFactory, only: [blue_story: 0]
  import Ecto.Query
  import Ecto.Changeset
  alias Proca.Factory
  alias Absinthe.Resolution

  use Proca.TestEmailBackend
  use Proca.TestProcessing

  alias Proca.{Repo, Action, Supporter}

  @basic_data %{}

  describe "Double opt in" do
    setup ctx do
      story =
        blue_story()
        |> Map.merge(ctx)
    end

    test "for action with opt_in", %{conn: conn, pages: [ap]} do
      {ref, email} = add_action_contact(ap, true)

      %{actions: [a]} =
        check_supporter(ref, status: :new, email_status: :none, consent: {true, true})

      process(a)

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

      s = check_supporter(ref, status: :new, email_status: :none, consent: {true, false})
      a = check_action(s, status: :new)

      process(a)

      s = check_supporter(ref, status: :confirming, email_status: :none, consent: {true, false})
      a = check_action(s, status: :new)

      click_supporter_link(conn, %{a | supporter: s}, :confirm)

      s = check_supporter(ref, status: :accepted, email_status: :none, consent: {true, false})
      a = check_action(s, status: :new)

      process(a)

      s = check_supporter(ref, status: :accepted, email_status: :none, consent: {true, false})
      a = check_action(s, status: :delivered)
    end

    test "Confirm but do double opt in", %{conn: conn, pages: [ap]} do
      {ref, email} = add_action_contact(ap, false)

      s = check_supporter(ref, status: :new, email_status: :none, consent: {true, false})
      a = check_action(s, status: :new)

      process(a)

      s = check_supporter(ref, status: :confirming, email_status: :none, consent: {true, false})

      click_supporter_link(conn, %{a | supporter: s}, :confirm, "doi=1")

      s =
        check_supporter(ref,
          status: :accepted,
          email_status: :double_opt_in,
          consent: {true, true}
        )

      a = check_action(s, status: :new)

      process(a)

      s =
        check_supporter(ref,
          status: :accepted,
          email_status: :double_opt_in,
          consent: {true, true}
        )

      a = check_action(s, status: :delivered)
    end

    test "Confirm but do form opt in and double opt in", %{conn: conn, pages: [ap]} do
      {ref, email} = add_action_contact(ap, true)

      s = check_supporter(ref, status: :new, email_status: :none, consent: {true, true})
      a = check_action(s, status: :new)

      process(a)

      s = check_supporter(ref, status: :confirming, email_status: :none, consent: {true, true})
      a = check_action(s, status: :new)

      click_supporter_link(conn, %{a | supporter: s}, :confirm, "doi=1")

      s =
        check_supporter(ref,
          status: :accepted,
          email_status: :double_opt_in,
          consent: {true, true}
        )

      a = check_action(s, status: :new)

      process(a)

      s =
        check_supporter(ref,
          status: :accepted,
          email_status: :double_opt_in,
          consent: {true, true}
        )

      a = check_action(s, status: :delivered)
    end

    test "Confirm with form opt in but no doi param does double opt in", %{
      conn: conn,
      pages: [ap]
    } do
      {ref, email} = add_action_contact(ap, true)

      s = check_supporter(ref, status: :new, email_status: :none, consent: {true, true})
      a = check_action(s, status: :new)

      process(a)

      s = check_supporter(ref, status: :confirming, email_status: :none, consent: {true, true})

      click_supporter_link(conn, %{a | supporter: s}, :confirm)

      s =
        check_supporter(ref,
          status: :accepted,
          email_status: :double_opt_in,
          consent: {true, true}
        )

      a = check_action(s, status: :new)

      process(a)

      s =
        check_supporter(ref,
          status: :accepted,
          email_status: :double_opt_in,
          consent: {true, true}
        )

      check_action(s, status: :delivered)
    end

    test "Confirm with doi=0 and no form opt in keeps consent opt out", %{
      conn: conn,
      pages: [ap]
    } do
      {ref, email} = add_action_contact(ap, false)

      s = check_supporter(ref, status: :new, email_status: :none, consent: {true, false})
      a = check_action(s, status: :new)

      process(a)

      s = check_supporter(ref, status: :confirming, email_status: :none, consent: {true, false})

      click_supporter_link(conn, %{a | supporter: s}, :confirm, "doi=0")

      s = check_supporter(ref, status: :accepted, email_status: :none, consent: {true, false})

      a = check_action(s, status: :new)

      process(a)

      s = check_supporter(ref, status: :accepted, email_status: :none, consent: {true, false})

      check_action(s, status: :delivered)
    end

    test "Reject with form opt in does not double opt in", %{conn: conn, pages: [ap]} do
      {ref, email} = add_action_contact(ap, true)

      s = check_supporter(ref, status: :new, email_status: :none, consent: {true, true})
      a = check_action(s, status: :new)

      process(a)

      s = check_supporter(ref, status: :confirming, email_status: :none, consent: {true, true})

      click_supporter_link(conn, %{a | supporter: s}, :reject)

      s = check_supporter(ref, status: :rejected, email_status: :none, consent: {true, true})

      check_action(s, status: :rejected)
    end

    test "Confirm with doi=0 and nil consent records opt out", %{conn: conn, pages: [ap]} do
      {ref, _email} = add_action_contact(ap, false)

      a = check_supporter(ref, status: :new, email_status: :none, consent: {true, false})
      process(check_action(a, status: :new))

      set_contact(ref, communication_consent: nil)
      s = check_supporter(ref, status: :confirming, email_status: :none, consent: {true, nil})

      click_supporter_link(conn, check_action(s, status: :new), :confirm, "doi=0")

      check_supporter(ref, status: :accepted, email_status: :none, consent: {true, false})
    end

    test "Confirm with doi=0 and form opt in does double opt in", %{conn: conn, pages: [ap]} do
      {ref, _email} = add_action_contact(ap, true)

      a = check_supporter(ref, status: :new, email_status: :none, consent: {true, true})
      process(check_action(a, status: :new))

      s = check_supporter(ref, status: :confirming, email_status: :none, consent: {true, true})

      res = click_supporter_link(conn, check_action(s, status: :new), :confirm, "doi=0")

      assert redirected_to(res) =~ "proca_doi=1"

      check_supporter(ref, status: :accepted, email_status: :double_opt_in, consent: {true, true})
    end

    test "Confirm with form opt in and no doi param redirects with proca_doi=1", %{
      conn: conn,
      pages: [ap]
    } do
      {ref, _email} = add_action_contact(ap, true)

      a = check_supporter(ref, status: :new, email_status: :none, consent: {true, true})
      process(check_action(a, status: :new))

      s = check_supporter(ref, status: :confirming, email_status: :none, consent: {true, true})

      res = click_supporter_link(conn, check_action(s, status: :new), :confirm)

      assert redirected_to(res) =~ "proca_confirm=accept"
      assert redirected_to(res) =~ "proca_doi=1"
    end

    test "Confirm without form opt in and no doi param has no proca_doi", %{
      conn: conn,
      pages: [ap]
    } do
      {ref, _email} = add_action_contact(ap, false)

      a = check_supporter(ref, status: :new, email_status: :none, consent: {true, false})
      process(check_action(a, status: :new))

      s = check_supporter(ref, status: :confirming, email_status: :none, consent: {true, false})

      res = click_supporter_link(conn, check_action(s, status: :new), :confirm)

      refute redirected_to(res) =~ "proca_doi"
    end

    test "Confirm with doi=1 and consent already given does not update contact", %{
      conn: conn,
      pages: [ap]
    } do
      {ref, _email} = add_action_contact(ap, true)

      a = check_supporter(ref, status: :new, email_status: :none, consent: {true, true})
      process(check_action(a, status: :new))

      old = ~N[2020-01-01 00:00:00]
      set_contact(ref, updated_at: old)

      s = check_supporter(ref, status: :confirming, email_status: :none, consent: {true, true})

      click_supporter_link(conn, check_action(s, status: :new), :confirm, "doi=1")

      s = check_supporter(ref, status: :accepted, email_status: :double_opt_in, consent: {true, true})

      assert [%{updated_at: ^old}] = s.contacts
    end

    test "Confirm with doi=1 and no contact row does not create one", %{
      conn: conn,
      pages: [ap]
    } do
      {ref, _email} = add_action_contact(ap, false)

      a = check_supporter(ref, status: :new, email_status: :none, consent: {true, false})
      process(check_action(a, status: :new))

      s = check_supporter(ref, status: :confirming, email_status: :none, consent: {true, false})
      Repo.delete_all(from(c in Proca.Contact, where: c.supporter_id == ^s.id))

      link = supporter_link_path(check_action(s, status: :new), :confirm) <> "&doi=1"
      res = get(conn, link, %{})

      assert redirected_to(res) =~ "proca_doi=1"

      s = Repo.preload(Repo.get(Supporter, s.id), [:contacts], force: true)
      assert s.email_status == :double_opt_in
      assert s.processing_status == :accepted
      assert s.contacts == []
    end

    test "Reject and not double opt in", %{conn: conn, pages: [ap]} do
      {ref, email} = add_action_contact(ap, false)

      s = check_supporter(ref, status: :new, email_status: :none, consent: {true, false})
      a = check_action(s, status: :new)

      process(a)

      s = check_supporter(ref, status: :confirming, email_status: :none, consent: {true, false})
      a = check_action(s, status: :new)

      click_supporter_link(conn, %{a | supporter: s}, :reject)

      s = check_supporter(ref, status: :rejected, email_status: :none, consent: {true, false})
      a = check_action(s, status: :rejected)

      process(a)

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

    assert Enum.map(added.contacts, &{&1.delivery_consent, &1.communication_consent}) ==
             [{dc, cc}]

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
    link = link <> "?redir=https://landingpage.com/thanks"
    res = get(conn, link, %{})
    process(action)
  end

  def click_supporter_link(conn, action, verb, qa \\ nil) do
    link = supporter_link_path(action, verb)
    link = link <> if qa == nil, do: "", else: "&" <> qa
    res = get(conn, link, %{})
    process(action)
    res
  end

  def supporter_link_path(action, verb) do
    link = Proca.Stage.Support.supporter_link(action, verb)
    # strip http://localhost
    "/" <>
      (link |> String.split("/") |> Enum.slice(3..-1) |> Enum.join("/")) <>
      "?redir=https://landingpage.com/thanks"
  end

  def set_contact(ref, fields) do
    s = Supporter.one(contact_ref: ref, limit: 1, order_by: [desc: :id])
    Repo.update_all(from(c in Proca.Contact, where: c.supporter_id == ^s.id), set: fields)
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

    # XXX process action?

    {:ok, ref2} = Supporter.base_decode(ref)
    {ref2, contact.email}
  end
end
