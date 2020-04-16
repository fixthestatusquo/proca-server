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
    data_mod = ActionPage.data_module(action_page)

    case apply(data_mod, :from_input, [contact]) do
      %{valid?: true} = data ->
        with contact = %{valid?: true} <- apply(data_mod, :to_contact, [data, action_page]),
             sig = Signature.build(contact, action_page, cons)
          do
          case signature do
            %{tracking: tr} -> put_assoc(sig, :source, Source.get_or_create_by(tr))
            _ -> sig
          end
          |> Repo.insert
        end
      invalid_data -> {:error, invalid_data}
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
