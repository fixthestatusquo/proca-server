defmodule Proca.Org do
  @moduledoc """
  Represents an organisation in Proca. `Org` can have many `Proca.Staffer`s, `Proca.Service`s, `Proca.Campaign`s and `Proca.ActionPage`'s.

  Org can have one or more `PublicKey`'s. Only one of them is active at a particular time. Others are expired.

  Org fields define how services are used (as which backends):

  - `event_backend` - where to send events (See `Proca.Stage.Event`)
  - `email_backend` - where to send emails
  - `detail_backend` - where to fetch supporter detail from
  - `storage_backend` - where to store files (attached to actions)
  - `push_backend` - where to push action data

  """
  use Ecto.Schema
  use Proca.Schema, module: __MODULE__
  import Ecto.Changeset
  import Ecto.Query, except: [update: 2]
  alias Proca.{Org, Service}

  schema "orgs" do
    field :name, :string
    field :title, :string
    has_many :public_keys, Proca.PublicKey, on_delete: :delete_all
    has_many :staffers, Proca.Staffer, on_delete: :delete_all
    has_many :campaigns, Proca.Campaign, on_delete: :nilify_all
    # XXX
    has_many :action_pages, Proca.ActionPage, on_delete: :nilify_all

    field :contact_schema, ContactSchema, default: :basic
    field :action_schema_version, :integer, default: 2

    # avoid storing transient data in clear
    # XXX rename to a more adequate :strict_privacy
    # XXX also maybe move to campaign level
    field :high_security, :boolean, default: false

    field :doi_thank_you, :boolean, default: false

    # services and delivery options
    has_many :services, Proca.Service, on_delete: :delete_all
    belongs_to :email_backend, Proca.Service
    belongs_to :storage_backend, Proca.Service
    field :email_from, :string
    field :reply_enabled, :boolean, default: true

    # supporter confirm in configuration
    field :supporter_confirm, :boolean, default: false
    field :supporter_confirm_template, :string

    # confirming and delivery configuration for custom queues (cus.*)
    field :custom_supporter_confirm, :boolean, default: false
    field :custom_action_confirm, :boolean, default: false
    field :custom_action_deliver, :boolean, default: false
    field :custom_event_deliver, :boolean, default: false

    belongs_to :event_backend, Proca.Service
    belongs_to :detail_backend, Proca.Service
    belongs_to :push_backend, Proca.Service

    field :config, :map, default: %{}

    timestamps()
  end

  @doc """
  The code you provided defines a function called `changeset` in the Elixir programming language.

  This function takes two arguments, `org` and `attrs`. It performs a series of operations to build a changeset for the `org` struct, which can be used for inserting or updating data in a database.

  Here's a breakdown of what the code does:

  1. The code uses the Elixir pipe operator (`|>`) to pass the `org` struct through a series of transformations.

  2. The `cast` function is used to update fields of the `org` struct based on the provided attributes. It takes the `org` struct, a list of field names to update, and the attrs map. Any fields that are not included in the list are ignored.

  3. The `cast_backend` function is used multiple times to update backend settings based on the provided attributes. It takes a field name, a list of allowed values for that field, the `attrs` map, and the `org` struct. It updates the backend field if the corresponding field in `attrs` matches one of the allowed values.

  4. The `validate_required` function is called with a list of required field names (`:name` and `:title`) to ensure they are present in the `org` struct.

  5. The `validate_format` function is used to validate that the `:name` field matches the regular expression pattern `~r/^[[:alnum:]_-]+$/`, which allows only alphanumeric characters, underscores, and hyphens.

  6. The `unique_constraint` function is used to add a unique constraint validation on the `:name` field.

  7. The `Proca.Contact.Input.validate_email` function is used to validate the format of the `:email_from` field.

  8. The `Proca.Service.EmailTemplate.validate_exists` function is used to validate that the `:supporter_confirm_template` field references an existing email template.

  Finally, the resulting changeset is returned by the function. This changeset represents the updates that can be applied to the `org` struct in the database.
  """
  def changeset(org, attrs) do
    org
    |> cast(attrs, [
      :name,
      :title,
      :contact_schema,
      :email_from,
      :supporter_confirm,
      :supporter_confirm_template,
      :config,
      :high_security,
      :doi_thank_you,
      :reply_enabled,
      :custom_supporter_confirm,
      :custom_action_confirm,
      :custom_action_deliver,
      :custom_event_deliver,
      :action_schema_version
    ])
    |> cast_backend(:email_backend, [:mailjet, :ses, :smtp, :system, :testmail], attrs, org)
    |> cast_backend(:event_backend, [:sqs, :webhook], attrs, org)
    |> cast_backend(:push_backend, [:sqs, :webhook], attrs, org)
    |> cast_backend(:storage_backend, [:supabase], attrs, org)
    |> cast_backend(:detail_backend, [:webhook], attrs, org)
    |> validate_required([:name, :title])
    |> validate_format(:name, ~r/^[[:alnum:]_-]+$/)
    |> unique_constraint(:name)
    |> Proca.Contact.Input.validate_email(:email_from)
    |> Proca.Service.EmailTemplate.validate_exists(:supporter_confirm_template)
  end

  @doc """
  The code you provided defines a function called `cast_backend` in the Elixir programming language. This function takes five arguments: `chset`, `backend_type`, `allow_list`, `params`, and `org`.

  Here's a breakdown of what the code does:

  1. The function checks if the `params` map has a key that matches the `backend_type`.

  - If the `backend_type` key is present in the `params` map, the code proceeds to execute the `case` expression.
  - If the `backend_type` key is not present, the function simply returns the unchanged `chset` argument.

  2. Inside the `case` expression, the function calls the `cast_backend_service` function with the `backend_type` key and the corresponding value from the `params` map. The `cast_backend_service` function is likely a custom function defined elsewhere and its purpose is not shown in the provided code snippet. It presumably performs some processing specific to the backend service.

  3. Based on the result of the `cast_backend_service` function, the code executes one of three possible branches:

  - If the result is `nil`, meaning no such service was found, an error is added to the changeset (`chset`) using the `add_error` function.
  - If the result is a map with keys `:id` and `:name`, the code checks if the `name` is a member of the `allow_list`. If it is, the changeset is updated by putting a change to the `chset` with the backend ID based on the `backend_type`. Otherwise, an error is added to the changeset.
  - If the result is `:disable`, the changeset is updated by putting a change to the `chset` with the backend ID based on the `backend_type` set to `nil`.

  4. After executing one of the branches, the resulting changeset is returned.
  """
  def cast_backend(chset, backend_type, allow_list, params, org) do
    if Map.has_key?(params, backend_type) do
      case cast_backend_service(backend_type, params[backend_type], org) do
        nil ->
          add_error(chset, backend_type, "no such service")

        %{id: id, name: name} ->
          if Enum.member?(allow_list, name) do
            put_change(chset, String.to_existing_atom("#{backend_type}_id"), id)
          else
            add_error(chset, backend_type, "service does not support such backend")
          end

        :disable ->
          put_change(chset, String.to_existing_atom("#{backend_type}_id"), nil)
      end
    else
      chset
    end
  end

  defp cast_backend_service(_type, nil, _org) do
    :disable
  end

  defp cast_backend_service(:email_backend, :system, _org) do
    Proca.Org.one([:instance] ++ [preload: [:email_backend]]).email_backend
  end

  defp cast_backend_service(_type, service, org) when is_atom(service) do
    Proca.Service.one([name: service, org: org] ++ [:latest])
  end

  defp cast_backend_service(_type, %Service{} = service, _org) do
    service
  end

  def all(q, [{:name, name} | kw]), do: where(q, [o], o.name == ^name) |> all(kw)
  def all(q, [:instance | kw]), do: all(q, [{:name, instance_org_name()} | kw])

  def all(q, [:active_public_keys | kw]) do
    q
    |> join(:left, [o], k in assoc(o, :public_keys), on: k.active)
    |> order_by([o, k], asc: k.inserted_at)
    |> preload([o, k], public_keys: k)
    |> all(kw)
  end

  @doc """
  The code you provided defines a function called `delete` in the Elixir programming language. This function takes one argument, `org`, which represents an organization.

  Here's a breakdown of what the code does:

  1. The code uses the Elixir pipe operator (`|>`) to pass the `org` argument through a series of transformations.

  2. The `change` function is called with the `org` argument. This function is likely a custom function defined elsewhere and its purpose is not shown in the provided code snippet. It could perform any necessary changes or transformations on the `org` struct.

  3. After the `change` function is applied to the `org`, the resulting value is piped into the `foreign_key_constraint` function.

  4. The `foreign_key_constraint` function adds a foreign key constraint to the `org` struct. It is used to define a relationship between the `org` and the `:action_pages` table, where the `org` has a foreign key reference in the `:action_pages` table. This constraint ensures referential integrity, meaning that the `org` cannot be deleted if there are any associated records in the `:action_pages` table.

  - The `:action_pages` is the table name where the foreign key constraint is applied.
  - The `name` option is used to specify the name of the foreign key constraint. In this case, it is set to `:action_pages_org_id_fkey`.
  - The `message` option is used to provide a custom error message that will be shown if the foreign key constraint is violated. In this case, it is set to "has action pages".

  The purpose of this code snippet is to build a changeset that verifies whether an organization (`org`) can be deleted based on the presence of associated records in the `:action_pages` table. If there are action pages associated with the organization, a foreign key constraint is added to prevent deletion and an error message is provided.
  """
  def delete(org) do
    change(org)
    |> foreign_key_constraint(:action_pages,
      name: :action_pages_org_id_fkey,
      message: "has action pages"
    )
  end

  @doc """
  The code you provided defines a function called `get_by_name` in the Elixir programming language. This function takes two arguments: `name` and `preload`, with `preload` being an optional argument that defaults to an empty list.

  Here's a breakdown of what the code does:

  1. The function calls the `one` function with the `name` argument and an options map that includes the `preload` argument.

  2. The `one` function is likely a part of a database querying library or framework, and its purpose is not shown in the provided code snippet. It is used here to retrieve a single record from the database based on the `name` value. The `name` could represent a unique identifier or a specific condition to filter the records.

  3. The `preload` option allows for eager-loading associations or related data in the returned record. The `preload` value, which is optional and defaults to an empty list, can be provided to specify which associations should be preloaded. Preloading associations is useful to avoid making additional database queries when accessing related data.

  4. The result of the `one` function, which represents a single record from the database based on the specified `name`, is returned by the `get_by_name` function.

  In summary, the purpose of this code snippet is to provide a convenient wrapper function `get_by_name` that retrieves a single record from the database based on the provided `name` value. The optional `preload` argument allows for eager-loading specific associations.
  """
  def get_by_name(name, preload \\ []) do
    one(name: name, preload: preload)
  end

  def get_by_id(id, preload \\ []) do
    one(id: id, preload: preload)
  end

  def instance_org_name do
    Application.get_env(:proca, Proca)[:org_name]
  end

  def list(preloads \\ []) do
    all(preload: preloads)
  end

  @spec active_public_keys([Proca.PublicKey]) :: [Proca.PublicKey]
  def active_public_keys(public_keys) do
    public_keys
    |> Enum.filter(& &1.active)
    |> Enum.sort(fn a, b -> a.inserted_at < b.inserted_at end)
  end

  @spec active_public_keys(Proca.Org) :: Proca.PublicKey | nil
  def active_public_key(org) do
    Proca.Repo.one(from(pk in Ecto.assoc(org, :public_keys), order_by: [asc: pk.id], limit: 1))
  end

  def put_service(%Org{} = org, service), do: put_service(change(org), service)

  def put_service(%Ecto.Changeset{} = ch, %Proca.Service{name: name} = service)
      when name in [:mailjet, :ses, :testmail] do
    ch
    |> put_assoc(:email_backend, service)
  end
end
