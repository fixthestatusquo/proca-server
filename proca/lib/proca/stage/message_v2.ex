defmodule Proca.Stage.MessageV2 do
  alias Proca.Stage.MessageV1
  alias Proca.Stage.Support
  alias Proca.Repo
  alias Proca.{Contact, Supporter, PublicKey, Action}

  def action_data(action, stage \\ :deliver, org_id) do
    action =
      Repo.preload(
        action,
        [
          [supporter: [contacts: [:public_key, :sign_key]]],
          :action_page,
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
        "thankYouTemplateRef" => MessageV1.action_page_template_ref(action.action_page)
      },
      "campaignId" => action.campaign_id,
      "campaign" => %{
        "name" => action.campaign.name,
        "title" => action.campaign.title,
        "externalId" => action.campaign.external_id
      },
      "orgId" => action.action_page.org_id,
      "action" =>
        %{
          "actionType" => action.action_type,
          "customFields" => action.fields,
          "createdAt" => action.inserted_at |> Support.to_iso8601()
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
          fingerprint: ref
        },
        contact
      ) do
    %{
      "firstName" => first_name,
      "email" => email,
      "contactRef" => Contact.base_encode(ref)
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

  def contact_privacy(supporter, contact, new_consent \\ true)

  def contact_privacy(
        %Supporter{
          email_status: email_status,
          email_status_changed: email_status_changed
        },
        contact = %Contact{},
        new_consent
      ) do
    p = %{
      "emailStatus" =>
        if email_status == :none do
          nil
        else
          Atom.to_string(email_status)
        end,
      "emailStatusChanged" =>
        if email_status_changed != nil do
          Support.to_iso8601(email_status_changed)
        else
          nil
        end
    }

    if new_consent do
      %{
        "optIn" => contact.communication_consent,
        "givenAt" => contact.inserted_at |> Support.to_iso8601()
      }
      |> Map.merge(p)
    else
      p
    end
  end

  def contact_privacy(_, nil, _), do: nil

  def put_action_meta(map, stage) do
    map
    |> Map.put("schema", "proca:action:2")
    |> Map.put("stage", Atom.to_string(stage))
  end
end
