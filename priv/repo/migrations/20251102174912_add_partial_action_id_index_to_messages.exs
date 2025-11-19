defmodule Proca.Repo.Migrations.AddPartialActionIdIndexToMessages do
  use Ecto.Migration

  def change do
    create_if_not_exists index(
                           :messages,
                           [:action_id],
                           name: :messages_partial_action_index
                         )
  end
end
