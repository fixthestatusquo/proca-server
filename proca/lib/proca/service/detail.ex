defmodule Proca.Service.Detail do
  @moduledoc """
  Implement supporter detail lookup.

  Will use a webhook service to do a POST passing:

  ```
  {
    email, contactRef
  }
  ```

  returns subset of Action Message V2. Currently:
  - `privacy`
    - `optIn`
    - `emailStatus`
    - `emailStatusChanged`
  - `action`
    - `customFields`

  ```
  {
    privacy: {
      optIn: true/false
      emailStatus: "doubleOptIn"
    }
  }
  ```
  """

  alias Proca.{Org, Supporter, Service}
  import Logger

  use Ecto.Schema
  import Ecto.Changeset
  alias Ecto.Changeset
  alias __MODULE__

  defmodule Privacy do
    use Ecto.Schema

    embedded_schema do
      field :opt_in, :boolean
      field :email_status, :string
      field :email_status_changed, :string
    end

    def changeset(ch, params) do
      ch =
        cast(ch, params, [:opt_in, :email_status, :email_status_changed])
        |> Proca.Validations.validate_iso8601_format(:email_status_changed)

      if get_change(ch, :email_status) do
        ch
        |> validate_required(:email_status_changed)
      else
        ch
      end
    end
  end

  defmodule Action do
    use Ecto.Schema

    embedded_schema do
      field :custom_fields, :map
    end

    def changeset(ch, params) do
      cast(ch, params, [:custom_fields])
    end
  end

  embedded_schema do
    embeds_one :privacy, Detail.Privacy
    embeds_one :action, Detail.Action
  end

  @spec changeset(Details | Changeset.t(Details), map()) :: Changeset.t(Details)
  def changeset(ch, params) do
    ch
    |> cast(params, [])
    |> cast_embed(:privacy)
    |> cast_embed(:action)
  end

  def changeset(params), do: changeset(%Detail{}, params)

  @spec lookup(Org, Supporter) :: {:ok, Detail} | {:error, any()}

  def lookup(
        %Org{detail_backend: %{name: :webhook} = srv},
        %Supporter{email: email, fingerprint: ref}
      ) do
    payload =
      Jason.encode!(%{
        "email" => email,
        "contactRef" => ref
      })

    case Service.json_request(srv, srv.host, post: payload, auth: Service.Webhook.auth_type(srv)) do
      {:ok, 200, data} ->
        details = Detail.changeset(ProperCase.to_snake_case(data))

        case details do
          %{valid?: true} ->
            {:ok, apply_changes(details)}

          %{errors: e} = error ->
            warn("Lookup service returned invalid data: (id #{srv.id}) at #{srv.host}: #{e}")
            # XXX calling ProcaWeb module
            ProcaWeb.Helper.format_result(error)
        end

      other ->
        warn(
          "Cannot lookup supporter detail from webhook (id #{srv.id}) at #{srv.host}: #{other}"
        )

        {:error, :other}
    end
  end

  def lookup(%Org{detail_backend: %{name: :testdetail}}, supporter) do
    Proca.TestDetailBackend.lookup(supporter)
  end

  def lookup(_org, _sup), do: {:error, :not_supported}

  @spec update(Changeset.t(Supporter), Changeset.t(Action), Details) ::
          {Changeset.t(Supporter), Changeset.t(Action)}
  def update(supporter, action, details) do
    s =
      supporter
      |> update_opt_in(details.privacy, get_field(action, :action_page).org)
      |> update_email_status(details.privacy)

    a =
      action
      |> update_custom_fields(details.action)

    {s, a}
  end

  # XXX here we should only chnge opt_in if nil (not given?). This is not yet possible
  def update_opt_in(ch, %Detail.Privacy{opt_in: true}, org) do
    change(ch,
      contacts:
        Proca.Contact.change_for_org(
          get_field(ch, :contacts),
          org,
          %{communication_consent: true}
        )
    )
  end

  def update_opt_in(ch, _, _), do: ch

  def update_email_status(ch, %Detail.Privacy{email_status: st, email_status_changed: dt})
      when st != nil and dt != nil do
    change(ch,
      email_status: String.to_existing_atom(st),
      email_status_changed: elem(DateTime.from_iso8601(dt), 1)
    )
  end

  def update_email_status(ch, _), do: ch

  def update_custom_fields(ch, %Detail.Action{custom_fields: cf}) when cf != nil do
    change(ch, fields: Map.merge(get_field(ch, :fields), cf))
  end

  def update_custom_fields(ch, _), do: ch
end
