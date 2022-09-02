defmodule Proca.Action.MessageContent do
  use Ecto.Schema
  use Proca.Schema, module: __MODULE__
  import Ecto.Changeset
  alias __MODULE__

  schema "message_contents" do
    field :subject, :string, default: ""
    field :body, :string, default: ""

    has_many :messages, Proca.Action.Message
  end

  def changeset(params), do: changeset(%MessageContent{}, params)

  def changeset(ch, params) do
    cast(ch, params, [:subject, :body])
    # https://stackoverflow.com/questions/1592291/what-is-the-email-subject-length-limit
    |> validate_length(:subject, max: 255)
    |> validate_length(:body, max: 10 * 1024)
    |> validate_required([:subject, :body])
  end
end
