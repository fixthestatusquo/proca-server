defmodule Proca.Factory do
  @moduledoc """
  Main schema Factory for tests
  """
  use ExMachina.Ecto, repo: Proca.Repo
  alias Proca.Factory

  def org_factory do
    org_name = sequence("org")
    email_service = build(:email_backend)

    %Proca.Org{
      name: org_name,
      title: "Org with name #{org_name}",
      services: [email_service],
      email_backend_id: email_service.id
    }
  end

  def email_backend_factory do
    %Proca.Service{
      name: :testmail,
      host: "email.host.com",
      user: "user",
      password: "Shebang123#!"
    }
  end

  def public_key_factory(attrs = %{org: org}) do
    name = sequence("public_key")

    Proca.PublicKey.build_for(org, name)
    |> Ecto.Changeset.change(Map.delete(attrs, :org))
    |> Ecto.Changeset.apply_changes()
  end

  def campaign_factory(attrs) do
    name = sequence("petition")
    title = sequence("petition", &"Petition about Foo (#{&1})")

    %Proca.Campaign{
      name: name,
      title: title,
      org: Map.get(attrs, :org) || insert(:org),
      force_delivery: false
    }
    |> merge_attributes(attrs)
    |> evaluate_lazy_attributes()
  end

  def action_page_factory(attrs) do
    campaign = Map.get(attrs, :campaign) || build(:campaign)
    org = Map.get(attrs, :org, campaign.org)

    %Proca.ActionPage{
      name: sequence("action_page", &"some.url.com/sign/#{&1}"),
      org: org,
      campaign: campaign,
      locale: "en",
      delivery: false,
      live: true,
      config: %{"journey" => ["Petition", "Share"]}
    }
    |> merge_attributes(attrs)
    |> evaluate_lazy_attributes()
  end

  def user_factory do
    email = sequence("email", &"member-#{&1}@example.org")

    %Proca.Users.User{
      email: email,
      hashed_password: Bcrypt.hash_pwd_salt(password_from_email(email))
    }
  end

  def password_from_email(email), do: email <> "A1%"

  def staffer_factory do
    %Proca.Staffer{
      user: build(:user),
      org: build(:org),
      perms: 0
    }
  end

  def basic_data_pl_factory do
    %Proca.Contact.BasicData{
      first_name: sequence("first_name", &"#{<<?A + rem(&1, 26)::utf8>>}aniel"),
      last_name: sequence("last_name", &"#{<<?A + rem(&1, 26)::utf8>>}ikiski"),
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
    |> Ecto.Changeset.apply_changes()
  end

  def basic_data_pl_supporter_factory(attrs) do
    action_page = Map.get(attrs, :action_page) || build(:action_page)
    data = Map.get(attrs, :data) || build(:basic_data_pl)

    Proca.Supporter.new_supporter(data, action_page)
    |> Ecto.Changeset.apply_changes()
    |> merge_attributes(attrs)
    |> evaluate_lazy_attributes()
  end

  @spec basic_data_pl_supporter_with_contact_factory(map) :: map
  def basic_data_pl_supporter_with_contact_factory(attrs) do
    action_page = Map.get(attrs, :action_page) || build(:action_page)
    data = Map.get(attrs, :data) || build(:basic_data_pl)

    contact = Proca.Contact.Data.to_contact(data, action_page)

    Proca.Supporter.new_supporter(data, action_page)
    |> Proca.Supporter.add_contacts(contact, action_page, %Proca.Supporter.Privacy{opt_in: true})
    |> Ecto.Changeset.apply_changes()
    |> merge_attributes(attrs)
    |> evaluate_lazy_attributes()
  end

  def contact_factory do
    {:ok, payload} =
      %{
        first_name: "John",
        last_name: "Brown",
        email: "john.brown@gmail.com",
        country: "GB",
        postcode: "012345"
      }
      |> JSON.encode()

    %Proca.Contact{
      payload: payload
    }
  end

  def supporter_factory(attrs) do
    ap = Map.get(attrs, :action_page, build(:action_page))

    %Proca.Supporter{
      first_name: sequence("first_name"),
      email: sequence("email", &"member-#{&1}@example.org"),
      fingerprint: sequence("fingerprint"),
      action_page: ap,
      campaign: Map.get(attrs, :campaign, ap.campaign)
    }
  end

  def action_factory(attrs) do
    # NOTE: insert(:action_page) here so AP is reused in both action and supporter
    # if I used build it would try to insert both (copies) of AP and result in name conflict

    {sup_ps, attrs} = Map.pop(attrs, :supporter_processing_status, :new)

    s =
      Map.get(attrs, :supporter) ||
        build(:basic_data_pl_supporter_with_contact, %{
          action_page: Map.get(attrs, :action_page) || insert(:action_page),
          processing_status: sup_ps
        })

    %Proca.Action{
      action_type: "register",
      action_page: s.action_page,
      campaign: s.action_page.campaign,
      supporter: s,
      with_consent: true
    }
    |> merge_attributes(attrs)
    |> evaluate_lazy_attributes()
  end

  def source_factory(attrs) do
    %Proca.Source{
      source: "unknown",
      medium: "unknown",
      campaign: "unknown",
      location: "https://proca.app"
    }
    |> merge_attributes(attrs)
    |> evaluate_lazy_attributes()
  end

  def target_factory(attrs) do
    emails = [
      %Proca.TargetEmail{
        email: sequence("email", &"member-#{&1}@example.org")
      }
    ]

    %Proca.Target{
      external_id: sequence("external_id"),
      name: sequence("name"),
      emails: emails
    }
    |> merge_attributes(attrs)
    |> evaluate_lazy_attributes()
  end

  def message_factory(attrs) do
    %Proca.Action.Message{
      message_content: Map.get(attrs, :message_content, build(:message_content)),
      action: Map.get(attrs, :action, build(:action))
    }
    |> merge_attributes(attrs)
    |> evaluate_lazy_attributes()
  end

  def message_content_factory do
    %Proca.Action.MessageContent{
      subject: sequence("MTT Subject to {{target.name}}"),
      body: sequence("MTT text body to {{target.name}}")
    }
  end

  def mtt_factory do
    %Proca.MTT{
      start_at: DateTime.utc_now(),
      end_at: DateTime.utc_now() |> DateTime.add(600, :second)
    }
  end
end
