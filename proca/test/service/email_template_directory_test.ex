defmodule Proca.EmailTemplateDirectoryTest do
  use Proca.DataCase
  alias Proca.Service.EmailTemplateDirectory
  alias Proca.Service.EmailTemplate
  alias Proca.Repo
  alias Swoosh.Email

  setup do
    org = Factory.insert(:org)

    t = %EmailTemplate{
      name: "test",
      locale: "en",
      subject: "Hello {{first_name}}",
      html: "<p>Click here {{first_name}}: {{link}}.</p>",
      org_id: org.id
    }

    v = %{
      first_name: "Henry",
      link: "https://proca.app/123"
    }

    %{
      org: org,
      template1: {t, v}
    }
  end

  test "fetch local template", %{
    org: org,
    template1: {t, v}
  } do
    t2 = Repo.insert_and_notify!(t)

    assert t2.id != nil

    {:ok, t3} = EmailTemplateDirectory.by_name(org, t2.name, t2.locale)

    assert t3.id == t2.id
    assert t3.compiled != nil

    Ecto.Changeset.change(t3, subject: "Good day {{first_name}}")
    |> Repo.update_and_notify!()

    GenServer.call(EmailTemplateDirectory, :sync)

    {:ok, t4} = EmailTemplateDirectory.by_name(org, t2.name, t2.locale)
    assert t4.compiled != nil

    assert String.starts_with?(t4.subject, "Good day")

    email = Email.new(to: {"test", "test@proca.app"}, assigns: v)

    e2 = EmailTemplate.render(email, t4)
    assert e2.subject == "Good day Henry"
    assert e2.html_body == "<p>Click here Henry: https://proca.app/123.</p>"
    assert e2.text_body == nil
  end
end
