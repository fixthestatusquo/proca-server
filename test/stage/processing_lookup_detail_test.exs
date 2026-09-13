defmodule Proca.Test.NotFoundPlug do
  @moduledoc false
  import Plug.Conn

  def init(opts), do: opts

  def call(conn, _opts) do
    send_resp(conn, 404, "")
  end
end

defmodule Proca.Test.OkDetailPlug do
  @moduledoc false
  import Plug.Conn

  def init(opts), do: opts

  def call(conn, _opts) do
    body =
      Jason.encode!(%{
        "privacy" => %{
          "optIn" => true,
          "givenAt" => "2024-01-01T00:00:00Z"
        }
      })

    conn
    |> put_resp_content_type("application/json")
    |> send_resp(200, body)
  end
end

defmodule Proca.Test.ServerErrorPlug do
  @moduledoc false
  import Plug.Conn

  def init(opts), do: opts

  def call(conn, _opts) do
    send_resp(conn, 500, "boom")
  end
end

defmodule Proca.Test.BadFormatPlug do
  @moduledoc false
  import Plug.Conn

  def init(opts), do: opts

  def call(conn, _opts) do
    # emailStatus is set but emailStatusChanged is missing -> fails
    # Detail.Privacy.changeset validation -> Detail.lookup/2 returns :bad_format
    body = Jason.encode!(%{"privacy" => %{"emailStatus" => "double_opt_in"}})

    conn
    |> put_resp_content_type("application/json")
    |> send_resp(200, body)
  end
end

defmodule Proca.Stage.ProcessingLookupDetailTest do
  @moduledoc """
  Regression test: when the org has a detail lookup backend configured but
  the lookup fails (backend down/unreachable, bad response, ...), the action
  must still proceed through the normal pipeline instead of getting stuck -
  eg. the supporter must still receive the normal two-button confirmation
  email. See https://github.com/fixthestatusquo/proca-server (Sentry:
  "Cannot lookup supporter detail from webhook ... econnrefused").
  """

  use Proca.DataCase

  import Proca.StoryFactory, only: [blue_story: 0]
  import Ecto.Changeset
  alias Proca.Factory
  alias Proca.Repo
  alias Proca.Stage.Processing

  defp preload_action_forced(action) do
    Repo.preload(
      action,
      [action_page: [[org: :detail_backend], :campaign], supporter: [:action_page, contacts: :org]],
      force: true
    )
  end

  defp start_plug_and_point_backend(plug, org) do
    {:ok, _} = Plug.Cowboy.http(plug, [], port: 0, ref: __MODULE__)
    port = :ranch.get_port(__MODULE__)

    org.detail_backend
    |> change(host: "http://127.0.0.1:#{port}/lookup")
    |> Repo.update!()

    :ok
  end

  setup do
    s = blue_story()

    org =
      Repo.preload(s.org, [:detail_backend])
      |> change(supporter_confirm: true)
      |> change(
        detail_backend:
          Factory.insert(:detail_backend,
            org_id: s.org.id,
            name: :webhook,
            # nothing is listening here: mirrors the prod econnrefused case
            host: "http://127.0.0.1:1/lookup"
          )
      )
      |> Repo.update!()

    [ap] = s.pages

    %{s | org: org, pages: [%{ap | org: org}]}
  end

  test "unreachable detail backend does not block the action, and the action still reaches the supporter_confirm stage",
       %{pages: [ap]} do
    action =
      Factory.insert(:action, action_page: ap, supporter_processing_status: :new)
      |> Processing.preload()

    assert {:lookup_detail, proc} = Processing.wrap(action)
    assert proc.stage == :supporter_confirm

    # the lookup fails (connection refused) - it must not fail the message,
    # it must fall back to processing without the extra detail
    assert {:ok, proc2} = Processing.lookup_detail(proc)
    assert proc2.details == nil
    assert proc2.action_change == proc.action_change
    assert proc2.supporter_change == proc.supporter_change

    # the pipeline continues normally from here, still headed to
    # supporter_confirm (ie. the two-button confirmation email)
    assert proc2.stage == :supporter_confirm
  end

  test "not-found response from the lookup backend also falls back instead of failing", %{
    org: org,
    pages: [ap]
  } do
    # a server that answers, but with 404 (Detail.lookup/2 -> {:error, :not_found})
    start_plug_and_point_backend(Proca.Test.NotFoundPlug, org)

    action =
      Factory.insert(:action, action_page: ap, supporter_processing_status: :new)
      |> preload_action_forced()

    assert {:lookup_detail, proc} = Processing.wrap(action)

    assert {:ok, proc2} = Processing.lookup_detail(proc)
    assert proc2.details == nil

    Plug.Cowboy.shutdown(__MODULE__)
  end

  test "HTTP 500 from the lookup backend also falls back instead of failing", %{
    org: org,
    pages: [ap]
  } do
    start_plug_and_point_backend(Proca.Test.ServerErrorPlug, org)

    action =
      Factory.insert(:action, action_page: ap, supporter_processing_status: :new)
      |> preload_action_forced()

    assert {:lookup_detail, proc} = Processing.wrap(action)

    assert {:ok, proc2} = Processing.lookup_detail(proc)
    assert proc2.details == nil
    assert proc2.stage == :supporter_confirm

    Plug.Cowboy.shutdown(__MODULE__)
  end

  test "malformed/invalid data from the lookup backend also falls back instead of failing", %{
    org: org,
    pages: [ap]
  } do
    start_plug_and_point_backend(Proca.Test.BadFormatPlug, org)

    action =
      Factory.insert(:action, action_page: ap, supporter_processing_status: :new)
      |> preload_action_forced()

    assert {:lookup_detail, proc} = Processing.wrap(action)

    assert {:ok, proc2} = Processing.lookup_detail(proc)
    assert proc2.details == nil
    assert proc2.stage == :supporter_confirm

    Plug.Cowboy.shutdown(__MODULE__)
  end

  test "regular (successful) lookup applies the returned detail to the supporter/action", %{
    org: org,
    pages: [ap]
  } do
    start_plug_and_point_backend(Proca.Test.OkDetailPlug, org)

    action =
      Factory.insert(:action, action_page: ap, supporter_processing_status: :new, opt_in: false)
      |> preload_action_forced()

    assert {:lookup_detail, proc} = Processing.wrap(action)

    assert {:ok, proc2} = Processing.lookup_detail(proc)
    assert %Proca.Service.Detail{privacy: %{opt_in: true}} = proc2.details

    supporter = apply_changes(proc2.supporter_change)
    assert hd(supporter.contacts).communication_consent == true

    # detail lookup does not change whether/how the action still gets
    # confirmed - it only enriches supporter/action data
    assert proc2.stage == :supporter_confirm

    Plug.Cowboy.shutdown(__MODULE__)
  end

  test "org without any detail lookup backend configured proceeds as usual (no lookup attempted)",
       %{org: org, pages: [ap]} do
    # strip the detail backend set up in this module's setup block
    Repo.update!(change(org, detail_backend_id: nil))
    ap = %{ap | org: Repo.get!(Proca.Org, org.id)}

    action =
      Factory.insert(:action, action_page: ap, supporter_processing_status: :new)
      |> Processing.preload()

    assert action.action_page.org.detail_backend_id == nil

    # no detail_backend configured -> skips the lookup step entirely and
    # goes straight to :process, same as before detail lookup existed
    assert {:process, proc} = Processing.wrap(action)
    assert proc.stage == :supporter_confirm
    assert proc.details == nil
  end
end
