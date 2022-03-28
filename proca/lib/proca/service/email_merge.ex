defmodule Proca.Service.EmailMerge do
  @defmodule """
  Logic needed to do personalization / merge tags in Proca email system (to supporter, to target).

  Partially replace the EmailRecipient logic

  ## Variables exposed to template

  - firstName - first name of supporter
  - ref - reference to supporter
  - orgName
  - orgTitle
  - campaignName
  - campaignTitle
  - actionPageName
  - actionPageLocale
  - actionId
  - trackingCampaign - the utm_campaign of action
  - trackingMedium - the utm_medium
  - trackingSource - the utm_source
  - custom fields - custom fields (camel cased!)
  """

  alias Swoosh.Email
  import Swoosh.Email, only: [assign: 3]

  alias Proca.{Action, Supporter, ActionPage, Campaign, Org}

  # action = Repo.preload(action, [:supporter, action_page: :org, campaign: :org])

  def put_action(%Swoosh.Email{} = email, %Action{
        id: id,
        supporter: supporter,
        campaign: campaign,
        action_page: ap
      }) do
    email
    |> assign(:action_id, id)
    |> put_supporter(supporter)
    |> put_campaign(campaign)
    |> put_action_page(ap)
  end

  def put_supporter(%Email{} = email, %Supporter{first_name: f, last_name: l, email: e}) do
    email
    |> assign(:first_name, f)
    |> assign(:last_name, l)
    |> assign(:email, e)
  end

  def put_supporter(email, _), do: email

  def put_campaign(%Email{} = email, %Campaign{name: n, title: t}) do
    email
    |> assign(:campaign, %{name: n, title: t})
  end

  def put_campaign(email, _), do: email

  def put_org(%Email{} = email, %Org{name: n, title: t}) do
    email
    |> assign(:org, %{name: n, title: t})
  end

  def put_org(e, _), do: e

  def put_action_page(%Email{} = email, %ActionPage{name: n, locale: l, org: org}) do
    email
    |> assign(:action_page, %{name: n, locale: l})
    |> put_org(org)
  end

  def put_action_page(e, _), do: e

  ## XXX implement put_action_data for %{"schema" => "proca:action:2"} ... to replace EmailRecipient.from_action_data
  def plain_to_html(text) do
    "<p>" <> String.replace(text, "\n", "</p><p>") <> "</p>"
  end
end
