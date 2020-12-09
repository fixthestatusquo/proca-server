defmodule Proca.StoryFactory do
  alias Proca.Factory

  @moduledoc """
  This module contains setups for different stories / use cases.

  # Single organisation campaigns
  Deep Blue fights to save the oceans and marine life. They run campaigns on their website and microsites.
  It runs a campaign on whales, and has one action page on their website, https://blue.org

  use with: `import Proca.StoryFactory, only: [blue_story: 0]`
  """

  @blue_website "blue.org"
  def blue_story() do
    blue_org = Factory.insert(:org, name: "blue")
    camp = Factory.insert(:campaign, name: "whales", title: "Save the whales!", org: blue_org)
    ap = Factory.insert(:action_page, campaign: camp, org: blue_org, name: @blue_website <> "/whales_now")

    %{
      org: blue_org,
      pages: [ap]
    }
  end

  @api_perms Proca.Staffer.Permission.add(0, [:use_api, :manage_campaigns, :manage_action_pages])

  @red_website "red.org"
  @yellow_website "yellow.org"
  def red_story() do
    red_org = Factory.insert(:org, name: "red")
    red_camp = Factory.insert(:campaign, name: "blood-donors", title: "Donate blood", org: red_org)
    red_ap = Factory.insert(:action_page, campaign: red_camp, org: red_org, name: @red_website <> "/sign")

    yellow_org = Factory.insert(:org, name: "yellow")
    yellow_camp = Factory.insert(:campaign, name: "blood-donors", title: "Donate blood", org: yellow_org)
    yellow_ap = Factory.insert(:action_page, campaign: yellow_camp, org: yellow_org, name: @yellow_website <> "/sign")

    red_bot = Factory.insert(:staffer, org: red_org, perms: @api_perms)

    orange_ap1 = Factory.insert(:action_page, campaign: yellow_camp, org: red_org, name: @red_website <> "/we-walk-with-yellow")
    orange_ap2 = Factory.insert(:action_page, campaign: yellow_camp, org: red_org, name: @red_website <> "/we-donate-with-yellow")

    %{
      red_org: red_org,       yellow_org: yellow_org,
      red_campaign: red_camp, yellow_campaign: yellow_camp,
      red_ap: red_ap,         yellow_ap: yellow_ap,
      orange_aps: [orange_ap1, orange_ap2],
      red_bot: red_bot
    }

  end

  def eci_story() do
    org = Factory.insert(:org, name: "runner", title: "ECI runner", contact_schema: :eci)
    camp = Factory.insert(:campaign, name: "the-eci", title: "ECI", org: org)
    ap = Factory.insert(:action_page, campaign: camp, org: org, name: "eci.eu/pl", locale: "pl")

    %{
      org: org,
      campaign: camp,
      pages: [ap]
    }
  end

end
