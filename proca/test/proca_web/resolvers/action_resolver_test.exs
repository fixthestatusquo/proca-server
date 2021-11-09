defmodule ProcaWeb.ActionResolverTest do
  use Proca.DataCase

  doctest ProcaWeb.Resolvers.Action
  import Proca.StoryFactory, only: [blue_story: 0]
  import Proca.Repo 
  import Ecto.Query, only: [from: 2]

  alias Proca.{Repo, Action, Supporter}

  defp some_action_data(ap) do
    %{
      action_page_id: ap.id,
      action: %{
        action_type: "signature"
      },
      contact: %{
        first_name: "Blixa",
        last_name: "Bargeld",
        email: "ein@sturzen.de",
        address: %{
          postcode: "01-234",
          country: "pl"
        }
      },
      privacy: %{
        opt_in: true
      }
    }
  end

  test "add petition action to a basic data campaign" do
    %{org: org, pages: [ap]} = blue_story()

    params = some_action_data(ap)

    {:ok, created} =
      ProcaWeb.Resolvers.Action.add_action_contact(nil, params, %Absinthe.Resolution{})

    Proca.Server.Processing.sync()

    assert %{contact_ref: ref, first_name: blx} = created

    assert blx == "Blixa"

    sup = Repo.get_by(Supporter, fingerprint: Supporter.base_decode(ref) |> elem(1))

    assert %Supporter{} = sup

    sup = Repo.preload(sup, [:actions, :contacts])

    assert length(sup.actions) == 1
    assert length(sup.contacts) == 1

    assert not is_nil(sup.first_name)
    assert not is_nil(sup.area)

    assert sup.processing_status == :new or
             (sup.processing_status == :accepted and is_nil(sup.email))

    assert %{
             communication_consent: true,
             communication_scopes: ["email"],
             public_key_id: nil,
             crypto_nonce: nil
           } = hd(sup.contacts)

    # User has done the share step

    action_params = %{
      action_page_id: ap.id,
      contact_ref: ref,
      action: %{
        action_type: "share",
        fields: [
          %{
            key: "medium",
            value: "tiktok"
          },
          %{
            key: "age",
            value: "44",
            transient: true
          }
        ]
      }
    }

    {:ok, created} =
      ProcaWeb.Resolvers.Action.add_action(nil, action_params, %Absinthe.Resolution{})

    Proca.Server.Processing.sync()

    sup = Repo.get_by(Supporter, fingerprint: Supporter.base_decode(ref) |> elem(1))
    sup = Repo.preload(sup, [:actions, :contacts])

    assert length(sup.actions) == 2

    share = Enum.find(sup.actions, fn a -> a.action_type == "share" end)
    assert Map.get(share.fields, "medium", :not_found) == "tiktok"
  end

  test "add custom fields (new and old format)" do 
    %{org: org, pages: [ap]} = blue_story()

    custom_fields = fn cf, f -> 
      params = some_action_data(ap)
      
      # conditionally add these params
      a = params.action
      a = if cf != nil, do: Map.put(a, :custom_fields, cf), else: a
      a = if f != nil, do: Map.put(a, :fields, f), else: a
      params = %{params | action: a}
    
      {:ok, _created} = ProcaWeb.Resolvers.Action.add_action_contact(nil, params, %Absinthe.Resolution{})
      last = one from(a in Action, limit: 1, order_by: [desc: :id])
      last.fields
    end

    assert custom_fields.(%{"new" => 123}, [%{key: "bar", value: "456"}]) == %{"new" => 123, "bar" => "456"}
    assert custom_fields.(nil, [%{key: "bar", value: "456"}]) == %{"bar" => "456"}
    assert custom_fields.(nil, [%{key: "bar", value: "456"}, %{key: "bar", value: "987"}]) == %{"bar" => ["987", "456"]}
    assert custom_fields.(%{"new" => 123, "key" => "val"}, nil) == %{"new" => 123, "key" => "val"}
    assert custom_fields.(%{"new" => 123, "food" => ["pizza", "pasta"]}, [%{key: "bar", value: "456"}]) == %{"new" => 123, "bar" => "456", "food" => ["pizza", "pasta"]} 

  end

  test "add signature with tracking" do
    %{org: org, pages: [ap]} = blue_story()

    params =
      some_action_data(ap)
      |> Map.put(:tracking, %{campaign: "email123", medium: "email", source: "team"})

    {:ok, created} =
      ProcaWeb.Resolvers.Action.add_action_contact(nil, params, %Absinthe.Resolution{})

    Proca.Server.Processing.sync()

    sup =
      Repo.get_by(Supporter, fingerprint: Supporter.base_decode(created.contact_ref) |> elem(1))

    sup = Repo.preload(sup, [:source, [actions: :source]])

    assert sup.source.id == hd(sup.actions).source.id
    assert %{campaign: "email123", medium: "email", source: "team", content: ""} = sup.source
  end
end

