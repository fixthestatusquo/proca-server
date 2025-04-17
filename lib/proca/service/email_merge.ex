defmodule Proca.Service.EmailMerge do
  @moduledoc """
  Logic needed to do personalization / merge tags in Proca email system (to supporter, to target).

  Partially replace the EmailRecipient logic

  ## Variables exposed to template

  - `firstName` - first name of supporter
  - `ref` - reference to supporter
  - `org.name`
  - `org.title`
  - `campaign.name`
  - `campaign.title`
  - `camapign.stats.supporterCount` - total deduplicated supporter count
  - `campaign.stats.supporterCountByOrg` - deduplicated supporter count collected by current org
  - `campaign.stats.supporterCountByArea` - deduplicated supporter count collected in area of this supporter
  - `campaign.stats.actionCount.someActionType` - count of actions of type `someActionType`
  - `actionPage.name`
  - `actionPage.locale`
  - `actionId`
  - `tracking.campaign` - the utm_campaign of action
  - `tracking.medium` - the utm_medium
  - `tracking.source` - the utm_source
  - `isDupe` - true if supporter for this campaign is a duplicate.
  - `privacy.optIn`
  - custom fields - custom fields (camel cased!)
  """

  alias Swoosh.{Email, Attachment}
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
    |> put_action_page(ap)
    |> put_campaign(campaign)
  end

  def put_supporter(%Email{} = email, %Supporter{
        first_name: f,
        last_name: l,
        email: e,
        area: a,
        dupe_rank: dr
      }) do
    email
    |> assign_maybe(:first_name, f)
    |> assign_maybe(:last_name, l)
    |> assign(:email, e)
    |> assign_maybe(:area, a)
    |> assign(:is_dupe, (dr || 0) > 0)
  end

  def put_supporter(email, _), do: email

  @spec put_campaign(any, any) :: any
  def put_campaign(%Email{} = email, %Campaign{id: id, name: n, title: t}) do
    stats = Proca.Server.Stats.stats(id)

    email
    |> assign(:campaign, %{
      name: n,
      title: t,
      stats: %{
        supporterCount: stats.supporters,
        actionCount: stats.action,
        supporterCountByArea: Map.get(stats.area, email.assigns[:area], 0),
        supporterCountByOrg: Map.get(stats.org, email.assigns[:org][:id], 0)
      }
    })
  end

  def put_campaign(email, _), do: email

  def put_org(%Email{} = email, %Org{name: n, title: t, config: c, id: id}) do
    email
    |> assign(:org, %{name: n, title: t, config: c, id: id})
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
    |> assign(:is_dupe, (get_in(action_data, ["contact", "dupeRank"]) || 0) > 0)
  end

  defp put_action_message_common(%Email{} = email, action_data) do
    {:ok, created_at, _} = get_in(action_data, ["action", "createdAt"]) |> DateTime.from_iso8601()

    email
    |> put_assigns(%{
      first_name: get_in(action_data, ["contact", "firstName"]),
      last_name: get_in(action_data, ["contact", "lastName"]) || "",
      email: get_in(action_data, ["contact", "email"]),
      org: %{
        name: get_in(action_data, ["org", "name"]),
        title: get_in(action_data, ["org", "title"])
      },
      campaign:
        %{
          name: get_in(action_data, ["campaign", "name"]),
          title: get_in(action_data, ["campaign", "title"])
        }
        |> Map.put(
          :stats,
          campaign_stats(
            action_data["campaignId"],
            action_data["orgId"],
            get_in(action_data, ["contact", "area"])
          )
        ),
      action_page: %{
        name: get_in(action_data, ["actionPage", "name"]),
        locale: get_in(action_data, ["actionPage", "locale"])
      },
      action_id: get_in(action_data, ["actionId"]),
      action_type: get_in(action_data, ["action", "actionType"]),
      created_at: DateTime.to_string(created_at),
      is_action_type: %{get_in(action_data, ["action", "actionType"]) => true},
      tracking: get_in(action_data, ["tracking"]) |> also_encode("location"),
      privacy: get_in(action_data, ["privacy"])
    })
  end

  def campaign_stats(campaign_id, org_id, area)
      when (is_nil(area) or is_bitstring(area)) and is_number(org_id) do
    %{supporters: sup, action: per_type, org: per_org, area: per_area} =
      Proca.Server.Stats.stats(campaign_id)

    %{
      supporter_count: sup,
      supporter_count_by_org: Map.get(per_org, org_id, 0),
      supporter_count_by_area: Map.get(per_area, area, 0),
      action_count: per_type
    }
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

  def put_files(eml = %Email{}, files) do
    Enum.reduce(Enum.with_index(files, 1), eml, fn {{filepath, data}, ordinal}, e ->
      mime_type =
        case Path.extname(filepath) do
          "." <> ext -> [content_type: "image/" <> String.downcase(ext)]
          _ -> []
        end

      filename = Path.basename(filepath)

      Email.attachment(
        e,
        Attachment.new(
          {:data, data},
          mime_type ++ [filename: filename, type: :inline, cid: "file#{ordinal}"]
        )
      )
      |> Email.assign(:files, Access.get(e.assigns, :files, []) ++ [filename])
    end)
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

  def assign_maybe(%Email{} = e, _key, nil), do: e
  def assign_maybe(%Email{} = e, key, value), do: assign(e, key, value)
end
