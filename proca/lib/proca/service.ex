defmodule Proca.Service do
  @moduledoc """
  # Service belong to Org and are hostnames, paths and credentials to external services that you can configure.

  ## Service concept in Proca Server

  Every organisation can own a set of services, and each service type has a
  name. A service record represents API access. Currently names are:

  - ses - AWS SES
  - sqs - AWS SQS
  - mailjet - Mailjet Email
  - smtp - SMTP Email
  - wordpress - Wordpress site with API (unused)
  - stripe - Stripe donation API
  - test_stripe - Stripe donation API for test actions
  - testmail - mock email backend used in tests
  - webhook - a HTTP POST json API
  - supabase - Supabase API (for storage)
  - testdetail - mock detail service API

  An org can have more then one of particular service type (same name), with
  different ids. Warning: Proca CLI and API lets you manipulate services by name, and so
  you cannot use it to distinguish between for example two `webhook` services.
  Sorry! However, this was only needed for very complex setups, and we did not want to overcomplicate.

  ## Using services

  Each service can be *used* in a stage of processing, by a particular worker,
  or in other internal service such as MTT sender. As a special case, an org can
  use `SYSTEM` service which will borrow a service used by instance org, for
  that particular function.

  A service must be assigned to some usage/function, it is not enough that org owns it.
  Here is a list of backends:

  Not all services support all usages, of course.

  - `emailBackend` - Send emails to supporters and MTTs through this API. Works with: ses, mailjet, smtp, testmail
  - `detailBackend` - Fetch/lookup member details from this service. Works with: webhook
  - `storageBackend` - Fetch files (attachments to MTT). Works with: supabase
  - `pushBackend` - Deliver action data. Works with: sqs, webhook
  - `eventBackend` - Deliver events data (See `Proca.Stage.Event`). Works with: sqs, webhook

  Proca will dynamically start and stop workers that perform particular
  function, when the service will be attached or removed from that function. Eg.
  `proca service:email -N` to stop worker that sends supporter emails, do `proca
  service:email -n mailjet` to attach mailjet service as email backend and start
  the worker again.

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

  @behaviour ExAws.Request.HttpClient

  @doc """
  Implement above behavuiour for ExAws library
  """
  @impl true
  def request(method, url, body, headers, http_opts) do
    client = Tesla.client([
      {Tesla.Middleware.Headers, headers}
    ])

    case Tesla.request(client, method: method, url: url, body: body) do
      {:ok, response} -> {
        :ok, Map.from_struct(response) |> Map.put(:status_code, response.status)
      }
      {:error, reason} -> {:error, %{reason: reason}}
    end
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

    client = Tesla.client([
      {Tesla.Middleware.Headers, req.headers},
      Tesla.Middleware.JSON,
    ])

    case Tesla.request(client, method: req.method, url: url, body: req.body) do
      {:ok, response = %{status: code}} when code in [200, 201] -> {:ok, code, response.body}

      {:ok, %{status: code}} when code in 500..599 -> {:error, "HTTP#{code}"}

      {:ok, response} -> {:ok, response.status}

      {:error, _reason} = e -> e
    end
  end

  # defaults
  defp json_request_opts(req, opts, srv) when map_size(req) == 0 do
    %{
      method: :get,
      body: nil,
      headers: [{"Accept", "application/json"}]
    }
    |> json_request_opts(opts, srv)
  end

  defp json_request_opts(req, [], _srv) do
    req
  end

  defp json_request_opts(req, [{:post, body} | rest], srv) do
    %{req | method: :post, body: body, headers: [{"Content-Type", "application/json"} | req.headers]}
    |> json_request_opts(rest, srv)
  end

  defp json_request_opts(req, [{:auth, :basic} | rest], srv = %{user: u, password: p})
       when is_bitstring(u) and is_bitstring(p) do
    auth = "#{u}:#{p}" |> Base.encode64()

    %{req | headers: [{"Authorization", "Basic #{auth}"}] ++ req.headers}
    |> json_request_opts(rest, srv)
  end

  defp json_request_opts(req, [{:auth, :header} | rest], srv = %{password: pwd})
       when is_bitstring(pwd) do
    %{req | headers: [{"Authorization", pwd}] ++ req.headers}
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
