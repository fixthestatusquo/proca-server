defmodule Proca.Repo.Migrations.AllowNullSupporterConfirmOnCampaigns do
  use Ecto.Migration

  def up do
    alter table(:campaigns) do
      modify :supporter_confirm, :boolean, default: nil, null: true
    end

    # Existing rows were all inserted with the old `default: false`, so a plain
    # `false` can't be told apart from "explicitly disabled". Reset to nil
    # (defer to org) so this migration doesn't retroactively force confirm off
    # for every campaign whose org has supporter_confirm enabled.
    execute "UPDATE campaigns SET supporter_confirm = NULL WHERE supporter_confirm = false"
  end

  def down do
    execute "UPDATE campaigns SET supporter_confirm = false WHERE supporter_confirm IS NULL"

    alter table(:campaigns) do
      modify :supporter_confirm, :boolean, default: false, null: false
    end
  end
end
