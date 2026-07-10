defmodule Proca.Server.MTTModeTest do
  use ExUnit.Case, async: false

  alias Proca.Server.MTT

  setup do
    previous = Application.get_env(:proca, MTT)

    on_exit(fn ->
      if previous do
        Application.put_env(:proca, MTT, previous)
      else
        Application.delete_env(:proca, MTT)
      end
    end)

    :ok
  end

  test "defaults to enabled" do
    Application.delete_env(:proca, MTT)

    assert MTT.mode() == :enabled
    assert MTT.enabled?()
    refute MTT.dry_run?()
  end

  test "supports disabled and dry-run modes" do
    Application.put_env(:proca, MTT, mode: :disabled)
    refute MTT.enabled?()
    refute MTT.dry_run?()

    Application.put_env(:proca, MTT, mode: :dry_run)
    assert MTT.enabled?()
    assert MTT.dry_run?()
  end
end
