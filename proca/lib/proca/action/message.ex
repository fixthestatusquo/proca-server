defmodule Proca.Action.Message do
  use Ecto.Schema
  use Proca.Schema, module: __MODULE__
  import Ecto.Changeset

  schema "messages" do
    field :delivered, :boolean, default: false
    belongs_to :action, Proca.Action
    belongs_to :target, Proca.Target, type: Ecto.UUID
    has_one :message_content, Proca.Action.MessageContent
  end
end
