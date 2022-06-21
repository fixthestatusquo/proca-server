defmodule Proca.SupabaseTest do
  use Proca.DataCase

  setup do
    %{
      key: "XXXX",
      url: "https://YYY.supabase.co"
    }
  end

  test "fetch using library", c do
    assert {:ok, b} =
             Supabase.Connection.new(c[:url], c[:key])
             |> Supabase.Storage.from("bucket")
             |> Supabase.Storage.download("pep")
  end

  test "fetch using Service", c do
    s = %Proca.Service{name: :supabase, password: c[:key], host: c[:url]}

    Proca.Service.Supabase.fetch(
      s,
      "file"
    )
    |> IO.inspect()
  end
end
