defmodule ProcaWeb.Resolvers.Contact do
  # import Ecto.Query
  import Ecto.Changeset

  alias Proca.ActionPage
  alias Proca.Signature
  alias Proca.Contact
  alias Proca.Repo
  alias Proca.Source
  alias Proca.Consent
  alias ProcaWeb.Helper

  defp create_or_get_source(%{tracking: t}) do
    Source.get_or_create_by(t)
  end

  defp create_or_get_source(_) do
    {:ok, nil}   # no source but fine
  end

  def create_signature(action_page, signature = %{contact: contact, privacy: cons}) do
    contact_changes = Contact.from_contact_input(contact, action_page)

    with {:ok, cr} <- contact_changes |> Repo.insert(),
         {:ok, _} <- Consent.from_opt_in(cons.opt_in) |> put_assoc(:contact, cr) |> Repo.insert,
         {:ok, src} <- create_or_get_source(signature)
      do
      change(%Signature{}, %{})
      |> put_assoc(:campaign, action_page.campaign)
      |> put_assoc(:action_page, action_page)
      |> put_assoc(:contacts, [cr])
      |> put_assoc(:source, src)
      |> Repo.insert
    else
      insert_error -> insert_error
    end
  end

  def add_signature(_, signature = %{action_page_id: id}, _) do
    case ActionPage.find(id) do
      nil -> 
        {:error, "action_page_id: Cannot find Action Page with id=#{id}"}
      action_page ->
        case create_signature(action_page, signature) do
          {:ok, %Signature{id: signature_id}} ->
            {:ok, signature_id}
          {:error, %Ecto.Changeset{} = changeset} ->
            {:error, Helper.format_errors(changeset)}
          _ ->
            {:error, "other error?"}
        end
    end
  end
end
