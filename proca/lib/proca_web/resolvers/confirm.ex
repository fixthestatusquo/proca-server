defmodule ProcaWeb.Resolvers.Confirm do 
  alias Proca.{ActionPage, Campaign, Org}

  def get(%{code: code, email: email}) when is_bitstring(code) and is_bitstring(email) do 
    Proca.Confirm.by_email_code(email, code)
  end

  def get(%{code: code, id: id}) when is_bitstring(code) and is_number(id) do 
    Proca.Confirm.by_object_code(id, code)
  end

  def get(%{code: code}) when is_bitstring(code) do 
    Proca.Confirm.by_open_code(code)
  end

  def org_confirm(_, %{invite: inv}, %{context: %{staffer: st}}) do 
    case get(inv) do 
      nil -> {:error, [%{message: "code invalid"}]}
      confirm -> Proca.Confirm.confirm(confirm, st) |> retval()
    end
  end

  def org_reject(_, %{invite: inv}, %{context: %{staffer: st}}) do 
    case get(inv) do 
      nil -> {:error, [%{message: "code invalid"}]}
      confirm -> Proca.Confirm.reject(confirm, st) |> retval()
    end
  end

  defp retval(result) do 
    case result do 
        :ok ->  {:ok, %{status: :success}}
        {:ok, ap = %ActionPage{}} -> {:ok, %{status: :success, action_page: ap}}
        {:ok, ca = %Campaign{}} -> {:ok, %{status: :success, campaign: ca}}
        {:ok, org = %Org{}} -> {:ok, %{status: :success, org: org}}
        {:noop, _} -> {:ok, %{status: :noop}}
        {:error, e} -> {:error, e}
      end

  end
end
