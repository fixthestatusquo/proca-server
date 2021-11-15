defmodule ReleaseTest do
  use Proca.DataCase

  test "Test if config/release.exs has proper syntax" do
    try do
      Code.compile_file "config/releases.exs"
    rescue 
      e in SyntaxError -> reraise e, __STACKTRACE__
      e in RuntimeError -> :ok
    end
  end
end
