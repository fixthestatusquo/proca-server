defmodule Proca.Contact do
  use Ecto.Schema
  import Ecto.Changeset

  schema "contacts" do
    field :address, :string
    field :email, :string
    field :encrypted, :binary
    field :encrypted_nonce, :binary
    field :first_name, :string
    field :name, :string
    field :phone, :string
    belongs_to :public_key, Proca.PublicKey
    has_one :consent, Proca.Consent

    many_to_many(
      :signatures,
      Proca.Signature,
      join_through: "contact_signatures",
      on_replace: :delete
    )

    timestamps()
  end



  @email_format ~r{^[a-zA-Z0-9_.+-]+@[a-zA-Z0-9-]+\.[a-zA-Z0-9-.]+$}

  @doc false
  def changeset(contact, attrs) do
    contact
    |> cast(attrs, [:name, :first_name, :email, :phone, :address, :encrypted])
    |> validate_required([:name, :first_name, :email, :phone, :address, :encrypted])
  end


  def normalize_names_attr(attr = %{first_name: _, name: _}) do
    attr
  end

  def normalize_names_attr(attr = %{first_name: fst, last_name: lst}) do
    attr
    |> Map.put(:name, String.trim "#{fst} #{lst}")
  end

  def normalize_names_attr(attr = %{name: n}) do
    attr
    |> Map.put(:first_name, hd(String.split(n, " ")))
    |> Map.put(:last_name, tl(String.split(n, " ")) |> Enum.join(" "))
  end

  def normalize_names_attr(attr) do
    attr
  end


  def from_input(contact_input, _action_page) do
    %Proca.Contact{}
    |> cast(contact_input, [:name, :first_name, :email, :phone])
    |> validate_required([:name, :first_name])
    |> validate_format(:email, @email_format)
    |> validate_format(:phone, ~r{[0-9+ -]+})
  end

  def encrypted_contact_payload(contact, extra) do
    p = Map.take(contact, [:name, :first_name, :last_name, :phone, :email])
    p2 = case extra[:address] do
           a when is_map(a) -> Map.merge(p, a)
            nil -> p
         end
    JSON.encode p2
  end

  defp public_key(action_page) do
    case Proca.Org.get_public_keys(action_page.org) do
      [] -> :no_keys
      [pk | _] -> pk
    end
  end

  def put_encryption(contact_ch, action_page, extra) do
    case public_key(action_page) do
      :no_keys -> contact_ch
      pk -> 
        with {:ok, payload} <- encrypted_contact_payload(contact_ch.changes, extra),
             {penc, nonce} when is_binary(penc) <- Proca.Server.Encrypt.encrypt(pk, payload)
          do
          contact_ch
          |> put_change(:encrypted, penc)
          |> put_change(:encrypted_nonce, nonce)
          |> put_assoc(:public_key, pk)
          else
          {:error, msg} -> add_error(contact_ch, :encrypted, msg)
        end
    end
  end

  @doc "Create contact with formats and criteria required by action_page"
  def from_contact_input(contact_input, action_page) do
    attrs = contact_input |> normalize_names_attr

    # XXX Use action page to filter this changeset according to its settings
    with %Ecto.Changeset{valid?: true} = contact_ch <- from_input(attrs, action_page),
         %Ecto.Changeset{valid?: true, changes: address} <- Proca.Address.from_input(Map.get(attrs, :address), action_page),
           %Ecto.Changeset{valid?: true} =  encrypted_contact <- put_encryption(contact_ch, action_page, address: address)
      do
      encrypted_contact
    end
  end
end
