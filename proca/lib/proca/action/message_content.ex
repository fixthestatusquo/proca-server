defmodule Proca.Action.MessageContent do
  use Ecto.Schema
  use Proca.Schema, module: __MODULE__
  import Ecto.Changeset

  schema "message_contents" do
    field :subject, :string, default: ""
    field :body, :string, default: ""

    has_many :messages, Proca.Action.Message
  end

  def changeset(ch, params) do
    cast(ch, params, [:subject, :body])
    # https://stackoverflow.com/questions/1592291/what-is-the-email-subject-length-limit
    |> validate_length(:subject, max: 100)
    |> validate_length(:body, max: 4 * 1024)
  end
end
