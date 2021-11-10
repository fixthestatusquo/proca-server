defmodule Proca.Service do
  @moduledoc """
  Service belong to Org and are hostnames, paths and credentials to external services that you can configure.
  """
  use Ecto.Schema
  use Proca.Schema, module: __MODULE__
  import Ecto.Changeset
  import Ecto.Query, only: [from: 1, from: 2, preload: 3, where: 3, join: 4, order_by: 3, limit: 2]
  alias Proca.{Repo, Service, Org}

  schema "services" do
    field :name, ExternalService
    field :host, :string
    field :user, :string
    field :password, :string
    field :path, :string
    belongs_to :org, Proca.Org

    timestamps()
  end

  def changeset(service, attrs) do
    service
    |> cast(attrs, [:name, :host, :user, :password, :path])
  end

  def build_for_org(attrs, %Org{id: org_id}, service) do
    %Service{}
    |> changeset(attrs)
    |> put_change(:name, service)
    |> put_change(:org_id, org_id)
  end

  def all(q, [{:id, id} | kw]), do: where(q, [s], s.id == ^id) |> all(kw)
  def all(q, [{:name, name} | kw]), do: where(q, [s], s.name == ^name) |> all(kw)
  def all(q, [{:org, %Org{id: org_id}} | kw]), do: where(q, [s], s.org_id == ^org_id) |> all(kw)

  def update(srv, [{:org, org} | kw]) do 
    srv
    |> put_assoc(:org, org)
    |> update(kw)
  end

  # XXX potential problem - org.services might not be sorted from latest updated
  # XXX inconsistent arg order 
  def get_one_for_org(name, %Org{services: lst}) when is_list(lst) do
    case Enum.filter(lst, fn srv -> srv.name == name end) do
      [s | _] -> s
      [] -> nil
    end
  end

  def get_one_for_org(name, org = %Org{}) do
    Ecto.assoc(org, :services)
    |> where([s], s.name == ^name)
    |> order_by([s], desc: s.updated_at)
    |> limit(1)
    |> Repo.one()
  end


  # AWS helpers. 
  def aws_request(req, name, org = %Org{}) do
    case get_one_for_org(name, org) do
      srv = %Service{} -> aws_request(req, srv)
      x when is_nil(x) -> {:error, {:no_service, name}}
    end
  end

  def aws_request(req, %Service{user: access_key_id, password: secret_access_key, host: region}) do
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
      {:ok, 200, _hdrs, ref} ->
        case json_request_read_body(ref) do
          {:ok, data} -> {:ok, 200, data}
          x -> x
        end

      {:ok, code, _hdrs, _ref} ->
        {:ok, code} 

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp json_request_read_body(ref) do
    with {:ok, body} <- :hackney.body(ref),
         {:ok, parsed} <- Jason.decode(body) do
      {:ok, parsed}
    else
      x -> x
    end
  end

  # defaults
  defp json_request_opts(req, opts, srv) when map_size(req) == 0 do
    req = %{
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
  when is_bitstring(u) and is_bitstring(p)
    do
    auth = "#{u}:#{p}" |> Base.encode64()

    %{req | headers: [Authorization: "Basic #{auth}"] ++ req.headers}
    |> json_request_opts(rest, srv)
  end

  defp json_request_opts(req, [{:auth, :header} | rest], srv = %{password: pwd}) when is_bitstring(pwd) do
    %{req | headers: [Authorization: pwd]}
    |> json_request_opts(rest, srv)
  end

  defp json_request_opts(req, [{:auth, nil} | rest], srv) do
    json_request_opts(req, rest, srv)
  end

  defp json_request_opts(req, [{:form, form} | rest], srv) do 
    %{req | 
      method: :post, 
      body: {:form, form}, 
      headers: Keyword.put(req.headers, :"Content-Type", "application/x-www-form-urlencoded")
      }
    |> json_request_opts(rest, srv)
  end
  end
