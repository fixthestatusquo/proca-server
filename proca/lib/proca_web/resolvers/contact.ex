defmodule ProcaWeb.Resolvers.Contact do
  import Ecto.Query
  import Ecto.Changeset

  alias Proca.ActionPage
  alias Proca.Signature
  alias Proca.Contact
  alias Proca.Repo

  defp create_signature(sig_data, action_page) do
    contact_changes = Contact.from_sig_data(sig_data)
    with {:ok, contact} <- Repo.insert contact_changes do
      change(%Signature{}, %{})
      |> put_assoc(:campaign, action_page.campaign)
      |> put_assoc(:action_page, action_page)
      |> put_assoc(:contacts, [contact])
      |> Repo.insert
    else
      err -> err
    end
  end

  def add_signature(_, %{action_page_id: id, signature: data}, _) do
    with %ActionPage{} = action_page <- ActionPage.find(id),
      {:ok, %Signature{id: signature_id}} <- create_signature(data, action_page) do

      IO.puts "RETURN #{signature_id}"
      {:ok, signature_id}
    end
  end
end
