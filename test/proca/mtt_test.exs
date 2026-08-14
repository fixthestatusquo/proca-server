defmodule Proca.MTTTest do
  use Proca.DataCase

  alias Proca.MTT

  test "accepts an IANA timezone from tzdata" do
    changeset =
      MTT.changeset(%MTT{}, %{
        start_at: ~U[2026-04-12 16:14:14Z],
        end_at: ~U[2026-05-12 16:14:14Z],
        timezone: "Europe/Berlin"
      })

    assert changeset.valid?
  end

  test "rejects an invalid timezone" do
    changeset =
      MTT.changeset(%MTT{}, %{
        start_at: ~U[2026-04-12 16:14:14Z],
        end_at: ~U[2026-05-12 16:14:14Z],
        timezone: "Not/AZone"
      })

    refute changeset.valid?
    assert %{timezone: [_ | _]} = errors_on(changeset)
  end
end
