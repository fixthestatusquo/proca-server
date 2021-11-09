defmodule ProcaWeb.JwtAuthPlugTest do
  use ProcaWeb.ConnCase

  setup do 
    jwt_json = """
    {
      "exp": 1612385939,
      "iat": 1612385934,
      "iss": "https://proca.lvh.me/",
      "jti": "26f2a55b-15f0-4253-ad1d-ed43e7b963d2",
      "nbf": 1612385934,
      "session": {
        "active": true,
        "authenticated_at": "2021-02-02T22:31:05.962921Z",
        "expires_at": "2021-02-03T22:31:05.962921Z",
        "id": "44ab1af0-0893-4be9-94c7-d1e06a5668ab",
        "identity": {
          "id": "1ca4899c-0f09-4624-83a5-b5dee21f1779",
          "recovery_addresses": [
            {
              "id": "ac4072e4-a106-4417-8694-127bc7dd7ced",
              "value": "marcin@tttp.eu",
              "via": "email"
            }
          ],
          "schema_id": "default",
          "schema_url": "https://proca.lvh.me/.ory/kratos/public/schemas/default",
          "traits": {
            "email": "marcin@tttp.eu",
            "first_name": "Marcin",
            "last_name": "Koziej"
          },
          "verifiable_addresses": [
            {
              "id": "8ec22f24-7574-4ae9-8bc2-043ce04d3670",
              "status": "pending",
              "value": "marcin@tttp.eu",
              "verified": true,
              "verified_at": null,
              "via": "email"
            }
          ]
        },
        "issued_at": "2021-02-02T22:31:05.962952Z"
      },
      "sub": "1ca4899c-0f09-4624-83a5-b5dee21f1779"
    }
    """

    %{
      jwt: %JOSE.JWT{fields: Jason.decode!(jwt_json)}
    }
  end

  def set_require_verified_email(bool) do 
    Application.put_env(:proca, Proca, 
      Application.get_env(:proca, Proca) 
      |> Keyword.put(:require_verified_email, bool)
    )
  end

  test "checking whether email is verified", %{jwt: jwt} do
    set_require_verified_email(true)
    assert ProcaWeb.Plugs.JwtAuthPlug.check_email_verified(jwt) == :ok

    jwt2 = %JOSE.JWT{
      fields: update_in(
      jwt.fields, 
      ["session", "identity", "verifiable_addresses"],
      fn [e] -> [%{e | "verified" => false}] end)
    }

    assert ProcaWeb.Plugs.JwtAuthPlug.check_email_verified(jwt2) == :unverified

  end
end

