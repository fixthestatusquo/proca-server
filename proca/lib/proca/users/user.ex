defmodule Proca.Users.User do
  use Ecto.Schema
  import Ecto.Changeset
  use Proca.Schema, module: __MODULE__
  import Ecto.Query, only: [from: 1, from: 2, preload: 3, where: 3, join: 4]

  @derive {Inspect, except: [:password]}
  schema "users" do
    field :email, :string
    field :password, :string, virtual: true
    field :hashed_password, :string
    field :confirmed_at, :naive_datetime


    field :perms, :integer, default: 0
    has_many :staffers, Proca.Staffer

    timestamps()
  end

  @doc """
  A user changeset for registration.

  It is important to validate the length of both email and password.
  Otherwise databases may truncate the email without warnings, which
  could lead to unpredictable or insecure behaviour. Long passwords may
  also be very expensive to hash for certain algorithms.

  ## Options

    * `:hash_password` - Hashes the password so it can be stored securely
      in the database and ensures the password field is cleared to prevent
      leaks in the logs. If password hashing is not needed and clearing the
      password field is not desired (like when using this changeset for
      validations on a LiveView form), this option can be set to `false`.
      Defaults to `true`.
  """
  def registration_changeset(user, attrs, opts \\ []) do
    user
    |> cast(attrs, [:email, :password])
    |> validate_email()
    |> validate_password(opts)
  end

  defp validate_email(changeset) do
    changeset
    |> validate_required([:email])
    |> validate_format(:email, ~r/^[^\s]+@[^\s]+$/, message: "must have the @ sign and no spaces")
    |> validate_length(:email, max: 160)
    |> unsafe_validate_unique(:email, Proca.Repo)
    |> unique_constraint(:email)
  end

  defp validate_password(changeset, opts) do
    changeset
    |> validate_required([:password])
    |> validate_length(:password, min: 12, max: 80)
    |> validate_format(:password, ~r/[a-z]/, message: "at least one lower case character")
    |> validate_format(:password, ~r/[A-Z]/, message: "at least one upper case character")
    |> validate_format(:password, ~r/[!?@#$%^&*_0-9]/, message: "at least one digit or punctuation character")
    |> maybe_hash_password(opts)
  end

  defp maybe_hash_password(changeset, opts) do
    hash_password? = Keyword.get(opts, :hash_password, true)
    password = get_change(changeset, :password)

    if hash_password? && password && changeset.valid? do
      changeset
      |> put_change(:hashed_password, Bcrypt.hash_pwd_salt(password))
      |> delete_change(:password)
    else
      changeset
    end
  end

  @doc """
  A user changeset for changing the email.

  It requires the email to change otherwise an error is added.
  """
  def email_changeset(user, attrs) do
    user
    |> cast(attrs, [:email])
    |> validate_email()
    |> case do
      %{changes: %{email: _}} = changeset -> changeset
      %{} = changeset -> add_error(changeset, :email, "did not change")
    end
  end

  @doc """
  A user changeset for changing the password.

  ## Options

    * `:hash_password` - Hashes the password so it can be stored securely
      in the database and ensures the password field is cleared to prevent
      leaks in the logs. If password hashing is not needed and clearing the
      password field is not desired (like when using this changeset for
      validations on a LiveView form), this option can be set to `false`.
      Defaults to `true`.
  """
  def password_changeset(user, attrs, opts \\ []) do
    user
    |> cast(attrs, [:password])
    |> validate_confirmation(:password, message: "does not match password")
    |> validate_password(opts)
  end

  @doc """
  Confirms the account by setting `confirmed_at`.
  """
  def confirm_changeset(user) do
    now = NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)
    change(user, confirmed_at: now)
  end

  @doc """
  Verifies the password.

  If there is no user or the user doesn't have a password, we call
  `Bcrypt.no_user_verify/0` to avoid timing attacks.
  """
  def valid_password?(%Proca.Users.User{hashed_password: hashed_password}, password)
      when is_binary(hashed_password) and byte_size(password) > 0 do
    verify_pass(password, hashed_password)
  end

  def valid_password?(_, _) do
    Bcrypt.no_user_verify()
    false
  end

  # backward compatible password verify with Pow
  def verify_pass(password, hashed_password = ("$pbkdf2" <> _ )) do 
    ["pbkdf2-" <> digest, rounds, salt, hash] = String.split(hashed_password, "$", trim: true)
    {:ok, salt} = Base.decode64 salt
    {:ok, hash} = Base.decode64 hash
    
    hashed_password = "$pbkdf2-" <> digest <> "$" <> rounds <> "$" <> Base.encode64(salt, padding: false) <> "$" <> Base.encode64(hash, padding: false)

    rounds = String.to_integer rounds

    IO.inspect(hashed_password)
    IO.inspect(Pbkdf2.Base.hash_password(password, salt, rounds: rounds, length: 64, digest: digest))
    hashed_password == Pbkdf2.Base.hash_password(password, salt, rounds: rounds, length: 64, digest: digest)
  end

  def verify_pass(password, hashed_password) do 
    Bcrypt.verify_pass(password, hashed_password)
  end

  @doc """
  Validates the current password otherwise adds an error to the changeset.
  """
  def validate_current_password(changeset, password) do
    if valid_password?(changeset.data, password) do
      changeset
    else
      add_error(changeset, :current_password, "is not valid")
    end
  end


  def all(q, [{:email, email} | kw]) do 
    q |> where([u], u.email == ^email) |> all(kw)
  end
  def all(q, [{:email_like, email} | kw]) do 
    q |> where([u], like(u.email, ^email)) |> all(kw)
  end
  def all(q, [{:id, id} | kw]) do 
    q |> where([u], u.id == ^id) |> all(kw)
  end
  def all(q, [{:org_name, org_name} | kw]) do 
    q 
    |> join(:inner, [u], s in assoc(u, :staffers))
    |> join(:inner, [u, s], o in assoc(s, :org))
    |> where([u, s, o], o.name == ^org_name)
    |> all(kw)
  end
  def all(q, [:preload | kw]) do 
    q |> preload([u], [staffers: :org]) |> all(kw)
  end

  def update(user, [:admin | kw]) do 
    update(user, [{:perms, [
      :instance_owner, 
      :join_orgs, 
      :manage_users, 
      :manage_orgs]} | kw])
  end

  def update(user, [{:perms, permissions} | kw]) do 
    change(user, perms: Proca.Permission.add(0, permissions))
    |> update(kw)
  end

  # XXX
  # -  def reset_password(email) do
  # -  def params_for(email) do
  
  
end
