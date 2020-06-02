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

  def user_factory do
    %Proca.Users.User{
      email: sequence("email", &"member-#{&1}@example.org"),
      password_hash: sequence("password") |>  Pow.Ecto.Schema.Password.pbkdf2_hash(iterations: 1)
    }
  end

  def staffer_factory do
    %Proca.Staffer{
      user: build(:user),
      org: build(:org),
      perms: 0
    }
  end


  def contact_factory do
    {:ok, payload} = %{
      first_name: "John", last_name: "Brown", email: "john.brown@gmail.com",
      country: "GB", postcode: "012345"
    } |> JSON.encode()

    %Proca.Contact{
      payload: payload
    }
  end
end
