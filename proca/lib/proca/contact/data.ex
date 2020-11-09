defprotocol Proca.Contact.Data do
  @moduledoc """
  Defines different styles of personal data that are stored in Contact.
  """

  @doc """
  Accepts (virtual) data changeset, and action page. Returns contact changeset and fingerprint
  """
  @spec to_contact(t, %Proca.ActionPage{}) :: Ecto.Changeset.t(%Proca.Contact{})
  def to_contact(data, action_page)

  @spec fingerprint(t) :: binary()
  def fingerprint(t)
end

defimpl Jason.Encoder,
  for: [
    Proca.Contact.BasicData,
    Proca.Contact.PopularInitiativeData,
    Proca.Contact.EciData,
    Proca.Contact.Input.Nationality,
    Proca.Contact.Input.Address
  ] do
  @doc """
  Do not serialize missing values
  """
  def encode(struct, opts) do
    struct
    |> Map.from_struct()
    |> Enum.filter(fn {_, v} -> not is_nil(v) end)
    |> Map.new()
    |> ProperCase.to_camel_case()
    |> Jason.Encode.map(opts)
  end
end
