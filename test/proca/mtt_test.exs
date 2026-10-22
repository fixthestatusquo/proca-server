defmodule Proca.MTTTest do
  use Proca.DataCase

  alias Proca.MTT

  @dates %{start_at: ~U[2026-04-12 16:00:00Z], end_at: ~U[2026-05-12 16:00:00Z]}

  defp new(attrs), do: MTT.changeset(%MTT{}, Map.merge(@dates, attrs))

  describe "delivery" do
    test "new mtt defaults to throttle" do
      assert get_field(new(%{}), :delivery) == :throttle
    end

    test "can be set to pacing" do
      assert get_field(new(%{delivery: :pacing}), :delivery) == :pacing
    end

    test "changing it on an existing mtt is saved" do
      mtt = Factory.insert(:campaign, mtt: Factory.build(:mtt)).mtt
      assert mtt.delivery == :pacing

      mtt = MTT.changeset(mtt, %{delivery: :throttle}) |> Repo.update!()
      assert mtt.delivery == :throttle
    end

    test "null is rejected" do
      refute new(%{delivery: nil}).valid?
    end
  end
end
