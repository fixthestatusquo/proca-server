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

  defp add_tracking(sig, %{tracking: tr}) do
    with {:ok, src} <- Source.get_or_create_by(tr) do
      put_assoc(sig, :source, src) 
    else
      # XXX report this somehow? This is a strange situation where we could not insert Source.
      # even though we retried 2 times
      {:error, _m} -> sig
    end
  end

  defp add_tracking(sig, %{}) do
    sig
  end


  def create_signature(action_page, signature = %{contact: contact, privacy: cons}) do
    data_mod = ActionPage.data_module(action_page)

    case apply(data_mod, :from_input, [contact]) do
      %{valid?: true} = data ->
        with contact = %{valid?: true} <- apply(data_mod, :to_contact, [data, action_page]),
             sig = %{valid?: true} <- Signature.build(contact, action_page, cons),
               sig_fpr = %{valid?: true} <- apply(data_mod, :add_fingerprint, [sig, data])
          do
          sig_fpr
          |> add_tracking(signature)
          |> Repo.insert
          else
            invalid_data ->
              IO.inspect(invalid_data, label: "Error")
              {:error, invalid_data}
        end
      %{valid?: false} = invalid_data -> {:error, invalid_data}
    end

  end

  def add_signature(_, signature = %{action_page_id: id}, _) do
    case ActionPage.find(id) do
      nil -> 
        {:error, "action_page_id: Cannot find Action Page with id=#{id}"}
      action_page ->
        case create_signature(action_page, signature) do
          {:ok, %Signature{id: _signature_id, fingerprint: fpr}} ->
            {:ok, Base.encode64(fpr)}
          {:error, %Ecto.Changeset{} = changeset} ->
            {:error, Helper.format_errors(changeset)}
          _ ->
            {:error, "other error?"}
        end
    end
  end

end
