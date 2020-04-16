defmodule Proca.Factory do
  use ExMachina.Ecto, repo: Proca.Repo

  def org_factory do
    org_name = sequence("org")
    %Proca.Org{
      name: org_name,
      title: "Org with name #{org_name}"
    }
  end


  def campaign_factory do
    name = sequence("petition")
    title = sequence("petition", &"Petition about Foo (#{&1})")

    %Proca.Campaign{
      name: name,
      title: title,
      org: build(:org)
    }
  end
 
  def action_page_factory do
    %Proca.ActionPage{
      url: sequence("https://some.url.com/sign"),
      org: build(:org),
      campaign: build(:campaign)
    }
  end

end
