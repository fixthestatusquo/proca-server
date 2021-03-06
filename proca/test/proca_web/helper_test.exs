defmodule ProcaWeb.HelperTest do
  use ProcaWeb.ConnCase
  import Ecto.Changeset
  alias ProcaWeb.Helper
  alias Proca.Action

  test "flatten_errors can handle a nested error structure" do
    errors = [value: {"can't be blank", [validation: :required]}]
    ch = change(%Action{})
    ch = %{ch | valid?: false, errors: errors}
    assert Helper.format_errors(ch) == [%{message: "can't be blank", path: ["value"]}]
  end
end
