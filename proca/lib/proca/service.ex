defmodule Proca.Service do
  @moduledoc """
  Service belong to Org and are hostnames, paths and credentials to external services that you can configure.
  """
  use Ecto.Schema
  use Proca.Schema, module: __MODULE__
  import Ecto.Changeset
  import Ecto.Query
  alias Proca.{Repo, Service, Org}

  schema "services" do
    field :name, ExternalService
    field :host, :string, default: ""
    field :user, :string, default: ""
    field :password, :string, default: ""
    field :path, :string
    belongs_to :org, Proca.Org

    timestamps()
  end

  def changeset(service, attrs) do
    assocs = Map.take(attrs, [:org])

    service
    |> cast(attrs, [:name, :host, :user, :password, :path])
    |> change(assocs)
  end

  def build_for_org(attrs, %Org{id: org_id}, service) do
    %Service{}
    |> changeset(attrs)
    |> put_change(:name, service)
    |> put_change(:org_id, org_id)
  end

  def all(q, [{:name, name} | kw]), do: where(q, [s], s.name == ^name) |> all(kw)
  def all(q, [{:org, %Org{id: org_id}} | kw]), do: where(q, [s], s.org_id == ^org_id) |> all(kw)

  def all(q, [:latest | kw]) do
    q
    |> order_by([s], desc: s.updated_at)
    |> limit(1)
    |> all(kw)
  end

  # AWS helpers. 
  def aws_request(req, name, org = %Org{}) do
    case one(name: name, org: org) do
      srv = %Service{} -> aws_request(req, srv)
      x when is_nil(x) -> {:error, {:no_service, name}}
    end
  end

  def aws_request(req = %ExAws.Operation.Query{}, srv) do
    json_req = ExAws.Operation.JSON.new(req.service, Map.from_struct(req))
    aws_request(json_req, srv)
  end

  def aws_request(req = %ExAws.Operation.JSON{}, %Service{
        user: access_key_id,
        password: secret_access_key,
        host: region
      }) do
    # Get JSON not XML
    req = %{req | headers: [{"Accept", "application/json"} | req.headers]}

    req
    |> ExAws.request(
      access_key_id: access_key_id,
      secret_access_key: secret_access_key,
      region: region
    )
  end

  @doc """
  Generic JSON request.

  returns:

  {:ok, 200, data} - when data is returned
  {:ok, code} - for other ok code with no data
  {:error, reason}
  """
  def json_request(srv, url, opts) do
    req = json_request_opts(%{}, opts, srv)

    case :hackney.request(req.method, url, req.headers, req.body) do
      {:ok, code, hdrs, ref} when code in [200, 201] ->
        json_request_read_body(hdrs, ref)

      {:ok, code, _hdrs, _ref} when code in 500..599 ->
        {:error, "HTTP#{code}"}

      {:ok, code, _hdrs, _ref} ->
        {:ok, code}

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp json_request_read_body(hdrs, ref) do
    content_type = :hackney_headers.get_value("content-type", :hackney_headers.new(hdrs))

    case content_type do
      "application/json" <> _ ->
        with {:ok, body} <- :hackney.body(ref),
             {:ok, parsed} <- Jason.decode(body) do
          {:ok, 200, parsed}
        else
          x -> x
        end

      ct ->
        case :hackney.body(ref) do
          {:ok, raw} -> {:ok, 200, raw}
          x -> x
        end
    end
  end

  # defaults
  defp json_request_opts(req, opts, srv) when map_size(req) == 0 do
    %{
      method: :get,
      body: "",
      headers: [Accepts: "application/json", "Content-Type": "application/json"]
    }
    |> json_request_opts(opts, srv)
  end

  defp json_request_opts(req, [], _srv) do
    req
  end

  defp json_request_opts(req, [{:post, body} | rest], srv) do
    %{req | method: :post, body: body}
    |> json_request_opts(rest, srv)
  end

  defp json_request_opts(req, [{:auth, :basic} | rest], srv = %{user: u, password: p})
       when is_bitstring(u) and is_bitstring(p) do
    auth = "#{u}:#{p}" |> Base.encode64()

    %{req | headers: [Authorization: "Basic #{auth}"] ++ req.headers}
    |> json_request_opts(rest, srv)
  end

  defp json_request_opts(req, [{:auth, :header} | rest], srv = %{password: pwd})
       when is_bitstring(pwd) do
    %{req | headers: [Authorization: pwd]}
    |> json_request_opts(rest, srv)
  end

  defp json_request_opts(req, [{:auth, nil} | rest], srv) do
    json_request_opts(req, rest, srv)
  end

  defp json_request_opts(req, [{:form, form} | rest], srv) do
    %{
      req
      | method: :post,
        body: {:form, form},
        headers: Keyword.put(req.headers, :"Content-Type", "application/x-www-form-urlencoded")
    }
    |> json_request_opts(rest, srv)
  end

  defp json_request_opts(req, [{:headers, headers} | rest], srv) do
    %{
      req
      | headers: Keyword.merge(req.headers, headers)
    }
    |> json_request_opts(rest, srv)
  end

  def fetch_file(%Org{storage_backend_id: nil}, _key), do: {:error, :not_supported}

  def fetch_file(%Org{storage_backend: srv}, key), do: fetch_file(srv, key)

  def fetch_file(%Service{name: :supabase} = service, filename) do
    Service.Supabase.fetch(service, filename)
  end

  def fetch_files(org, keys) do
    for k <- keys, reduce: {:ok, []} do
      acc ->
        case acc do
          {:ok, result} ->
            case fetch_file(org, k) do
              {:ok, bytes} -> {:ok, result ++ [{k, bytes}]}
              {:error, reason} -> {:error, reason, result}
            end

          {:error, _reason, _result} = e ->
            e
        end
    end
  end
end
