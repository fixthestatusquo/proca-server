defmodule ProcaWeb.Resolvers.ReportError do
  @behaviour Absinthe.Middleware

  def call(
        %Absinthe.Resolution{
          state: :resolved,
          errors: [_ | _],
          context: context
        } = resolution,
        _
      ) do
    if enabled?() and enabled_for_context?(context) do
      try do
        info = %{
          path: Enum.reverse(Enum.map(resolution.path, &Map.get(&1, :name))),
          extensions: resolution.extensions,
          errors: resolution.errors,
          user:
            case resolution.context do
              %{user: %{email: email}} -> email
              _ -> nil
            end,
          org:
            case resolution.context do
              %{org: %{name: name}} -> name
              _ -> nil
            end,
          campaign:
            case resolution.context do
              %{campaign: %{name: name}} -> name
              _ -> nil
            end,
          name: resolution.arguments[:name],
          id: resolution.arguments[:id]
        }

        event =
          "User error " <>
            (info.path |> Enum.join(".")) <>
            " " <> (Enum.map(info.errors, &error_message/1) |> Enum.join(", "))

        Sentry.capture_message(event, extra: info, level: "warning")
      rescue
        e in RuntimeError ->
          Sentry.capture_message("Other user error",
            extra: %{exception: Map.get(e, :message, "(no message)")}
          )
      end
    end

    resolution
  end

  def call(reso, _) do
    reso
  end

  defp error_message(e) when is_map(e) do
    path = Map.get(e, :path, nil)
    msg = Map.get(e, :message)

    if is_list(path) do
      Enum.join(path, ".") <> " " <> msg
    else
      msg
    end
  end

  defp error_message(e) when is_bitstring(e) do
    e
  end

  defp error_message(e) do
    inspect(e)
  end

  def enabled? do
    Application.get_env(:proca, __MODULE__)[:enable] and not is_nil(Sentry.Config.dsn())
  end

  def enabled_for_context?(context) do
    if Application.get_env(:proca, __MODULE__)[:auth_only] do
      Map.has_key?(context, :auth)
    else
      true
    end
  end

  def scrub_params(conn) do
    # Makes use of the default body_scrubber to avoid sending password
    # and credit card information in plain text.  To also prevent sending
    # our sensitive "my_secret_field" and "other_sensitive_data" fields,
    # we simply drop those keys.
    Sentry.PlugContext.default_body_scrubber(conn)
    |> Map.drop(["query"])
    |> Map.update("variables", %{}, &censor_bars/1)
  end

  def scrub_headers(conn) do
    Sentry.PlugContext.default_header_scrubber(conn)
    |> Map.drop(["X-Forwarded-For", "X-Real-Ip"])
  end

  def censor_bars(a) when is_map(a) do
    for {k, v} <- a, into: %{} do
      if Enum.member?(["country", "documentType"], k) do
        {k, v}
      else
        {k, censor_bars(v)}
      end
    end
  end

  def censor_bars(a) when is_list(a) do
    for e <- a, do: censor_bars(e)
  end

  def censor_bars(a) when is_bitstring(a) do
    a
    |> String.replace(~r/[0-9]/, "0")
    |> String.replace(~r/\p{L}/u, "X")
  end

  def censor_bars(a), do: a
end
