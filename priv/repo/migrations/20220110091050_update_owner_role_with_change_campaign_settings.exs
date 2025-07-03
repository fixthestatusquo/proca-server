defmodule Proca.Repo.Migrations.UpdateOwnerRoleWithChangeCampaignSettings do
  use Ecto.Migration

  def up do
    owner2 = Proca.Permission.add(0, Proca.Staffer.Role.permissions(:owner))
    owner1 = Proca.Permission.remove(owner2, :change_campaign_settings)
    bit = Proca.Permission.add(0, :change_campaign_settings)

    execute """
    update staffers
    set perms = perms | #{bit}
    where perms & #{owner1} > 0
    """
  end

  def down do
    bit = Proca.Permission.add(0, :change_campaign_settings)

    execute """
    update staffers set perms = perms & ~#{bit}
    """
  end
end
