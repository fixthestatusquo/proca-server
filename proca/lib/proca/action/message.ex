defmodule Proca.Action.Message do
  use Ecto.Schema
  use Proca.Schema, module: __MODULE__
  import Ecto.Changeset

  alias Proca.{ActionPage, Action}
  alias __MODULE__

  schema "messages" do
    field :sent, :boolean, default: false
    field :delivered, :boolean, default: false
    field :opened, :boolean, default: false
    field :clicked, :boolean, default: false
    field :dupe_rank, :integer

    # files in storage service
    field :files, {:array, :string}, default: []

    belongs_to :action, Proca.Action
    belongs_to :target, Proca.Target, type: Ecto.UUID
    belongs_to :message_content, Proca.Action.MessageContent

    # inserted_at is same as actions, but updated_at is useful to see when flags changed
    timestamps(inserted_at: false)
  end

  def changeset(attrs), do: changeset(%Message{}, attrs)

  def changeset(msg, attrs) do
    assocs = Map.take(attrs, [:target, :message_content])

    # The foreigh constraing below is there to prevent deleting target with waiting messages.
    msg
    |> cast(attrs, [
      :target_id,
      :action_id,
      :message_content_id,
      :sent,
      :delivered,
      :opened,
      :clicked,
      :files
    ])
    |> change(assocs)
    |> validate_format_many(:files, ~r/^[-0-9a-zA-Z!_.*'()'\/]+$/)
    |> foreign_key_constraint(:target,
      name: :messages_target_id_fkey,
      message: "target to messages association violated"
    )
  end

  def put_messages(action, %{targets: targets} = attrs, %ActionPage{} = action_page) do
    # check if Campaign supports MTT
    if is_nil(action_page.campaign.mtt) do
      add_error(action, :mtt, "Campaign does not support MTT")
    else
      {_, message_content} =
        Proca.Repo.insert(Action.MessageContent.changeset(%Action.MessageContent{}, attrs))

      # which ever we have - failed changeset or good record, lets just add it once

      messages =
        Enum.map(targets, fn t ->
          %{
            target_id: t,
            message_content: message_content,
            files: Map.get(attrs, :files, [])
          }
        end)

      action
      |> cast(%{messages: messages}, [])
      |> cast_assoc(:messages)
    end
  end

  def put_messages(action, _, _), do: action

  @doc """
  Returns a query for [message, target, action] for specified target id list, or :all for all.
  Use sent and testing flags to further select (not) sent or (not) testing actions
  """
  @spec select_by_targets([number] | :all, boolean, boolean) :: %Ecto.Query{}
  def select_by_targets(target_ids, sent \\ false, testing \\ false) do
    import Ecto.Query

    sent = List.wrap(sent)

    q =
      from(m in Proca.Action.Message,
        join: t in Proca.Target,
        on: m.target_id == t.id,
        join: a in Proca.Action,
        on: m.action_id == a.id,
        # processed
        # and testing status we want
        # and with that sent status
        # and either testing or only non-dupe if not testing
        where:
          a.processing_status == :delivered and
            a.testing == ^testing and
            m.sent in ^sent and
            (a.testing == true or m.dupe_rank == 0)
      )

    case target_ids do
      :all ->
        q

      target_ids ->
        where(q, [m, t, a], m.target_id in ^target_ids)
    end
  end

  @spec mark_all([%Message{}], :sent | :delivered | :opened | :clicked) :: :ok
  def mark_all(messages, field) when field in [:sent, :delivered, :opened, :clicked] do
    import Ecto.Query
    ids = Enum.map(messages, & &1.id)

    Repo.update_all(from(m in Message, where: m.id in ^ids),
      set: [{field, true}, {:updated_at, NaiveDateTime.utc_now()}]
    )

    :ok
  end

  def handle_event(event) do
    message = Repo.get_by(Message, id: event.id)
    ## If message found in DB
    if message do
      case event.reason do
        :sent ->
          Repo.update!(change(message, delivered: true))

        :open ->
          Repo.update!(change(message, opened: true, delivered: true))

        :click ->
          Repo.update!(change(message, clicked: true, opened: true, delivered: true))
      end
    end
  end

  def validate_format_many(changeset, field, format) do
    case get_change(changeset, field) do
      vals when is_list(vals) ->
        Enum.reduce(
          Enum.with_index(vals),
          changeset,
          fn {v, i}, ch ->
            validate_change(ch, field, {:format, format}, fn _, _ ->
              if v =~ format,
                do: [],
                else: [{field, {"files.#{i} has invalid format", [validation: :format]}}]
            end)
          end
        )

      _ ->
        changeset
    end
  end
end
