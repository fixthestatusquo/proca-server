defmodule Proca.Confirm.AddStaffer do
  @moduledoc """
  Confirmed operation to add staffer to org.
  subject: org
  object_id: perms (binary)
  email: invited user
  """
  alias Proca.Confirm
  @behaviour Confirm.Operation

  alias Proca.{Staffer, Org, Auth, Permission}
  import Proca.Repo

  def changeset(email, role, %Auth{user: user, staffer: %Staffer{org_id: org_id}}, message \\ nil)
      when is_bitstring(email) do
    role_perms = Permission.add(0, Staffer.Role.permissions(role))

    %{
      operation: :add_staffer,
      subject_id: org_id,
      object_id: role_perms,
      email: email,
      message: message,
      creator: user
    }
    |> Confirm.changeset()
  end

  def run(
        %Confirm{operation: :add_staffer, subject_id: org_id, object_id: perms},
        :confirm,
        %Auth{user: user}
      ) do
    with {:org, org = %Org{}} <- {:org, Org.one(id: org_id)},
         {:exists?, nil} <- {:exists?, Staffer.one(org: org, user: user)},
         {:ok, _new_staffer} <- insert(Staffer.changeset(%{user: user, org: org, perms: perms})) do
      {:ok, org}
    else
      {:org, nil} -> {:error, :org_not_found}
      {:exists?, _s} -> {:error, :staffer_exists}
      {:error, chset} -> {:error, chset}
    end
  end

  def run(%Confirm{operation: :add_staffer}, :reject, _auth), do: :ok

  def email_template(%Confirm{operation: :add_staffer}), do: "add_staffer"

  def notify_fields(%Confirm{operation: :add_staffer, subject_id: org_id}) do
    org = Org.one(id: org_id)

    %{
      org: %{
        name: org.name,
        title: org.title
      }
    }
  end
end
