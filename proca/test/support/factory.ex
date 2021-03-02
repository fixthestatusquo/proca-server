defmodule Proca.Factory do
  @moduledoc """
  Main schema Factory for tests
  """
  use ExMachina.Ecto, repo: Proca.Repo
  alias Proca.Factory

  def org_factory do
    org_name = sequence("org")
    IO.inspect(org_name, label: "factory org")
    %Proca.Org{
      name: org_name,
      title: "Org with name #{org_name}"
    }
  end

  def public_key_factory(attrs = %{org: org}) do
    name = sequence("public_key")
    Proca.PublicKey.build_for(org, name)
    |> Ecto.Changeset.change(Map.delete(attrs, :org))
    |> Ecto.Changeset.apply_changes
  end

  def campaign_factory do
    name = sequence("petition")
    title = sequence("petition", &"Petition about Foo (#{&1})")

    %Proca.Campaign{
      name: name,
      title: title,
      org: build(:org),
      force_delivery: false
    }
  end
 
  def action_page_factory(attrs) do
    campaign = Map.get(attrs, :campaign, insert(:campaign))
    org = Map.get(attrs, :org, campaign.org)

    %Proca.ActionPage{
      name: sequence("some.url.com/sign"),
      org: org,
      locale: "en",
      campaign: campaign,
      delivery: false
    }
    |> merge_attributes(attrs) 
    |> evaluate_lazy_attributes()
  end

  def user_factory do
    email = sequence("email", &"member-#{&1}@example.org")
    %Proca.Users.User{
      email: email,
      password_hash: email |>  Pow.Ecto.Schema.Password.pbkdf2_hash(iterations: 1)
    }
  end

  def staffer_factory do
    %Proca.Staffer{
      user: build(:user),
      org: build(:org),
      perms: 0
    }
  end

  def basic_data_pl_factory do
    %Proca.Contact.BasicData{
      first_name: sequence("first_name"),
      last_name: sequence("last_name"),
      email: sequence("email", &"member-#{&1}@example.org"),
      phone: sequence("phone", ["+48123498213", "6051233412", "0048600919929"]),
      postcode: sequence("postcode", ["02-123", "03-999", "03-123", "33-123"]),
      country: "pl"
    }
  end

  def basic_data_pl_contact_factory(attrs) do
    action_page = Map.get(attrs, :action_page) || Factory.build(:action_page)

    data = Map.get(attrs, :data) || build(:basic_data_pl)

    Proca.Contact.Data.to_contact(data, action_page)
    |> Ecto.Changeset.apply_changes
  end

  def basic_data_pl_supporter_factory(attrs) do
    action_page = Map.get(attrs, :action_page) || Factory.build(:action_page)
    data = Map.get(attrs, :data) || build(:basic_data_pl)

    Proca.Supporter.new_supporter(data, action_page)
    |> Ecto.Changeset.apply_changes
  end

  def basic_data_pl_supporter_with_contact_factory(attrs) do
    action_page = Map.get(attrs, :action_page) || Factory.build(:action_page)
    data = Map.get(attrs, :data) || build(:basic_data_pl)

    contact = Proca.Contact.Data.to_contact(data, action_page)

    Proca.Supporter.new_supporter(data, action_page)
    |> Proca.Supporter.add_contacts(contact, action_page, %Proca.Supporter.Privacy{opt_in: true})
    |> Ecto.Changeset.apply_changes
    |> merge_attributes(attrs)
    |> evaluate_lazy_attributes()
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

  def supporter_factory do
    %Proca.Supporter{
      first_name: sequence("first_name"),
      email: sequence("email"),
      fingerprint: sequence("fingerprint")
    }
  end

  def action_factory(attrs) do
    s = build(:basic_data_pl_supporter_with_contact, %{
      action_page: Map.get(attrs, :action_page, build(:action_page)),
    })

    %Proca.Action{
      action_page: s.action_page,
      campaign: s.action_page.campaign,
      supporter: s
    }
    |> merge_attributes(attrs) 
    |> evaluate_lazy_attributes()

  end
end
