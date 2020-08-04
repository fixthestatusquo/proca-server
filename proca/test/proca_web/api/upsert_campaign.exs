defmodule ProcaWeb.UpsertCampaign do
  use ProcaWeb.ConnCase
  import Proca.StoryFactory, only: [blue_story: 0]

  describe "upsert_campaign API" do
    setup do
      blue_story()
    end


  end

end
