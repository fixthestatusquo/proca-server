defmodule Proca.Stage.MessageV1 do
  alias Proca.{Action, Supporter, PublicKey, Contact}
  alias Proca.Repo
  alias Proca.Stage.Support

  def tracking_data(%Action{source: s}) when not is_nil(s) do
    %{
      "source" => s.source,
      "medium" => s.medium,
      "campaign" => s.campaign,
      "content" => s.content,
      "location" => s.location
    }
  end

  def tracking_data(_) do
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
           email: email,
           area: area
         },
         %Contact{
           payload: payload
         }
       ) do
    %{
      "ref" => Supporter.base_encode(ref),
      "firstName" => first_name,
      "area" => area,
      "email" => email,
      "payload" => payload
    }
  end

  defp action_data_contact(
         %Supporter{
           fingerprint: ref,
           first_name: first_name,
           email: email,
           area: area
         },
         contact
       )
       when is_nil(contact) do
    %{
      "ref" => Supporter.base_encode(ref),
      "firstName" => first_name,
      "email" => email,
      "area" => area,
      "payload" => ""
    }
  end

  def contact_privacy(%Action{with_consent: true}, contact = %Contact{}) do
    %{
      "communication" => contact.communication_consent,
      "givenAt" => contact.inserted_at |> Support.to_iso8601()
    }
  end

  def contact_privacy(%Action{}, _) do
    nil
  end

  def action_data(action, stage \\ :deliver, org_id) do
    action =
      Repo.preload(
        action,
        [
          [supporter: [contacts: [:public_key, :sign_key]]],
          [action_page: :org],
          :campaign,
          :source,
          :donation
        ]
      )

    contact = Enum.find(action.supporter.contacts, fn c -> c.org_id == org_id end)

    %{
      "actionId" => action.id,
      "actionPageId" => action.action_page_id,
      "campaignId" => action.campaign_id,
      "orgId" => action.action_page.org_id,
      "action" =>
        %{
          "actionType" => action.action_type,
          "fields" => action.fields,
          "createdAt" => action.inserted_at |> Support.to_iso8601(),
          "testing" => action.testing
        }
        |> put_action_donation(action.donation),
      "actionPage" => %{
        "locale" => action.action_page.locale,
        "name" => action.action_page.name,
        "thankYouTemplate" => action.action_page.thank_you_template,
        "thankYouTemplateRef" => action_page_template_ref(action.action_page)
      },
      "campaign" => %{
        "name" => action.campaign.name,
        "title" => action.campaign.title,
        "externalId" => action.campaign.external_id
      },
      "org" => %{
        "name" => action.action_page.org.name,
        "title" => action.action_page.org.title
      },
      "contact" => action_data_contact(action.supporter, contact),
      "privacy" => contact_privacy(action, contact),
      "tracking" => tracking_data(action)
    }
    |> put_action_meta(stage)
  end

  def put_action_meta(map, stage) do
    map
    |> Map.put("schema", "proca:action:1")
    |> Map.put("stage", Atom.to_string(stage))
  end

  def put_action_donation(action_map, donation = %Action.Donation{}) do
    donation_map = %{
      "payload" => donation.payload,
      "amount" => donation.amount,
      "currency" => donation.currency,
      "frequencyUnit" => donation.frequency_unit
    }

    donation_map =
      if is_nil(donation.schema),
        do: donation_map,
        else: Map.put(donation_map, "schema", Atom.to_string(donation.schema))

    action_map
    |> Map.put("donation", donation_map)
  end

  def put_action_donation(action_map, donation) when is_nil(donation), do: action_map

  def action_page_template_ref(action_page) do
    alias Proca.Service.EmailTemplateDirectory

    case EmailTemplateDirectory.by_name(action_page.org, action_page.thank_you_template) do
      {:ok, %{ref: ref}} -> ref
      _ -> nil
    end
  end
end
