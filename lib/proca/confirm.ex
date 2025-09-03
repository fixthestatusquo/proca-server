defmodule Proca.Confirm do
  @moduledoc """

  Confirm represents a confirmable
  action deferred in time. It is called confirm, because it is a confirmable -
  something that must be confirmed by a party. Usually party A creates a
  confirm, and party B accepts or rejects it. Upon acceptance, the operation can
  run. Optionaly upon rejection a different action can be triggered.

  The confirm uses subject - operation - object terminology.

  Eg. Marcin eats a-dosa would contain "eats" as operation, subject_id would be
  an FK to Marcin and object_id would be a FK to a dosa. To eat a dosa, Marcin
  creats a `Confirm{operation: :eats, subject_id: marcin.id, object_id: dosa.id}`.
  Then someone who is responsible for the dosas can accept the confirm, after
  which Marcin will instantly devour the dosa.

  The order of subject and object can also be altered.

  Eg. A dosa served to Marcin, in which case subject will be a dosa, and object
  is Marcin. In this case the dosa maker will create a `Confirm{operaition:
  :serving, subject_id: dosa.id, object_id: marcin.id}` and Marcin must accept
  this offer, after which he will instantly devour the dosa.

  There are also other possibilities. The Confirm can omit the object_id, but
  just have a special code to accept it. In our example the dosa maker will make
  a `Confirm{operation: :serving, subject_id: dosa.id, code: "98429214"}`, and
  whoever is the lucky person to use that _open code_ can become the object of
  the confirm and devour the dosa. The code can be used by both authenticated
  and non-authenticated users (works like one-time-password).

  Similarly, the confirm can be given an email, in which case the code will be
  sent to a person with particular email, as the intended devourer of the dosa.
  This way of creating a confirm is useful when we do not have the user.id for
  someone, but want them to confirm an operation (eg.: inviting new users to do
  somehing by email).

  The confirm can have many _charges_ which means they can be used more then
  once - for example when we have more then one dosa to give away.

  Confirm contains:
  - operation - name of operation, an enum defined in Proca.EctoEnum
  - subject_id - the action taker
  - object_id - some object
  - code - code to trigger the accept or reject
  - charge - how many times can be used? defaults to 1

  ### Partner joins a campaign

  ```
          subject v   object v
  join_campaign(partner_org, campaign)
  ```
  - confirm created by partner_org
  - accepted by someone from campaign lead or campaign coordinator
  - charges: 1

  ### Inviting a partner over email

  ```
  invite_partner(campaign, email)

  invite_partner(campaign, code)
  ```
  - confirm created by campaign lead or coordinator
  - confirm sent by email to particular org so they can accept the invitation instantly
  - or confirm code can be put on some forum or group, with 20 charges - the first 20 users of the code can accept the invitation.
  - after 20 uses, a new code needs to be generated.
  """

  # XXX Expire and remove old confirms!

  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query
  alias Proca.Repo
  alias Proca.{Confirm, Org}
  alias Proca.Users.User
  alias Proca.Service.{EmailBackend, EmailMerge}

  schema "confirms" do
    field :operation, ConfirmOperation
    field :subject_id, :integer
    field :object_id, :integer
    field :email, :string
    field :code, :string
    field :charges, :integer, default: 1
    field :message, :string
    belongs_to :creator, User

    timestamps()
  end

  @doc false
  def changeset(confirm, attrs) do
    confirm
    |> cast(attrs, [:operation, :subject_id, :object_id, :email, :message, :charges])
    |> put_assoc(:creator, Map.get(attrs, :creator, nil))
    |> add_code()
    |> validate_required([:operation, :subject_id, :charges, :code])
  end

  def changeset(attrs), do: changeset(%Confirm{}, attrs)

  def add_code(ch) do
    code = Confirm.SimpleCode.generate()
    change(ch, code: code) |> unique_constraint(:code)
  end

  @doc """
  Try to insert the confirm with special handling of situation, when randomly generated code is duplicated.
  In case of duplication, we will keep adding one random digit to the code, until we succeed
  """
  def insert!(ch = %Ecto.Changeset{}) do
    case Repo.insert(ch) do
      {:ok, cnf} ->
        cnf

      {:error, %{errors: [{:code, _} | _]}} ->
        code = get_change(ch, :code)
        random_digit = :rand.uniform(10)

        ch
        |> change(code: code <> Integer.to_string(random_digit))
        |> insert!()

      {:error, err} ->
        raise ArgumentError, "Cannot insert Confirm: #{inspect(err)}"
    end
  end

  def insert!(attr) when is_map(attr) do
    changeset(attr)
    |> insert!()
  end

  def insert_and_notify!(ch) do
    cnf = insert!(ch)
    Proca.Server.Notify.created(cnf)
    cnf
  end

  def by_open_code(code) when is_bitstring(code) do
    from(c in Confirm,
      where: c.code == ^code and is_nil(c.object_id) and is_nil(c.email),
      limit: 1
    )
    |> Repo.one()
  end

  def by_object_code(object_id, code) when is_integer(object_id) and is_bitstring(code) do
    from(c in Confirm, where: c.code == ^code and c.object_id == ^object_id, limit: 1)
    |> Repo.one()
  end

  def by_email_code(email, code) when is_bitstring(email) and is_bitstring(code) do
    from(c in Confirm, where: c.code == ^code and c.email == ^email, limit: 1)
    |> Repo.one()
  end

  def reject(confirm = %Confirm{}, auth \\ nil) do
    confirm
    |> change(charges: 0)
    |> Repo.update!()
    |> Confirm.Operation.run(:reject, auth)
  end

  def confirm(confirm = %Confirm{}, auth \\ nil) do
    if confirm.charges <= 0 do
      {:error, "expired"}
    else
      case Confirm.Operation.run(confirm, :confirm, auth) do
        {:error, e} ->
          {:error, e}

        ok ->
          confirm
          |> change(charges: confirm.charges - 1)
          |> Repo.update!()

          ok
      end
    end
  end

  defp notify_first_name(email) do
    String.split(email, "@") |> List.first()
  end

  def notify_fields(
        cnf = %Proca.Confirm{
          code: confirm_code,
          email: email,
          message: message,
          object_id: obj_id,
          subject_id: subj_id,
          operation: operation
        }
      ) do
    opmod = Confirm.Operation.mod(cnf)
    cnf = Proca.Repo.preload(cnf, [:creator])

    %{
      operation: Atom.to_string(operation),
      email: email || "",
      message: message || "",
      subject_id: subj_id,
      object_id: obj_id || "",
      code: confirm_code,
      creator: if(cnf.creator != nil, do: Map.take(cnf.creator, [:email, :job_title]), else: %{}),
      accept_link: Proca.Stage.Support.confirm_link(cnf, :confirm),
      reject_link: Proca.Stage.Support.confirm_link(cnf, :reject)
    }
    |> Map.merge(opmod.notify_fields(cnf))
  end

  @doc """
  Send a confirm operation specific email notification to list of emails or to confirm email.
  Uses dynamic dispatch to get template name and personalisation fields from each Confirm operation module.
  Will send the email from instance org backend.
  """
  def notify_by_email(cnf = %Confirm{email: email}) when is_bitstring(email),
    do: notify_by_email(cnf, [email])

  def notify_by_email(cnf = %Confirm{}, emails) when is_list(emails) do
    alias Proca.Service.EmailTemplateDirectory

    opmod = Confirm.Operation.mod(cnf)

    instance = Org.one([preload: [:email_backend]] ++ [:instance])

    recipients =
      emails
      |> Enum.map(fn email ->
        EmailBackend.make_email({notify_first_name(email), email}, {:user, email})
        |> EmailMerge.put_assigns(notify_fields(cnf))
      end)

    case EmailTemplateDirectory.by_name_reload(instance, opmod.email_template(cnf)) do
      {:ok, template} ->
        EmailBackend.deliver(recipients, instance, template)

      :not_found ->
        {:error, :no_template}

      :not_configured ->
        {:error, :no_template}
    end
  end
end
