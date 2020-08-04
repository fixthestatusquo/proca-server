defmodule Proca.StoryFactory do
  alias Proca.Factory

  @moduledoc """
  This module contains setups for different stories / use cases.

  # Single organisation campaigns
  Deep Blue fights to save the oceans and marine life. They run campaigns on their website and microsites.
  It runs a campaign on whales, and has one action page on their website, https://blue.org

  use with: `import Proca.StoryFactory, only: [blue_story: 0]`
  """

  @blue_website "https://blue.org"
  def blue_story() do
    blue_org = Factory.insert(:org, name: "blue")
    camp = Factory.insert(:campaign, name: "whales", title: "Save the whales!", org: blue_org)
    ap = Factory.insert(:action_page, campaign: camp, org: blue_org, url: @blue_website <> "/whales_now")

    %{
      org: blue_org,
      pages: [ap]
    }
  end

  @api_perms Proca.Staffer.Permission.add(0, [:use_api, :manage_campaigns, :manage_action_pages])

  @red_website "https://red.org"
  @yellow_website "https://yellow.org"
  def red_story() do
    red_org = Factory.insert(:org, name: "red")
    red_camp = Factory.insert(:campaign, name: "blood-donors", title: "Donate blood", org: red_org)
    red_ap = Factory.insert(:action_page, campaign: red_camp, org: red_org, url: @red_website <> "/sign")

    yellow_org = Factory.insert(:org, name: "yellow")
    yellow_camp = Factory.insert(:campaign, name: "blood-donors", title: "Donate blood", org: yellow_org)
    yellow_ap = Factory.insert(:action_page, campaign: yellow_camp, org: yellow_org, url: @yellow_website <> "/sign")

    red_bot = Factory.insert(:staffer, org: red_org, perms: @api_perms)

    %{
      red_org: red_org, yellow_org: yellow_org,
      red_campaign: red_camp, yellow_camp: yellow_camp,
      red_ap: red_ap, yellow_ap: yellow_ap,
      red_bot: red_bot
    }

  end
end
