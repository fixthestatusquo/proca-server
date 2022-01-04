defmodule Proca.Repo.Migrations.CreateMessages do
  use Ecto.Migration

  def change do
    create table(:message_contents) do
      add :subject, :string, null: false, default: ""
      add :body, :string, null: false, default: ""
    end

    create table(:messages) do
      add :action_id, references(:actions, on_delete: :delete_all), null: false
      add :message_content_id, references(:message_contents, on_delete: :delete_all), null: false
      add :target_id, references(:targets, type: :uuid, on_delete: :delete_all), null: false
      add :delivered, :boolean, default: false, null: false
    end
  end
end
