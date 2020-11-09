defmodule Server.EncryptTest do
  use Proca.DataCase
  doctest Proca.Server.Encrypt
  import Proca.StoryFactory, only: [red_story: 0]

  alias Proca.Server.Encrypt
  alias Proca.{Org, PublicKey, Repo}

  setup do
    red_story()
  end

  test "Encrypt using Orgs without encryption keys", %{red_org: red_org} do
    assert [] == Ecto.assoc(red_org, :public_keys) |> Repo.all()
    assert {"zebra giraffe", nil, nil, nil} == Encrypt.encrypt(nil, "zebra giraffe")
    assert {"foo bar baz", nil, nil, nil} == Encrypt.encrypt(red_org, "foo bar baz")
  end

  test "Encryption key is updated using notification", %{red_org: red_org} do
    key = Factory.insert(:public_key, org: red_org)
    Proca.Server.Notify.public_key_created(red_org, key)
    {encrypted, nonce, enc_id, sign_id} = Encrypt.encrypt(red_org, "tabula rasa")
    assert not is_nil(nonce)
    assert enc_id == key.id

    instance_org =
      Application.get_env(:proca, Proca)[:org_name] |> Org.get_by_name([:active_public_keys])

    instance_key = instance_org.public_keys |> List.first()
    assert sign_id == instance_key.id
  end
end
