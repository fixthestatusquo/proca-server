defmodule Proca.Repo.Migrations.AddPartialProcessingStatusIndexToActions do
  use Ecto.Migration

  def change do
    create_if_not_exists index(
                           :actions,
                           [:supporter_id, :action_page_id, :campaign_id],
                           where: "processing_status IN (3, 4)",
                           name: :actions_partial_processing_status_index
                         )
  end
end
