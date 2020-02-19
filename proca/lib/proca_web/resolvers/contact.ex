defmodule ProcaWeb.Resolvers.Contact do
  # import Ecto.Query
  import Ecto.Changeset

  alias Proca.ActionPage
  alias Proca.Signature
  alias Proca.Contact
  alias Proca.Repo

  defp create_signature(action_page, %{contact: contact}) do
    contact_changes = Contact.from_contact_input(contact)
    with {:ok, cr} <- Repo.insert contact_changes do
      change(%Signature{}, %{})
      |> put_assoc(:campaign, action_page.campaign)
      |> put_assoc(:action_page, action_page)
      |> put_assoc(:contacts, [cr])
      |> Repo.insert
    else
      insert_error -> insert_error
    end
  end

  def add_signature(_, signature = %{action_page_id: id}, _) do
    case ActionPage.find(id) do
      nil -> 
        {:error, "Cannot find Action Page with id=#{id}"}
      action_page ->
        case create_signature(action_page, signature) do
          {:ok, %Signature{id: signature_id}} ->
            {:ok, signature_id}
          {:error, %Ecto.Changeset{} = changeset} ->
            {:error, format_errors(changeset)}
          _ ->
            {:error, "other error?"}
        end
    end
  end

  def format_errors(changeset) do
    changeset.errors
    |> Enum.map(fn {field, {msg, _}} ->
      "#{field}: #{msg}"
    end)
  end
end
