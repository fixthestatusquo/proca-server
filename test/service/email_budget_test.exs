defmodule Proca.Service.EmailBudgetTest do
  use ExUnit.Case, async: true

  alias Proca.Service.EmailBudget

  test "count/1 is 0 for an org with no recorded sends" do
    assert EmailBudget.count(System.unique_integer([:positive])) == 0
  end

  test "add/2 accumulates and returns the running total" do
    org_id = System.unique_integer([:positive])

    assert EmailBudget.add(org_id, 3) == 3
    assert EmailBudget.add(org_id, 2) == 5
    assert EmailBudget.count(org_id) == 5
  end

  test "add/1 defaults to incrementing by 1" do
    org_id = System.unique_integer([:positive])

    assert EmailBudget.add(org_id) == 1
    assert EmailBudget.add(org_id) == 2
  end

  test "reset/1 zeroes the counter again" do
    org_id = System.unique_integer([:positive])

    EmailBudget.add(org_id, 10)
    assert EmailBudget.count(org_id) == 10

    EmailBudget.reset(org_id)
    assert EmailBudget.count(org_id) == 0
  end

  test "counts for different orgs don't interfere, even under concurrent adds" do
    org_a = System.unique_integer([:positive])
    org_b = System.unique_integer([:positive])

    1..50
    |> Enum.map(fn _ -> Task.async(fn -> EmailBudget.add(org_a, 1) end) end)
    |> Enum.each(&Task.await/1)

    1..20
    |> Enum.map(fn _ -> Task.async(fn -> EmailBudget.add(org_b, 1) end) end)
    |> Enum.each(&Task.await/1)

    assert EmailBudget.count(org_a) == 50
    assert EmailBudget.count(org_b) == 20
  end
end
