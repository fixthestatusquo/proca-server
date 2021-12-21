defmodule ProcaWeb.Api.ActionTest do
  use Proca.DataCase
  import Proca.StoryFactory, only: [blue_story: 0]
  import Ecto.Query
  alias Proca.Factory

  alias Proca.{Repo, Action, Supporter}

  @basic_data %{}

  setup do
    blue_story()
  end

  def action_with_ref(_org, ap, action_info) do
    ref = Supporter.base_encode("fake_reference")

    params = %{
      action: action_info,
      action_page_id: ap.id,
      contact_ref: ref
    }

    result = ProcaWeb.Resolvers.Action.add_action(:unused, params, %Absinthe.Resolution{})
    assert result = {:ok, %{contact_ref: ref}}
    result
  end

  def action_with_contact(
        _org,
        ap,
        action_info,
        contact_info,
        other_params \\ %{},
        context \\ %{}
      ) do
    params =
      %{
        action: action_info,
        action_page_id: ap.id,
        contact: contact_info,
        privacy: %{opt_in: true}
      }
      |> Map.merge(other_params)

    result =
      ProcaWeb.Resolvers.Action.add_action_contact(:unused, params, %Absinthe.Resolution{
        context: context
      })

    assert {:ok, %{contact_ref: _ref}} = result
    result
  end

  test "create petition action without custom fields", %{org: org, pages: [ap]} do
    action_with_ref(org, ap, %{action_type: "petiton"})

    [action] =
      Repo.all(from(a in Action, order_by: [desc: :inserted_at], limit: 1, preload: [:supporter]))

    assert action.fields == %{}
    assert action.processing_status == :new
    assert action.action_page_id == ap.id
    assert action.campaign_id == ap.campaign_id
    assert is_nil(action.supporter)
  end

  test "create petition action with custom fields", %{org: org, pages: [ap]} do
    action_with_ref(org, ap, %{
      action_type: "petition",
      fields: [
        %{key: "extra_supporters", value: "5"},
        %{key: "card_url", value: "https://bucket.s3.amazon.com/1234/file.pdf"}
      ]
    })

    [action] =
      Repo.all(from(a in Action, order_by: [desc: :inserted_at], limit: 1, preload: [:supporter]))

    assert map_size(action.fields) == 2
    assert action.processing_status == :new
    assert action.action_page_id == ap.id
    assert action.campaign_id == ap.campaign_id
  end

  @stripe_payment_intent_example1 """
  {
    "id": "pi_1DoS0s2eZvKYlo2ClDw4tUjD",
    "object": "payment_intent",
    "amount": 1099,
    "amount_capturable": 0,
    "amount_received": 0,
    "application": null,
    "application_fee_amount": null,
    "canceled_at": null,
    "cancellation_reason": null,
    "capture_method": "automatic",
    "charges": {
      "object": "list",
      "data": [],
      "has_more": false,
      "url": "/v1/charges?payment_intent=pi_1DoS0s2eZvKYlo2ClDw4tUjD"
    },
    "client_secret": "pi_1DoS0s2eZvKYlo2ClDw4tUjD_secret_Vle7Y30kVlQU7zKFlJXlgp58V",
    "confirmation_method": "automatic",
    "created": 1546505834,
    "currency": "usd",
    "customer": null,
    "description": null,
    "invoice": null,
    "last_payment_error": null,
    "livemode": false,
    "metadata": {},
    "next_action": null,
    "on_behalf_of": null,
    "payment_method": null,
    "payment_method_options": {},
    "payment_method_types": [
      "card"
    ],
    "receipt_email": null,
    "review": null,
    "setup_future_usage": null,
    "shipping": null,
    "statement_descriptor": null,
    "statement_descriptor_suffix": null,
    "status": "requires_payment_method",
    "transfer_data": null,
    "transfer_group": null
  }
  """

  test "create stripe donation action", %{org: org, pages: [ap]} do
    {:ok, %{contact_ref: ref}} =
      action_with_contact(
        org,
        ap,
        %{
          action_type: "stripe-donation",
          donation: %{
            schema: :stripe_payment_intent,
            payload: Jason.decode!(@stripe_payment_intent_example1)
          }
        },
        %{
          email: "donor@example.com",
          first_name: "Mike",
          last_name: "Scott",
          address: %{country: "PL", postcode: "03-123"}
        }
      )

    # fetch last donation action
    {:ok, ref} = Supporter.base_decode(ref)

    last_action =
      from(s in Supporter,
        left_join: a in assoc(s, :actions),
        where: s.fingerprint == ^ref,
        order_by: [desc: a.id],
        select: a
      )
      |> Repo.one()

    assert not is_nil(last_action)

    last_action = Repo.preload(last_action, :donation)
    assert not is_nil(last_action.donation)
    assert last_action.donation.amount == 1099
    assert last_action.donation.currency == "USD"
    assert last_action.donation.frequency_unit == :one_off
    # IO.inspect last_action.donation
  end

  test "create action with location tracking", %{org: org, pages: [ap]} do
    {:ok, result} =
      action_with_contact(
        org,
        ap,
        %{action_type: "x"},
        %{first_name: "Jan", email: "j@a.n"},
        %{},
        %{headers: %{"referer" => "https://example.com/petition?foo=123"}}
      )

    action = Repo.one(from(a in Action, order_by: [desc: a.id], limit: 1))

    assert action.source_id != nil
  end
end
