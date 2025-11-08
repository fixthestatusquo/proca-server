defmodule Proca.Service.Preview.OrgStorage do
  use Agent

  def start_link(_opts) do
    Agent.start_link(fn -> [] end, name: __MODULE__)
  end

  def push(email) do
    message_id =
      email.private.custom_id
      |> String.replace("mtt:", "")

    email = %{email | headers: email.headers |> Map.merge(%{"Message-ID" => message_id})}

    Agent.update(__MODULE__, fn state ->
      [email | state]
    end)

    email
  end

  def get(email_id) do
    Agent.get(__MODULE__, fn state ->
      state
      |> Enum.find(fn message ->
        "#{message.headers["Message-ID"]}" == "#{email_id}"
      end)
    end)
  end

  def all() do
    Agent.get(__MODULE__, & &1)
  end

  def delete_all() do
    Agent.update(__MODULE__, fn _ -> [] end)
  end

  def delete(email_id) do
    Agent.update(__MODULE__, fn state ->
      state
      |> Enum.reject(fn message ->
        "#{message.headers["Message-ID"]}" == "#{email_id}"
      end)
    end)
  end
end
