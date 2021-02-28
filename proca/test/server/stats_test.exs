defmodule Proca.Server.StatsTest do 
  use Proca.DataCase
  doctest Proca.Server.Stats

  import Proca.StoryFactory, only: [red_story: 0]
  import Proca.Factory
  alias Proca.Server.Stats
  alias Proca.{Repo,Action,Supporter}

  import Ecto.Query


  setup do 
    red_story
  end

  test "Signed second campaign with just action", %{
    red_ap: ap1, red_campaign: c1,  yellow_ap: ap2, yellow_campaign: c2
  } do 
      aa = %{
        action_type: "sign",
        processing_status: :accepted,
      }
      act1 = insert(:action, %{
        action_page: ap1,
        supporter: build(:basic_data_pl_supporter_with_contact, %{
            action_page: ap1,
            campaign: ap1.campaign,
            processing_status: :accepted
          })
        } |>Map.merge(aa))

      act2 = insert(:action, %{
        action_page: ap2, 
        campaign: ap2.campaign,
        supporter: act1.supporter
        } |> Map.merge(aa)) 
      
      # IO.inspect(Repo.all(from(a in Action, preload: [:supporter])))
      st = Stats.calculate() 

  # IO.inspect(st, label: "AAA")
    
  end
  

end 
