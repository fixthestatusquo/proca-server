defmodule Proca.Confirm.AddStaffer do 
  alias Proca.Confirm
  @behaviour Confirm.Operation

  alias Proca.{Campaign, ActionPage, Staffer, Org, Auth, Error}
  import Proca.Repo

  def create(email, %Auth{user: user, staffer: %Staffer{org_id: org_id}}, message \\ nil) when is_bitstring(email) do
    # XXX test for campaign manager
    %{
      operation: :add_staffer,
      subject_id: org_id,
      email: email,
      message: message,
      creator: user
    }
    |> Confirm.create()
  end
  
  def run(%Confirm{operation: :add_staffer, subject_id: org_id}, :confirm, %Auth{user: user}) do 
    with {:org, org = %Org{}} <- Org.one(id: org_id),
      {:ok, new_staffer} <- Staffer.create(user: user, org: org, role: :owner) do 

      {:ok, org}
    else 
      {org, nil} -> {:error, :org_not_found}
      {:error, chset} -> {:error, chset}
    end
  end

  def run(%Confirm{operation: :add_staffer}, :reject, _auth), do: :ok

  def email_template(%Confirm{operation: :add_staffer}), do: "staffer_invite"

  def email_fields(%Confirm{operation: :add_staffer, subject_id: org_id}) do
    org = Org.one(id: org_id)
    %{
      "org_name" => org.name,
      "org_title" => org.title
    }
  end
end
