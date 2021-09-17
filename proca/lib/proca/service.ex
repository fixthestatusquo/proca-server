defmodule Proca.Service do
  @moduledoc """
  Service belong to Org and are hostnames, paths and credentials to external services that you can configure.
  """
  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query
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
    |> cast(attrs, [:host, :user, :password, :path])
  end

  def build_for_org(attrs, %Org{id: org_id}, service) do
    %Service{}
    |> changeset(attrs)
    |> put_change(:name, service)
    |> put_change(:org_id, org_id)
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

  # Generic JSON request helpers
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

  defp json_request_opts(req, opts, srv) when map_size(req) == 0 do
    req = %{
      method: :get,
      body: "",
      headers: [Accepts: "application/json", "Content-Type": "application/json"]
    }

    json_request_opts(req, opts, srv)
  end

  defp json_request_opts(req, [], _srv) do
    req
  end

  defp json_request_opts(req, [{:auth, :basic} | rest], srv) do
    auth = "#{srv.user}:#{srv.password}" |> Base.encode64()

    %{req | headers: [Authorization: "Basic #{auth}"] ++ req.headers}
    |> json_request_opts(rest, srv)
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
