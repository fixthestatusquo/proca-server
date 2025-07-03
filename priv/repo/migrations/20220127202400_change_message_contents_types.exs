defmodule Proca.Repo.Migrations.ChangeMessageContentsTypes do
  use Ecto.Migration

  def change do
    alter table(:message_contents) do
      modify :subject, :text, null: false, default: ""
      modify :body, :text, null: false, default: ""
    end
  end
end
