defmodule Proca.Stage.Support do
  alias Proca.{Action, Supporter, Org, PublicKey, Contact, Field}
  alias Proca.Repo
  import Ecto.Query, only: [from: 2]


  def bulk_actions_data(action_ids, stage \\ :deliver) do
    from(a in Action,
      where: a.id in ^action_ids,
      preload: [
        [supporter: [[contacts: [:public_key, :sign_key]], :consent]],
        :action_page, :campaign,
        :source,
        :fields
      ])
      |> Repo.all()
      |> Enum.map(fn a -> action_data(a, stage) end)
  end

  defp action_data_source(%Action{source: s}) when not is_nil(s) do
    %{
      source: s.source,
      mediunm: s.medium,
      campaign: s.campaign,
      content: s.content
    }
  end

  defp action_data_source(_) do
    nil
  end

  defp action_data_contact(
        %Supporter{
          fingerprint: ref,
          first_name: first_name,
          email: email
        },
        %Contact{
          payload: payload,
          crypto_nonce: nonce,
          public_key: %PublicKey{public: public},
          sign_key: %PublicKey{public: sign}
        }
      ) do
    %{
      ref: Supporter.base_encode(ref),
      firstName: first_name,
      email: email,
      payload: Contact.base_encode(payload),
      nonce: Contact.base_encode(nonce),
      publicKey: PublicKey.base_encode(public),
      signKey: PublicKey.base_encode(sign)
    }
  end

  defp action_data_contact(
        %Supporter{
          fingerprint: ref,
          first_name: first_name,
          email: email
        },
        %Contact{
          payload: payload
        }
      ) do
    %{
      ref: Supporter.base_encode(ref),
      firstName: first_name,
      email: email,
      payload: payload
    }
  end

  def action_data(action, stage \\ :deliver) do
    action = Repo.preload(action,
      [
        [supporter: [[contacts: [:public_key, :sign_key]], :consent]],
        :action_page, :campaign,
        :source,
        :fields
      ])
    contact = hd(action.supporter.contacts)
    privacy = if action.with_consent do
      %{
        "communication" => action.supporter.consent.communication,
        "givenAt" => (action.supporter.consent.given_at |> DateTime.to_iso8601())
      }
    else
      nil
    end

    %{
      "actionId" => action.id,
      "actionPageId" => action.action_page_id,
      "campaignId" => action.campaign_id,
      "orgId" => action.action_page.org_id,
      "action" => %{
        "actionType" => action.action_type,
        "fields" => Field.list_to_map(action.fields),
        "createdAt" => (action.inserted_at |> NaiveDateTime.to_iso8601())
      },
      "actionPage" => %{
        "locale" => action.action_page.locale,
        "url" => action.action_page.url,
        "thankYouTemplateRef" => action.action_page.thank_you_template_ref
      },
      "campaign" => %{
        "name" => action.campaign.name,
        "externalId" => action.campaign.external_id
      },
      "contact" => action_data_contact(action.supporter, contact),
      "privacy" => privacy,
      "source" => action_data_source(action)
    }
    |> put_action_meta(stage)
  end

  @doc "We just pass action id around because we can just retrieve the action and have a synced copy"
  def brief_action_data(action, stage \\ :deliver) do
    action = Repo.preload(action, [:action_page])
    %{
      "actionId" => action.id,
      "actionPageId" => action.action_page_id,
      "campaignId" => action.campaign_id,
      "orgId" => action.action_page.org_id
    }
    |> put_action_meta(stage)
  end

  def put_action_meta(map, stage) do
    map
    |> Map.put("schema", "proca:action:1")
    |> Map.put("stage", Atom.to_string(stage))
  end
end
