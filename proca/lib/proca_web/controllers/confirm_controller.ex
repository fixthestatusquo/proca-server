defmodule ProcaWeb.ConfirmController do
  @moduledoc """
  Controller processing two kinds of confirm links:
  1. supporter confirm (double opt in in most cases)
  2. generic Confirm
  """

  use ProcaWeb, :controller
  import Ecto.Changeset
  import Proca.Repo
  alias Proca.{Supporter, Action, Confirm, Staffer, ActionPage, Auth}
  import ProcaWeb.Helper, only: [request_basic_auth: 2]

  @doc """
  Handle a supporter confirm link of form:
  /link/s/123/REF_REF_REF/accept

  Optionally can contain:
  ?doi=1  - for a double opt in

  This is a special case where we do not use Confirm model. Instead, we use the
  ref known to supporter. This way we do not have to create so many Confirm
  records when org is using double opt in.

  This path optionally takes a ?redir query param to redirect after accepting/rejecting.

  Handle double opt in link of form:
  /link/d/1234/REF_REF_REF

  It will double opt in Supporter email_status. This will just change the
  email_status, and possibly send the supporter_updated event. Can be useful to
  do a double opt in when we have actually already processed the action.

  """
  def supporter(conn, params) do
    with {:ok, args} <- supporter_parse_params(params),
         {:ok, action} <- find_action(args),
         {:ok, action} <- handle_double_opt_in(action, args[:doi]),
         :ok <- handle_supporter(action, args.verb) do
      conn
      |> redirect(external: redirect_url(action, args))
      |> halt()
    else
      {:error, status, msg} ->
        conn |> resp(status, error_msg(msg)) |> halt()
    end
  end

  defp extra_redirect_params(args) do
    c = if args[:verb], do: [proca_confirm: args[:verb]], else: []
    d = if args[:doi], do: [proca_doi: args[:doi]], else: []

    c ++ d
  end

  defp prepend_extra_redirect_params(url, args) do
    uri = URI.parse(url)

    query =
      case uri.query do
        nil -> []
        q -> URI.query_decoder(q, :rfc3986) |> Enum.to_list()
      end

    query = extra_redirect_params(args) ++ query

    uri = %{uri | query: URI.encode_query(query)}

    URI.to_string(uri)
  end

  def redirect_url(action, args) do
    case args do
      %{redir: url} when is_bitstring(url) ->
        prepend_extra_redirect_params(url, args)

      _ ->
        case ActionPage.Status.get_last_location(action.action_page_id) do
          nil -> "/"
          url -> url <> "?" <> URI.encode_query(extra_redirect_params(args), :rfc3986)
        end
    end
  end

  defp supporter_parse_params(params) do
    types = %{
      action_id: :integer,
      verb: :string,
      ref: :string,
      redir: :string,
      doi: :string
    }

    args =
      cast({%{}, types}, params, Map.keys(types))
      |> validate_inclusion(:verb, ["accept", "reject"])
      |> validate_inclusion(:doi, ["1", "0", "true", "false", "yes", "no"])
      |> Supporter.decode_ref(:ref)
      |> validate_required([:action_id, :verb, :ref])

    if args.valid? do
      {:ok, apply_changes(args)}
    else
      {:error, 400, "malformed link"}
    end
  end

  defp find_action(%{action_id: action_id, ref: ref}) do
    action = Action.get_by_id_and_ref(action_id, ref)

    if is_nil(action) do
      {:error, 404, "malformed link"}
    else
      {:ok, action}
    end
  end

  def double_opt_in(conn, params) do
    with {:ok, args} <- double_opt_in_parse_params(params),
         {:ok, action} <- find_action(args),
         {:ok, action} <- handle_double_opt_in(action, "true") do
      conn
      |> redirect(external: redirect_url(action, Map.put(args, :doi, 1)))
      |> halt()
    else
      {:error, status, msg} ->
        conn |> resp(status, error_msg(msg)) |> halt()
    end
  end

  defp double_opt_in_parse_params(params) do
    types = %{
      action_id: :integer,
      ref: :string,
      redir: :string
    }

    args =
      cast({%{}, types}, params, Map.keys(types))
      |> Supporter.decode_ref(:ref)
      |> validate_required([:action_id, :ref])

    if args.valid? do
      {:ok, apply_changes(args)}
    else
      {:error, 400, "malformed link"}
    end
  end

  # Change the supporter status on supporter confirm
  defp handle_supporter(action = %Action{supporter: sup}, "accept") do
    case Supporter.confirm(sup) do
      {:ok, sup2} -> Proca.Stage.Action.process(%{action | supporter: sup2})
      {:noop, _} -> :ok
      {:error, msg} -> {:error, 400, msg}
    end
  end

  defp handle_supporter(_action = %Action{supporter: sup}, "reject") do
    case Supporter.reject(sup) do
      {:ok, _} -> :ok
      {:noop, _} -> :ok
      {:error, msg} -> {:error, 400, msg}
    end
  end

  # Change the supporter email_status
  defp handle_double_opt_in(action = %Action{supporter: sup}, doi)
       when doi in ["1", "yes", "true"] do
    case update_and_notify(Supporter.changeset(sup, %{email_status: :double_opt_in})) do
      {:ok, sup2} -> {:ok, %{action | supporter: sup2}}
      {:error, _ch} -> {:error, 400, "cannot double opt in"}
    end
  end

  defp handle_double_opt_in(action, _), do: {:ok, action}

  @doc """
  Handles a generic accept/reject of a Confirm.

  Link of form: /link/1234567/accept

  Optionally with query params:
  - email - if this Confirm was created for a recipient with email
  - id - if this Confirm was created for particular object id (schema determined by Confirm operation)
  - redir - query param to redirect after accepting/rejecting.
  """
  def confirm(conn, params) do
    with {:ok, args} <- confirm_parse_params(params),
         confirm = %Confirm{} <- get_confirm(args),
         :ok <- handle_confirm(confirm, args.verb, get_auth(conn, Map.get(params, "org", nil))) do
      conn
      |> redirect(to: Map.get(args, :redir, "/"))
      |> halt()
    else
      {:error, 401, msg} -> conn |> request_basic_auth(msg) |> halt()
      {:error, status, msg} -> conn |> resp(status, msg) |> halt()
      nil -> conn |> resp(400, error_msg("code invalid")) |> halt()
    end
  end

  defp get_auth(conn, org_name) do
    case conn.assigns.user do
      nil ->
        nil

      user = %Proca.Users.User{} ->
        %Auth{
          user: user,
          staffer:
            if(is_nil(org_name),
              do: Staffer.for_user(user),
              else: Staffer.for_user_in_org(user, org_name)
            )
        }
    end
  end

  defp handle_confirm(confirm, "accept", auth) do
    case Confirm.confirm(confirm, auth) do
      :ok -> :ok
      {:ok, _} -> :ok
      {:error, "unauthorized"} -> {:error, 401, "unauthorized"}
      {:error, "expired"} -> {:error, 400, "expired"}
      {:error, msg} -> {:error, 500, error_msg(msg)}
    end
  end

  defp handle_confirm(confirm, "reject", auth) do
    case Confirm.reject(confirm, auth) do
      :ok -> :ok
      {:ok, _} -> :ok
      {:error, "unauthorized"} -> {:error, 401, "Unauthorized"}
      {:error, msg} -> {:error, 500, error_msg(msg)}
    end
  end

  defp confirm_parse_params(params) do
    types = %{
      code: :string,
      verb: :string,
      email: :string,
      id: :integer,
      redir: :string
    }

    args =
      cast({%{}, types}, params, Map.keys(types))
      |> validate_inclusion(:verb, ["accept", "reject"])
      |> validate_format(:code, ~r/^[0-9]+$/)
      |> validate_required([:code, :verb])

    if args.valid? do
      {:ok, apply_changes(args)}
    else
      {:error, 400, "malformed link"}
    end
  end

  defp get_confirm(%{code: code, email: email}) do
    Confirm.by_email_code(email, code)
  end

  defp get_confirm(%{code: code, id: id}) do
    Confirm.by_object_code(id, code)
  end

  defp get_confirm(%{code: code}) do
    Confirm.by_open_code(code)
  end

  defp error_msg(msg) when is_bitstring(msg) do
    %{errors: [%{message: msg}]} |> Jason.encode!()
  end

  defp error_msg(msg = %Ecto.Changeset{}) do
    %{errors: ProcaWeb.Helper.format_errors(msg)} |> Jason.encode!()
  end

  defp error_msg(other), do: other |> Jason.encode!()
end
