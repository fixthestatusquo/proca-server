defmodule Proca.Users.Status do
  use GenServer

  import Ecto.Query
  import Ecto.Changeset
  import Proca.Repo, only: [all: 1, update!: 1]

  alias Proca.Users.{User, UserToken}

  @interval 10_000

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl true
  def init(opts) do
    interval = Keyword.get(opts, :interval, @interval)

    call_me(interval)

    {
      :ok,
      %{
        token_last_seen: %{},
        interval: interval
      }
    }
  end

  defp call_me(ms) do
    Process.send_after(self(), :sync, ms)
  end

  @impl true
  def handle_cast({:api_token_used, token, _user}, st) do
    now = NaiveDateTime.truncate(NaiveDateTime.utc_now(), :second)

    {
      :noreply,
      %{st | token_last_seen: Map.put(st.token_last_seen, token.id, now)}
    }
  end

  def api_token_used(%User{} = user, %UserToken{} = token) do
    GenServer.cast(__MODULE__, {:api_token_used, token, user})
  end

  @impl true
  def handle_info(:sync, st) do
    ids = Map.keys(st.token_last_seen)
    tokens = all(from ut in UserToken, where: ut.id in ^ids)

    tokens
    |> Enum.each(fn tok ->
      update!(change(tok, inserted_at: st.token_last_seen[tok.id]))
    end)

    call_me(st.interval)

    {
      :noreply,
      %{st | token_last_seen: %{}}
    }
  end
end
