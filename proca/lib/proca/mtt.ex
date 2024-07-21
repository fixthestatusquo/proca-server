defmodule Proca.MTT do
  use Ecto.Schema
  use Proca.Schema, module: __MODULE__
  import Ecto.Changeset
  import Proca.Validations

  schema "mtt" do
    field :start_at, :utc_datetime
    field :end_at, :utc_datetime
    #   field :sending_rate, :integer
    field :stats, :map, default: %{}
    field :test_email, :string

    # TODO:
    # field :distributed, :boolean, default: false
    # # if distributed, each AP has a template, and each partner sends via their mail system
    # field :spoof_username, :boolean, default: true

    # maybe an ap override is necessary
    # optional! must support also sending without it.
    field :message_template, :string

    belongs_to :campaign, Proca.Campaign
  end

  def changeset(mtt, attrs) do
    assocs = Map.take(attrs, [:campaign])

    mtt
    |> cast(attrs, [:start_at, :end_at, :stats, :message_template, :test_email])
    |> change(assocs)
    |> validate_required([:start_at, :end_at])
    |> validate_after(:start_at, :end_at)
    |> Proca.Contact.Input.validate_email(:test_email)
    |> Proca.Service.EmailTemplate.validate_exists(:message_template)
  end
end
