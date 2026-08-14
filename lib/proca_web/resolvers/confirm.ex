defmodule ProcaWeb.Resolvers.Confirm do
  alias Proca.{ActionPage, Campaign, Org}
  alias ProcaWeb.Error

  def get(%{code: code, email: email}) when is_bitstring(code) and is_bitstring(email) do
    Proca.Confirm.by_email_code(email, code)
  end

  def get(%{code: code, object_id: id}) when is_bitstring(code) and is_number(id) do
    Proca.Confirm.by_object_code(id, code)
  end

  def get(%{code: code}) when is_bitstring(code) do
    Proca.Confirm.by_open_code(code)
  end

  def org_confirm(_, %{confirm: cnf}, %{context: %{auth: auth}}) do
    case get(cnf) do
      nil -> {:error, [%{message: "code invalid"}]}
      confirm -> Proca.Confirm.confirm(confirm, auth) |> retval(confirm.message)
    end
  end

  def org_reject(_, %{confirm: cnf}, %{context: %{auth: auth}}) do
    case get(cnf) do
      nil -> {:error, [%{message: "code invalid"}]}
      confirm -> Proca.Confirm.reject(confirm, auth) |> retval(confirm.message)
    end
  end

  def user_confirm(_, %{confirm: cnf}, %{context: %{auth: auth}}) do
    case get(cnf) do
      nil -> {:error, [%{message: "code invalid"}]}
      confirm -> Proca.Confirm.confirm(confirm, auth) |> retval(confirm.message)
    end
  end

  def user_reject(_, %{confirm: cnf}, %{context: %{auth: auth}}) do
    case get(cnf) do
      nil -> {:error, [%{message: "code invalid"}]}
      confirm -> Proca.Confirm.reject(confirm, auth) |> retval(confirm.message)
    end
  end

  defp retval(result, message) do
    case result do
      :ok -> {:ok, %{status: :success}}
      {:ok, ap = %ActionPage{}} -> {:ok, %{status: :success, action_page: ap, message: message}}
      {:ok, ca = %Campaign{}} -> {:ok, %{status: :success, campaign: ca, message: message}}
      {:ok, org = %Org{}} -> {:ok, %{status: :success, org: org, message: message}}
      {:noop, _} -> {:ok, %{status: :noop, message: message}}
      {:error, e} when is_bitstring(e) -> {:error, %Error{message: e, code: e}}
      {:error, e} -> {:error, e}
    end
  end
end
