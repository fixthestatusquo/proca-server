defmodule Proca.MTT do
  use Ecto.Schema
  use Proca.Schema, module: __MODULE__
  import Ecto.Changeset
  import Proca.Validations

  schema "mtt" do
    field :start_at, :utc_datetime
    field :end_at, :utc_datetime
    field :stats, :map, default: %{}
    field :test_email, :string
    field :cc_contacts, {:array, :string}, default: []
    field :cc_sender, :boolean, default: false

    # TODO:
    # field :distributed, :boolean, default: false
    # # if distributed, each AP has a template, and each partner sends via their mail system
    # field :spoof_username, :boolean, default: true

    # maybe an ap override is necessary
    # optional! must support also sending without it.
    field :message_template, :string

    field :max_emails_per_hour, :integer
    field :timezone, :string, default: "Etc/UTC"
    # DB column name is historical; prefer "pacing" / "throttle" in docs and metrics.
    # true  = pacing delivery (MTTWorker, proportional cycles)
    # false = throttle delivery (MTTScheduler, per-target hourly cap)
    field :drip_delivery, :boolean, default: true

    belongs_to :campaign, Proca.Campaign
  end

  @doc """
  MTT delivery mode for telemetry and docs.

  - `:pacing` — spread volume evenly across the campaign window (`drip_delivery: true`)
  - `:throttle` — cap sends per target per hour (`drip_delivery: false`)
  """
  def delivery_mode(%__MODULE__{drip_delivery: true}), do: :pacing
  def delivery_mode(%__MODULE__{drip_delivery: false}), do: :throttle
  def delivery_mode(true), do: :pacing
  def delivery_mode(false), do: :throttle
  def delivery_mode(nil), do: nil
  def delivery_mode(_), do: nil

  def changeset(mtt, attrs) do
    assocs = Map.take(attrs, [:campaign])
    attrs = normalize_delivery_mode_attrs(attrs)

    mtt
    |> cast(attrs, [
      :start_at,
      :end_at,
      :stats,
      :message_template,
      :test_email,
      :cc_contacts,
      :cc_sender,
      :max_emails_per_hour,
      :timezone,
      :drip_delivery
    ])
    |> change(assocs)
    |> validate_required([:start_at, :end_at])
    |> validate_after(:start_at, :end_at)
    |> Proca.Contact.Input.validate_email(:test_email)
    |> Proca.Service.EmailTemplate.validate_exists(:message_template)
    |> validate_inclusion(:timezone, Tzdata.zone_list())
  end

  # GraphQL pacingDelivery maps onto the drip_delivery column.
  defp normalize_delivery_mode_attrs(attrs) when is_map(attrs) do
    {pacing, attrs} = Map.pop(attrs, :pacing_delivery)

    if is_nil(pacing) do
      attrs
    else
      Map.put(attrs, :drip_delivery, pacing)
    end
  end

  defp normalize_delivery_mode_attrs(attrs), do: attrs
end
