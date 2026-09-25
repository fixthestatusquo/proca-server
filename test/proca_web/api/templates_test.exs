defmodule ProcaWeb.Api.TemplatesTest do
  use ProcaWeb.ConnCase

  import Proca.StoryFactory, only: [red_story: 0]

  alias Proca.Repo
  alias Proca.Service.EmailTemplate

  setup do
    story = red_story()

    for {name, locale, attrs} <- [
          {"thank_you", "en", %{subject: "Thanks {{firstName}}", html: "<p>Thanks</p>"}},
          {"thank_you", "de", %{subject: "Danke", html: "<p>Danke</p>", text: "Danke"}},
          {"supporter_confirm", "en", %{external_id: "42", subject: "-", html: "-"}}
        ] do
      %EmailTemplate{org: story.yellow_org}
      |> EmailTemplate.changeset(Map.merge(%{name: name, locale: locale}, attrs))
      |> Repo.insert!()
    end

    # template of another org must not be returned
    %EmailTemplate{org: story.red_org}
    |> EmailTemplate.changeset(%{name: "thank_you", locale: "en", subject: "x", html: "x"})
    |> Repo.insert!()

    story
  end

  defp templates_query(org_name, args \\ "") do
    """
    {
      org(name: "#{org_name}") {
        templates#{args} { name locale externalId subject html text }
      }
    }
    """
  end

  test "lists org templates", %{conn: conn, yellow_org: org, yellow_user: user} do
    res =
      conn
      |> auth_api_post(templates_query(org.name), user)
      |> json_response(200)
      |> is_success()

    assert [
             %{"name" => "supporter_confirm", "locale" => "en", "externalId" => "42"},
             %{"name" => "thank_you", "locale" => "de", "text" => "Danke"},
             %{"name" => "thank_you", "locale" => "en", "subject" => "Thanks {{firstName}}"}
           ] = res["data"]["org"]["templates"]
  end

  test "filters by name and locale", %{conn: conn, yellow_org: org, yellow_user: user} do
    res =
      conn
      |> auth_api_post(templates_query(org.name, ~s[(name: "thank_you", locale: "de")]), user)
      |> json_response(200)
      |> is_success()

    assert [%{"name" => "thank_you", "locale" => "de", "html" => "<p>Danke</p>"}] =
             res["data"]["org"]["templates"]
  end
end
