defmodule Proca.Confirm do
  @moduledoc """
  Confirm represents an action deferred in time.

  OPERATION
  SUBJECT_ID - requester id 
  OBJECT_ID - on what the opration is performed
  CODE

  # Asking to join a campaign:
  
          subject v   object v
  join_campaign(org, campaign)
  - confirms someone from ^ this org.
    Staffers with proper permission? 
  - times: 1
  XXX should send email after

  # Asking to add a partner
  add_partner()
  
  Confirm supporter data - is confirmed by REF
 
  # Confirm action data - it's an open confirm
  confirm_action(action, nil, code)
 

  defenum(ConfirmOperation, confirm_action: 0, join_campaign: 1, add_partner: 2)

  CONFIRMS/REJECTS ARE SYNC

  XXX Expire and remove old confirms!
  """

  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query
  import Proca.Repo
  alias Proca.Confirm
  alias Proca.{ActionPage, Campaign, Org, Action, Staffer, Auth}
  alias Proca.Users.User
  alias Proca.Service.{EmailBackend, EmailRecipient, EmailTemplate}

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
    |> put_assoc(:creator, Map.get(attrs, :user, nil))
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
  def create(ch = %Ecto.Changeset{data: %Confirm{}}) do 
    case insert(ch) do 
      {:ok, cnf} -> cnf

      {:error, %{errors: [{:code,_} | _]}} -> 
        code = get_change(ch, :code)
        random_digit = :rand.uniform(10)
        ch 
        |> change(code: code <> Integer.to_string(random_digit))
        |> create()

      {:error, err} -> {:error, err} 
    end
  end

  def create(attr) when is_map(attr) do 
    changeset(attr) 
    |> create()
  end

  def by_open_code(code) when is_bitstring(code) do
    from(c in Confirm, where: c.code == ^code and is_nil(c.object_id), limit: 1)
    |> one()
  end

  def by_object_code(object_id, code) when is_integer(object_id) and is_bitstring(code) do 
    from(c in Confirm, where: c.code == ^code and c.object_id == ^object_id, limit: 1)
    |> one()
  end

  def by_email_code(email, code)  when is_bitstring(email) and is_bitstring(code) do 
    from(c in Confirm, where: c.code == ^code and c.email == ^email, limit: 1)
    |> one()
  end

  def reject(confirm = %Confirm{}, auth \\ nil) do
    confirm 
    |> change(charges: 0) 
    |> update!
    |> Confirm.Operation.run(:reject, auth)
  end

  def confirm(confirm = %Confirm{}, auth \\ nil) do 
    if confirm.charges <= 0 do 
      {:error, "expired"}
    else
      case Confirm.Operation.run(confirm, :confirm, auth) do 
        {:error, e} -> {:error, e}
        ok -> 
          confirm 
          |> change(charges: confirm.charges - 1) 
          |> update!

          ok
      end
    end
  end

  defp notify_first_name(email) do 
    String.split(email, "@") |> List.first
  end


  @doc """
  Send a confirm operation specific email notification to list of emails or to confirm email.
  Uses dynamic dispatch to get template name and personalisation fields from each Confirm operation module.
  Will send the email from instance org backend.
  """
  def notify_by_email(cnf = %Confirm{email: email}), do: notify_by_email(cnf, [email])
  def notify_by_email(cnf = %Confirm{}, emails) when is_list(emails) do 
    alias Proca.Service.EmailTemplateDirectory

    operation = Confirm.Operation.mod(cnf)

    instance = Org.get_by_name(Org.instance_org_name, 
      [:email_backend, :template_backend])

    recipients = emails 
    |> Enum.map(fn email -> 
      %EmailRecipient{
        first_name: notify_first_name(email),
        email: email,
        fields: operation.email_fields(cnf)
      }
      |> EmailRecipient.put_confirm(cnf)
    end)

    with {:ok, template_ref} <- EmailTemplateDirectory.ref_by_name_reload(
                                    instance, operation.email_template(cnf))
      do 
        template = %EmailTemplate{ref: template_ref}

        EmailBackend.deliver(recipients, instance, template)
      else 
        :not_found -> {:error, :no_tempalte}
        :not_configured -> {:error, :no_template}
    end
  end
end
