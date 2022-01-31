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

    belongs_to :action, Proca.Action
    belongs_to :target, Proca.Target, type: Ecto.UUID
    belongs_to :message_content, Proca.Action.MessageContent
  end

  def changeset(attrs), do: changeset(%Message{}, attrs)

  def changeset(msg, attrs) do
    assocs = Map.take(attrs, [:target, :message_content])

    msg
    |> cast(attrs, [
      :target_id,
      :action_id,
      :message_content_id,
      :sent,
      :delivered,
      :opened,
      :clicked
    ])
    |> foreign_key_constraint(:target, name: :messages_target_id_fkey, message: "has messages")
    |> change(assocs)
  end

  def put_messages(action, %{targets: targets} = attrs, %ActionPage{} = action_page) do
    # check if Campaign supports MTT
    if is_nil(action_page.campaign.mtt) do
      add_error(action, :mtt, "Campaign does not support MTT")
    else
      message_content = Action.MessageContent.changeset(%Action.MessageContent{}, attrs)

      messages =
        Enum.map(targets, fn t ->
          %{
            target_id: t,
            message_content: message_content
          }
        end)

      action
      |> cast(%{messages: messages}, [])
      |> cast_assoc(:messages)
    end
  end

  def put_messages(action, _, _), do: action

  @spec select_by_targets([number], boolean, boolean) :: %Ecto.Query{}
  def select_by_targets(target_ids, sent \\ false, testing \\ false) do
    import Ecto.Query

    sent = List.wrap(sent)

    action_status = if testing, do: :testing, else: :delivered

    from(m in Proca.Action.Message,
      join: t in Proca.Target,
      on: m.target_id == t.id,
      join: a in Proca.Action,
      on: m.action_id == a.id,
      where:
        a.processing_status == ^action_status and m.sent in ^sent and
          m.target_id in ^target_ids
    )
  end

  @spec mark_all([%Message{}], :sent | :delivered | :opened | :clicked) :: :ok
  def mark_all(messages, field) when field in [:sent, :delivered, :opened, :clicked] do
    import Ecto.Query
    ids = Enum.map(messages, & &1.id)
    Repo.update_all(from(m in Message, where: m.id in ^ids), set: [{field, true}])
    :ok
  end
end
