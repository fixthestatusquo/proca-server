defmodule Proca.Service do
  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query
  alias Proca.{Repo,Service,Org}

  schema "services" do
    field :name, ExternalService
    field :host, :string
    field :user, :string
    field :password, :string
    field :path, :string
    belongs_to :org, Proca.Org

    timestamps()
  end

  def build_for_org(attrs, %Org{id: org_id}, service) do
    %Service{}
    |> cast(attrs, [:name, :host, :user, :password, :path])
    |> put_change(:name, service)
    |> put_change(:org_id, org_id)
  end

  def get_one_for_org(name, %Org{services: lst}) when is_list(lst) do
    case Enum.filter(lst, fn srv -> srv.name == name end) do
      [s | _] -> s
      [] -> nil
    end
  end

  def get_one_for_org(name, org = %Org{}) do
    Ecto.assoc(org, :services)
    |> where([s], s.name == ^name)
    |> order_by([s], [desc: s.updated_at])
    |> limit(1)
    |> Repo.one()
  end

  def aws_request(req, name, %Org{} = org) do
    case get_one_for_org(name, org) do
      srv = %Service{} -> aws_request(req, srv)
      x when is_nil(x) -> {:error, { :no_service, name }}
    end
  end

  def aws_request(req, %Service{user: access_key_id,
                           password: secret_access_key,
                           host: region}) do
    req
    |> ExAws.request([
      access_key_id: access_key_id,
      secret_access_key: secret_access_key,
      region: region])
  end
end
