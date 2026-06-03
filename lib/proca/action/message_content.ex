defmodule Proca.Action.MessageContent do
  use Ecto.Schema
  use Proca.Schema, module: __MODULE__
  import Ecto.Changeset
  alias __MODULE__
  alias Proca.Service.EmailTemplate

  schema "message_contents" do
    field :subject, :string, default: ""
    field :body, :string, default: ""
    field :compiled, :map, virtual: true

    has_many :messages, Proca.Action.Message
  end

  def changeset(params), do: changeset(%MessageContent{}, params)

  def changeset(ch, params) do
    cast(ch, params, [:subject, :body])
    # https://stackoverflow.com/questions/1592291/what-is-the-email-subject-length-limit
    |> validate_length(:subject, max: 5 * 256)
    |> validate_length(:body, max: 10 * 1024)
    |> fix_subject()
    |> EmailTemplate.validate_template(:subject)
    |> EmailTemplate.validate_template(:body)
  end

  def compile(%MessageContent{subject: subject, body: body} = mc) do
    %{mc | compiled: %{
      subject: EmailTemplate.compile_string(subject),
      body: EmailTemplate.compile_string(body)
    }}
  end

  def fix_subject(chset = %{changes: %{subject: s}, valid?: true}) when is_bitstring(s) do
    s =
      s
      |> String.replace(~r/\n+/, " ")

    change(chset, subject: s)
  end

  def fix_subject(ch), do: ch
end
