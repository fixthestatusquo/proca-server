defmodule ProcaWeb.Api.EciSecurityTest do
  use ProcaWeb.ConnCase
  import Proca.StoryFactory, only: [eci_story: 0]

  setup do
    eci_story()
  end

  def query(ap_id, vars) do
    """
    mutation Sign {
      addActionContact(
        contact:{
          nationality:  {
            country: "#{Map.get(vars, :nat_country, "at")}",
            documentType: "#{Map.get(vars, :nat_dt, "passport")}",
            documentNumber: "#{Map.get(vars, :nat_dn, "R1234567")}"
          },
          firstName: "#{Map.get(vars, :first_name, "Olaf")}",
          lastName: "#{Map.get(vars, :last_name, "Foobar")}",
          birthDate: "#{Map.get(vars, :birth_date, "2000-01-01")}",
          address: {
            country: "#{Map.get(vars, :add_country, "")}",
            postcode: "#{Map.get(vars, :add_postcode, "")}",
            locality: "#{Map.get(vars, :add_locality, "")}",
            street: "#{Map.get(vars, :add_street, "")}"
          }
        },
        action: {actionType: "register", fields: []},
        actionPageId: #{ap_id},
        privacy: {optIn: false}
      ) {
      contactRef
      }
    }
    """
  end


  test "Sending HTML tags in fields fails", %{conn: conn, pages: [ap]} do
    bad_input = [
      {%{first_name: "<SCRIPT>alert()"}, "firstName: has invalid format"},
      {%{first_name: "'-alert(1)-'"}, "firstName: has invalid format"},
      {%{first_name: "http://217.69.168.225"}, "firstName: has invalid format"},
      {%{first_name: "%77%77%77%2E%6B%6F%6D%70%75%72%69%74%79%2E%64%65"}, "firstName: has invalid format"},
      {%{first_name: "http://0000331.0x0000045.168.0xE1"}, "firstName: has invalid format"},
      {%{last_name: "<SCRIPT>alert()"}, "lastName: has invalid format"},
      {%{birth_date: ""},
       "Argument \"contact\" has invalid value {nationality: {country: \"at\", documentType: \"passport\", documentNumber: \"R1234567\"}, firstName: \"Olaf\", lastName: \"Foobar\", birthDate: \"\", address: {country: \"\", postcode: \"\", locality: \"\", street: \"\"}}.\nIn field \"birthDate\": Expected type \"Date\", found \"\"."
       },
      {%{nat_country: "fr", add_postcode: "0000-000000000000000-0000"}, "postcode: has invalid format"}
      
    ]

    bad_input
    |> Enum.each(fn {vars, message} ->
      q = query(ap.id, vars)
      conn
      |> api_post(q)
      |> json_response(200)
      |> has_error_message(message)
    end)

  end

  test "Send a very long field", %{conn: conn, pages: [ap]} do
    bad_input = [
      {%{first_name: String.duplicate("Foo", 2000)}, "firstName: should be at most 64 character(s)"}
    ]
 
    bad_input
    |> Enum.each(fn {vars, message} ->
      q = query(ap.id, vars)
      conn
      |> api_post(q)
      |> json_response(200)
      |> has_error_message(message)
    end)
  end

end
