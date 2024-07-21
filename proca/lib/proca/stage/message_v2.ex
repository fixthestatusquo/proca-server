defmodule Proca.Stage.MessageV2 do
  alias Proca.Stage.MessageV1
  alias Proca.Stage.Support
  alias Proca.Repo
  alias Proca.{Contact, Supporter, PublicKey}

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
      "actionPage" => %{
        "locale" => action.action_page.locale,
        "name" => action.action_page.name,
        "thankYouTemplate" => action.action_page.thank_you_template,
        "thankYouTemplateRef" => MessageV1.action_page_template_ref(action.action_page),
        "supporterConfirmTemplate" =>
          action.action_page.supporter_confirm_template ||
            action.action_page.org.supporter_confirm_template
      },
      "campaignId" => action.campaign_id,
      "campaign" => %{
        "name" => action.campaign.name,
        "title" => action.campaign.title,
        "externalId" => action.campaign.external_id,
        "contactSchema" => Atom.to_string(action.campaign.contact_schema)
      },
      "org" => %{
        "name" => action.action_page.org.name,
        "title" => action.action_page.org.title
      },
      "orgId" => action.action_page.org_id,
      "action" =>
        %{
          "actionType" => action.action_type,
          "customFields" => action.fields,
          "createdAt" => action.inserted_at |> Support.to_iso8601(),
          "testing" => action.testing
        }
        |> MessageV1.put_action_donation(action.donation),
      "contact" => contact_data(action.supporter, contact),
      "personalInfo" => personal_info_data(contact),
      "privacy" => contact_privacy(action.supporter, contact, action.with_consent),
      "tracking" => MessageV1.tracking_data(action)
    }
    |> put_action_meta(stage)
  end

  def contact_data(
        %Supporter{
          first_name: first_name,
          email: email,
          fingerprint: ref,
          dupe_rank: dupe_rank,
          area: area
        },
        contact
      ) do
    %{
      "firstName" => first_name,
      "email" => email,
      "contactRef" => Contact.base_encode(ref),
      "dupeRank" => dupe_rank,
      "area" => area
    }
    |> contact_data_cleartext(contact)
  end

  def contact_data_cleartext(
        d,
        %Contact{crypto_nonce: nil, payload: payload}
      ) do
    contact_fields = Jason.decode!(payload)
    Map.merge(d, contact_fields)
  end

  def contact_data_cleartext(d, _encrypted_contact) do
    d
  end

  def personal_info_data(nil), do: nil

  def personal_info_data(%{crypto_nonce: nil}), do: nil

  def personal_info_data(%{
        payload: payload,
        crypto_nonce: nonce,
        public_key: %PublicKey{id: enc_id, public: enc_key},
        sign_key: %PublicKey{id: sign_id, public: sign_key}
      }) do
    %{
      payload: Contact.base_encode(payload),
      nonce: Contact.base_encode(nonce),
      encryptKey: %{
        id: enc_id,
        public: PublicKey.base_encode(enc_key)
      },
      signKey: %{
        id: sign_id,
        public: PublicKey.base_encode(sign_key)
      }
    }
  end

  @doc """
  Action data for organization that a contact record was created will contain a consent,
  and withConsent field signifying that on this exact action the consent was collected.
  """
  def contact_privacy(supporter, contact, with_consent \\ false)

  def contact_privacy(supporter, contact = %Contact{}, with_consent) do
    %{
      "optIn" => contact.communication_consent,
      "givenAt" => contact.inserted_at |> Support.to_iso8601()
    }
    |> contact_privacy_supporter(supporter)
    |> contact_privacy_consent(with_consent)
  end

  # this variant is only for supporter with no contact (wiped out or missing contact data)
  def contact_privacy(supporter, nil, _with_consent) do
    %{}
    |> contact_privacy_supporter(supporter)
    |> contact_privacy_consent(false)
  end

  defp contact_privacy_supporter(d, %Supporter{
         email_status: email_status,
         email_status_changed: email_status_changed
       }) do
    es =
      case email_status do
        :none -> nil
        es -> Atom.to_string(es)
      end

    esch =
      case email_status_changed do
        nil -> nil
        dt -> Support.to_iso8601(dt)
      end

    %{
      "emailStatus" => es,
      "emailStatusChanged" => esch
    }
    |> Map.merge(d)
  end

  defp contact_privacy_consent(d, with_consent) do
    Map.put(d, "withConsent", with_consent)
  end

  def put_action_meta(map, stage) do
    map
    |> Map.put("schema", "proca:action:2")
    |> Map.put("stage", Atom.to_string(stage))
  end
end
