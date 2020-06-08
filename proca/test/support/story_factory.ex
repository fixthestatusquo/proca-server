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
    blueOrg = Factory.insert(:org, name: "blue")
    camp = Factory.insert(:campaign, name: "whales", title: "Save the whales!", org: blueOrg)
    ap = Factory.insert(:action_page, campaign: camp, org: blueOrg, url: @blue_website <> "/whales_now")

    %{
      org: blueOrg,
      pages: [ap]
    }
  end
end
