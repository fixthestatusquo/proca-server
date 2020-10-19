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

  def supported_languages() do
    [
      {"Arabic", "ar"},
      {"Bulgarian", "br"},
      {"Croatian", "hr"},
      {"Czech", "cs"},
      {"Danish", "da"},
      {"Dutch", "nl"},
      {"English", "en"},
      {"English (GB)", "en_GB"},
      {"Estonian", "et"},
      {"Finnish", "fi"},
      {"French", "fr"},
      {"German", "de"},
      {"Greek", "el"},
      {"Hebrew", "he"},
      {"Hindi", "hi"},
      {"Italian", "it"},
      {"Polish", "pl"},
      {"Romanian", "ro"},
      {"Spanish", "es"},
      {"Swedish", "se"},
      {"Serbian", "sr"}
    ]
  end

  def owned_by(items, staffer) do
    items
    |> Enum.filter(fn i -> i.org_id == staffer.org_id end)
  end
end
