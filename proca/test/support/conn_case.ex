defmodule ProcaWeb.ConnCase do
  @moduledoc """
  This module defines the test case to be used by
  tests that require setting up a connection.

  Such tests rely on `Phoenix.ConnTest` and also
  import other functionality to make it easier
  to build common data structures and query the data layer.

  Finally, if the test case interacts with the database,
  we enable the SQL sandbox, so changes done to the database
  are reverted at the end of every test. If you are using
  PostgreSQL, you can even run database tests asynchronously
  by setting `use ProcaWeb.ConnCase, async: true`, although
  this option is not recommended for other databases.
  """

  use ExUnit.CaseTemplate

  using do
    quote do
      # Import conveniences for testing with connections
      import Plug.Conn
      import Phoenix.ConnTest
      alias ProcaWeb.Router.Helpers, as: Routes
      alias ProcaWeb.UserAuth
      alias Proca.Users.User

      # The default endpoint for testing
      @endpoint ProcaWeb.Endpoint

      def auth_api_post(conn, query, %User{email: email}) do
        auth_api_post(conn, query, email, 
          Proca.Factory.password_from_email(email))
      end

      def auth_api_post(conn, query, email, password) 
        when is_bitstring(email) and is_bitstring(password) do
        conn
        |> put_req_header("authorization", "Basic " <> Base.encode64(email <> ":" <> password))
        |> api_post(query)
      end

      def api_post(conn, query) when is_bitstring(query) do
        conn
        |> post("/api", %{query: query})
      end

      def api_post(conn, query) when is_map(query) do
        conn
        |> post("/api", query)
      end

      def is_success(res) do
        assert res["errors"] == nil
        res
      end

      def has_error_message(res, message) do
        assert length(Map.get(res, "errors", [])) > 0
        assert Enum.any?(Map.get(res, "errors", []), fn
          %{"message" => msg} -> msg == message
          _ -> false
        end)
        res
      end

      @doc """
      Setup helper that registers and logs in users.

      setup :register_and_log_in_user

      It stores an updated connection and a registered user in the
      test context.
      """
      def register_and_log_in_user(%{conn: conn}) do
        user = Proca.UsersFixtures.user_fixture()
        %{conn: log_in_user(conn, user), user: user}
      end

      @doc """
      Logs the given `user` into the `conn`.

      It returns an updated `conn`.
      """
      def log_in_user(conn, user) do
        token = Proca.Users.generate_user_session_token(user)

        conn
        |> Phoenix.ConnTest.init_test_session(%{})
        |> Plug.Conn.put_session(:user_token, token)
      end
    end
  end

  setup tags do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Proca.Repo)

    unless tags[:async] do
      Ecto.Adapters.SQL.Sandbox.mode(Proca.Repo, {:shared, self()})
    end

    if tags[:start] do
      if :processing in tags[:start], do: Proca.Server.Processing.start_link([])
    end

    {:ok, conn: Phoenix.ConnTest.build_conn()}
  end



end
