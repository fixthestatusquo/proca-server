defmodule Proca.Repo.Migrations.ChangeSqsToPushBackend do
  use Ecto.Migration

  def up do
    alter table(:orgs) do
      add :push_backend_id, references(:services, on_delete: :nilify_all), null: true
    end

    set_push_backend = """
    update orgs
    SET push_backend_id = (select id from services where org_id = orgs.id and name = 'sqs')
    where orgs.system_sqs_deliver
    """

    execute set_push_backend

    alter table(:orgs) do
      remove :system_sqs_deliver
      remove :event_processing
    end
  end

  def down do
    alter table(:orgs) do
      add :system_sqs_deliver, :boolean, null: false, default: false
      add :event_processing, :boolean, null: false, default: false
    end

    set_sqs_flag = """
    update orgs
    SET system_sqs_deliver = push_backend_id is not null
    """

    execute set_sqs_flag

    alter table(:orgs) do
      remove :push_backend_id
    end
  end
end
