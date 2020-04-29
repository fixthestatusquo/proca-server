defmodule ProcaWeb.DashView do
  use ProcaWeb, :view

  def has_public_key?(org) do
    Enum.count(org.public_keys) > 0
  end

  def editing?(changeset) when is_nil(changeset) do
    false
  end

  def editing?(_) do
    true
  end

  def new_record?(%{data: %{id: id}}) when not is_nil(id) do
    false
  end

  def new_record?(%{data: %{}}) do
    true
  end

  def can?(staffer, permission) do
    Proca.Staffer.Permission.can? staffer, permission
  end
end
