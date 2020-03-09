defmodule ProcaWeb.DashView do
  use ProcaWeb, :view

  def has_public_key?(org) do
    IO.puts "#{org.name}: #{Enum.count(org.public_keys)}"
    Enum.count(org.public_keys) > 0
  end

  def editing?(struct) when is_nil(struct) do
    IO.puts "not editing"
    false
  end

  def editing?(_) do
    IO.puts "editing"
    true
  end

  def new_record?(%{id: id}) when is_nil(id) do
    true
  end

  def new_record?(%{}) do
    false
  end
end
