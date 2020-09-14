defmodule Proca.Stage.Support do
  alias Proca.{Action, Supporter, Org, PublicKey, Contact, Field}
  alias Proca.Repo
  import Ecto.Query, only: [from: 2]

  # XXX for now we assume that only ActionPage owner does the processing, but i think it should be up to
  # the AP.delivery flag

  def bulk_actions_data(action_ids, stage \\ :deliver) do
    from(a in Action,
      where: a.id in ^action_ids,
      preload: [
        [supporter: [contacts: [:public_key, :sign_key]]],
        :action_page, :campaign,
        :source,
        :fields
      ])
      |> Repo.all()
      |> Enum.map(fn a -> action_data(a, stage) end)
  end

  defp action_data_source(%Action{source: s}) when not is_nil(s) do
    %{
      "source" => s.source,
      "mediunm" => s.medium,
      "campaign" => s.campaign,
      "content" => s.content
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
      "ref" => Supporter.base_encode(ref),
      "firstName" => first_name,
      "email" => email,
      "payload" => Contact.base_encode(payload),
      "nonce" => Contact.base_encode(nonce),
      "publicKey" => PublicKey.base_encode(public),
      "signKey" => PublicKey.base_encode(sign)
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
      "ref" => Supporter.base_encode(ref),
      "firstName" => first_name,
      "email" => email,
      "payload" => payload
    }
  end


  defp action_data_contact(
    %Supporter{
      fingerprint: ref,
      first_name: first_name,
      email: email
    },
    contact
  ) when is_nil(contact) do
    %{
      "ref" => Supporter.base_encode(ref),
      "firstName" => first_name,
      "email" => email,
      "payload" => ""
    }
  end

  def action_data(action, stage \\ :deliver) do
    action = Repo.preload(action,
      [
        [supporter: [contacts: [:public_key, :sign_key]]],
        :action_page, :campaign,
        :source,
        :fields
      ])

    # XXX we should be explicit about Contact org_id recipient, because for unencrypted contacts we do not have
    # the public_key!
    contact = Enum.find(action.supporter.contacts, fn c -> c.org_id == action.action_page.org_id end)

    privacy = if not is_nil(contact) and action.with_consent do
      %{
        "communication" => contact.communication_consent,
        "givenAt" => contact.inserted_at
        |> DateTime.from_naive!("Etc/UTC")
        |> DateTime.to_iso8601()
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
        "name" => action.action_page.name,
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

  def put_action_meta(map, stage) do
    map
    |> Map.put("schema", "proca:action:1")
    |> Map.put("stage", Atom.to_string(stage))
  end
end
