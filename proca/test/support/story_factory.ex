defmodule Proca.StoryFactory do
  alias Proca.Factory
  import ExMachina, only: [sequence: 1]

  @moduledoc """
  This module contains setups for different stories / use cases.

  # Single organisation campaigns
  Deep Blue fights to save the oceans and marine life. They run campaigns on their website and microsites.
  It runs a campaign on whales, and has one action page on their website, https://blue.org

  use with: `import Proca.StoryFactory, only: [blue_story: 0]`
  """

  @blue_website "blue.org"
  def blue_story() do
    blue_org = Factory.insert(:org, name: sequence("blue_org"))

    camp =
      Factory.insert(:campaign,
        name: sequence("whales_campaign"),
        title: "Save the whales!",
        org: blue_org
      )

    ap =
      Factory.insert(:action_page,
        campaign: camp,
        org: blue_org,
        name: @blue_website <> "/whales_now"
      )

    %{
      org: blue_org,
      pages: [ap]
    }
  end

  @api_perms Proca.Permission.add([:manage_campaigns, :manage_action_pages])
  @owner_perms Proca.Permission.add(Proca.Staffer.Role.permissions(:owner))

  @red_website "red.org"
  @yellow_website "yellow.org"
  def red_story() do
    red_org = Factory.insert(:org, name: sequence("red_org"))

    red_camp =
      Factory.insert(:campaign,
        name: sequence("blood-donors"),
        title: "Donate blood",
        org: red_org
      )

    red_ap =
      Factory.insert(:action_page, campaign: red_camp, org: red_org, name: @red_website <> "/sign")

    yellow_org = Factory.insert(:org, name: "yellow")

    yellow_camp =
      Factory.insert(:campaign, name: sequence("free-beer"), title: "Donate beer", org: yellow_org)

    yellow_ap =
      Factory.insert(:action_page,
        campaign: yellow_camp,
        org: yellow_org,
        name: @yellow_website <> "/sign"
      )

    yellow_owner = Factory.insert(:staffer, org: yellow_org, perms: @owner_perms)
    red_owner = Factory.insert(:staffer, org: red_org, perms: @owner_perms)
    red_bot = Factory.insert(:staffer, org: red_org, perms: @api_perms)

    # red org joins yellows campaign
    orange_ap1 =
      Factory.insert(:action_page,
        campaign: yellow_camp,
        org: red_org,
        name: @red_website <> "/we-walk-with-yellow"
      )

    orange_ap2 =
      Factory.insert(:action_page,
        campaign: yellow_camp,
        org: red_org,
        name: @red_website <> "/we-donate-with-yellow"
      )

    %{
      red_org: red_org,
      yellow_org: yellow_org,
      red_campaign: red_camp,
      yellow_campaign: yellow_camp,
      red_ap: red_ap,
      yellow_ap: yellow_ap,
      orange_aps: [orange_ap1, orange_ap2],
      red_user: red_owner.user,
      yellow_user: yellow_owner.user,
      red_bot: red_bot,
      yellow_owner: yellow_owner,
      red_bot_user: red_bot.user,
      red_owner: red_owner
    }
  end

  def eci_story() do
    org = Factory.insert(:org, name: "runner", title: "ECI runner", contact_schema: :eci)

    camp =
      Factory.insert(:campaign, name: "the-eci", title: "ECI", org: org, contact_schema: :eci)

    ap = Factory.insert(:action_page, campaign: camp, org: org, name: "eci.eu/pl", locale: "pl")

    %{
      org: org,
      campaign: camp,
      pages: [ap]
    }
  end

  @doc """
  Green org is running a MTT campaign.
  """
  def green_story() do
    eml = Factory.build(:email_backend)

    org =
      Factory.build(:org, name: "panda", title: "The Green Panda", contact_schema: :basic)
      |> Proca.Org.changeset(%{email_backend: eml})
      |> Proca.Repo.insert!()

    campaign =
      Factory.insert(:campaign,
        org: org,
        name: "mtt",
        title: "Mail To Target",
        mtt: Factory.build(:mtt)
      )

    ap = Factory.insert(:action_page, org: org, campaign: campaign, name: "mtt/en", locale: "en")
    targets = Factory.insert_list(10, :target, campaign: campaign)

    %{
      org: org,
      campaign: campaign,
      ap: ap,
      targets: targets
    }
  end
end
