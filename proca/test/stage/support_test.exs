defmodule Proca.Stage.SupportTest do
  use Proca.DataCase

  import Proca.StoryFactory, only: [red_story: 0]

  alias Proca.Stage.Support

  setup do
    red_story()
  end

  test "camel_case_keys ignores config", %{
    red_campaign: camp,
    red_org: org
  } do
    org_data = %{
      name: org.name,
      title: org.title,
      config: %{
        some_field: "value",
        replace: %{
          "https://example.com/example-candidats" => "https://url.com/other-candidats"
        }
      }
    }

    camp_data =
      camp
      |> Map.from_struct()
      |> Map.replace(:config, %{some_key: "val"})
      |> Map.take([:id, :name, :external_id, :title, :config, :contact_schema])
      |> Map.put(:org, org_data)

    camelized_map =
      camp_data
      |> Support.camel_case_keys(ignore: :config)

    assert %{
             "externalId" => _,
             "contactSchema" => _,
             "title" => _,
             "config" => %{"some_key" => _},
             "org" => %{
               "name" => _,
               "config" => %{
                 "some_field" => _,
                 "replace" => %{"https://example.com/example-candidats" => _}
               }
             }
           } = camelized_map
  end
end
