defmodule Proca.Repo.Migrations.MakeSupportrsAreaLength32 do
  use Ecto.Migration

  def down, do: nil

  def up do
    alter table(:supporters) do 
      modify :area, :string, size: 32, null: true
    end
  end
end
