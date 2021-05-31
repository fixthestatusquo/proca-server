defmodule Proca.Confirm do
  @moduledoc """
  Confirm represents an action deferred in time.

  OPERATION
  SUBJECT_ID - requester id 
  OBJECT_ID
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
  alias Proca.{ActionPage,Campaign,Org,Action,Staffer}
  alias Proca.Service.{EmailBackend, EmailRecipient, EmailTemplate}

  schema "confirms" do
    field :operation, ConfirmOperation
    field :subject_id, :integer
    field :object_id, :integer
    field :email, :string
    field :code, :string
    field :charges, :integer, default: 1

    timestamps()
  end


  @doc false
  def changeset(confirm, attrs) do
    confirm
    |> cast(attrs, [:operation, :subject_id, :object_id, :email, :charges])
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

  def reject(confirm = %Confirm{}, staffer \\ nil) do
    confirm 
    |> change(charges: 0) 
    |> update!
    |> Confirm.Operation.run(:reject, staffer)
  end

  def confirm(confirm = %Confirm{}, staffer \\ nil) do 
    if confirm.charges <= 0 do 
      {:error, "expired"}
    else
      case Confirm.Operation.run(confirm, :confirm, staffer) do 
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

  def notify_template(%Confirm{operation: :join_campaign}), do: "join_campaign"
  def notify_template(%Confirm{operation: :add_partner}), do: "add_partner"

  def notify_by_email(cnf = %Confirm{email: email}) do 
    instance = Org.get_by_name(Org.instance_org_name, [:email_backend, :template_backend])
    recipient = %EmailRecipient{
      first_name: notify_first_name(email),
      email: email 
    }
    |> EmailRecipient.put_confirm(cnf)

    with {:ok, template_ref} <- Proca.Service.EmailTemplateDirectory.ref_by_name_reload(instance, notify_template(cnf))
      do 
        template = %EmailTemplate{ref: template_ref}

        EmailBackend.deliver([recipient], instance, template) |> hd
      else 
        :not_found -> {:error, :no_tempalte}
        :not_configured -> {:error, :no_template}
    end
  end
end
