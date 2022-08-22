defmodule Proca.Stage.DetailBackendTest do
  use Proca.DataCase
  @moduletag start: [:processing]

  import Proca.StoryFactory, only: [blue_story: 0]
  import Ecto.Changeset
  import Ecto.Query
  alias Proca.Factory

  alias Proca.{Repo, Action, Supporter}
  alias Proca.TestDetailBackend
  alias Proca.Stage.Processing
  alias Proca.Service.Detail
  import Logger

  setup do
    s = blue_story()

    org =
      Repo.update!(
        change(
          Repo.preload(s.org, [:detail_backend]),
          detail_backend: Factory.insert(:detail_backend, org_id: s.org.id)
        )
      )

    [ap] = s.pages

    {:ok, dp} = Task.Supervisor.start_link(name: Proca.Service.DetailProcessing)

    %{s | org: org, pages: [%{ap | org: org}]}
    |> Map.put(:detail_processing, dp)
  end

  test "test detail service" do
    TestDetailBackend.start_link(%Detail{privacy: %{optIn: false}})

    {:ok, d} = TestDetailBackend.lookup(%Supporter{})
    assert d.privacy.optIn == false
  end

  test "process action with detail", %{pages: [ap]} do
    assert not is_nil(Process.whereis(Proca.Stage.Processing))
    TestDetailBackend.start_link(%Detail{privacy: %{opt_in: true}})

    a = Factory.insert(:action, action_page: ap, opt_in: false)

    info("action has an id: #{a.id}")

    assert %{communication_consent: false} = hd(a.supporter.contacts)

    Processing.process(a)
    |> IO.inspect(label: "processing:")

    TestDetailBackend.sync()

    :timer.sleep(1000)

    a = Repo.reload(a) |> Repo.preload(supporter: :contacts)

    info("action still has an id: #{a.id}")
    assert %{communiction_consent: true} = hd(a.supporter.contacts)

    info("After processing: #{inspect(a)}")
  end
end
