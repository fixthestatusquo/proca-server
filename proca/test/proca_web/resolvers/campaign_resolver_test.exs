defmodule ProcaWeb.CampaignResolverTest do
  use ProcaWeb.ConnCase

  import Proca.StoryFactory, only: [red_story: 0]
  import Proca.Repo 
  import Ecto.Query, only: [from: 2]

  alias Proca.{Repo, Action, Supporter}

  setup do
    red_story()
  end

end
