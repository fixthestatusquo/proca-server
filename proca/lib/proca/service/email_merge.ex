defmodule Proca.Service.EmailMerge do
  @defmodule """
  Logic needed to do personalization / merge tags in Proca email system (to supporter, to target).

  Partially replace the EmailRecipient logic

  ## Variables exposed to template

  - firstName - first name of supporter
  - ref - reference to supporter
  - org.name
  - org.title
  - campaign.name
  - campaign.title
  - actionPage.name
  - actionPage.locale
  - actionId
  - tracking.campaign - the utm_campaign of action
  - tracking.medium - the utm_medium
  - tracking.source - the utm_source
  - custom fields - custom fields (camel cased!)
  """

  alias Swoosh.Email
  import Swoosh.Email, only: [assign: 3]

  alias Proca.{Action, Supporter, ActionPage, Campaign, Org, Target}

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

  def put_org(%Email{} = email, %Org{name: n, title: t, config: c}) do
    email
    |> assign(:org, %{name: n, title: t, config: c})
  end

  def put_org(e, _), do: e

  def put_action_page(%Email{} = email, %ActionPage{id: id, name: n, locale: l, org: org}) do
    email
    |> assign(:action_page, %{name: n, locale: l, id: id})
    |> put_org(org)
  end

  def put_action_page(e, _), do: e

  def put_target(%Email{} = email, %Target{} = target) do
    email
    |> assign(:target, Map.take(target, [:name, :external_id, :area, :locale, :fields]))
  end

  def put_action_message(%Email{} = email, action_data = %{"schema" => "proca:action:1"}) do
    fields = remove_nil_values(get_in(action_data, ["action", "fields"]) || %{})

    %{email | assigns: Map.merge(fields, email.assigns)}
    |> assign(:ref, get_in(action_data, ["contact", "ref"]))
    |> put_action_message_common(action_data)
  end

  def put_action_message(%Email{} = email, action_data = %{"schema" => "proca:action:2"}) do
    fields = remove_nil_values(get_in(action_data, ["action", "customFields"]) || %{})

    %{email | assigns: Map.merge(fields, email.assigns)}
    |> assign(:ref, get_in(action_data, ["contact", "contactRef"]))
    |> put_action_message_common(action_data)
  end

  defp put_action_message_common(%Email{} = email, action_data) do
    email
    |> put_assigns(%{
      first_name: get_in(action_data, ["contact", "firstName"]),
      email: get_in(action_data, ["contact", "email"]),
      org: %{
        name: get_in(action_data, ["org", "name"]),
        title: get_in(action_data, ["org", "title"])
      },
      campaign: %{
        name: get_in(action_data, ["campaign", "name"]),
        title: get_in(action_data, ["campaign", "title"])
      },
      action_page: %{
        name: get_in(action_data, ["actionPage", "name"]),
        locale: get_in(action_data, ["actionPage", "locale"])
      },
      action_id: get_in(action_data, ["actionId"]),
      tracking: get_in(action_data, ["tracking"]) |> also_encode("location"),
      privacy: get_in(action_data, ["privacy"])
    })
  end

  defp remove_nil_values(fields) do
    fields
    |> Enum.reject(fn {_, v} -> is_nil(v) end)
    |> Map.new()
  end

  def put_assigns(eml = %Email{assigns: fields}, fields2) when is_map(fields2) do
    %{eml | assigns: Map.merge(fields, fields2)}
  end

  def put_assigns(eml, []), do: eml

  def put_assigns(eml = %Email{assigns: fields}, [{key, val} | rest]) do
    %{eml | assigns: Map.put(fields, Atom.to_string(key), val)}
    |> put_assigns(rest)
  end

  def plain_to_html(text) do
    "<p>" <> String.replace(text, "\n", "</p><p>") <> "</p>"
  end

  def also_encode(nil, _), do: nil

  def also_encode(map, key) when is_bitstring(key) or is_atom(key) do
    key2 = "encoded_" <> if is_atom(key), do: Atom.to_string(key), else: key

    case Map.get(map, key, nil) do
      nil ->
        map

      val when is_bitstring(val) ->
        Map.put(map, key2, URI.encode(val, &URI.char_unreserved?/1))
    end
  end
end
