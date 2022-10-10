defmodule Proca.DataCase do
  @moduledoc """
  This module defines the setup for tests requiring
  access to the application's data layer.

  You may define functions here to be used as helpers in
  your tests.

  Finally, if the test case interacts with the database,
  we enable the SQL sandbox, so changes done to the database
  are reverted at the end of every test. If you are using
  PostgreSQL, you can even run database tests asynchronously
  by setting `use Proca.DataCase, async: true`, although
  this option is not recommended for other databases.
  """

  use ExUnit.CaseTemplate

  using do
    quote do
      alias Proca.Repo
      alias Proca.Factory

      import Ecto
      import Ecto.Changeset
      import Ecto.Query
      import Proca.DataCase
      alias Proca.TestEmailBackend
    end
  end

  setup tags do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Proca.Repo)

    unless tags[:async] do
      Ecto.Adapters.SQL.Sandbox.mode(Proca.Repo, {:shared, self()})
    end

    if tags[:start] do
      if :stats in tags[:start] do
        case Proca.Server.Stats.start_link(1000) do
          {:ok, pid} -> Process.unlink(pid)
          _ -> :ok
        end
      end
    end

    # if tags[:start] do
    #   if :processing in tags[:start] do
    #     Proca.Stage.Action.start_link(producer: {Proca.Stage.Queue, []})
    #   end

    #   if :old_processing in tags[:start] do
    #     proca.stage.action.start_link(
    #       name: proca.stage.oldactions,
    #       producer: {proca.stage.unprocessedactions, [sweep_interal: 60, time_margine: 5]}
    #     )
    #   end
    # end

    :ok
  end

  @doc """
  A helper that transforms changeset errors into a map of messages.

      assert {:error, changeset} = Accounts.create_user(%{password: "short"})
      assert "password is too short" in errors_on(changeset).password
      assert %{password: ["password is too short"]} = errors_on(changeset)

  """
  def errors_on(changeset) do
    Ecto.Changeset.traverse_errors(changeset, fn {message, opts} ->
      Regex.replace(~r"%{(\w+)}", message, fn _, key ->
        opts |> Keyword.get(String.to_existing_atom(key), key) |> to_string()
      end)
    end)
  end
end
