defmodule Proca.Server.KeysTest do
  use Proca.DataCase
  doctest Proca.Server.Keys

  import Proca.StoryFactory, only: [red_story: 0]
  alias Proca.{Repo, PublicKey, Org}

  setup do
    Process.flag :trap_exit, true
    red_story()
  end

  test "Key server fails when given non-existing org" do
    {:error, p} = GenServer.start_link(Proca.Server.Keys, "foobar")
    assert p =~ ~r/find org foobar/
  end

  test "Key server fails silently (exit with :ignore) when instance org has no keys", %{red_org: org} do
    p = GenServer.start_link(Proca.Server.Keys, org.name)
    assert p == :ignore
  end

  test "Sever works when instance org has keys", %{red_org: org} do
    PublicKey.build_for(org) |> Repo.insert()
    p = GenServer.start_link(Proca.Server.Keys, org.name)
    refute_receive({:EXIT, p, _}, 100)
  end

  test "I can get keys for encryption from server", %{red_org: o1, yellow_org: o2} do
    {:ok, pk1} =  PublicKey.build_for(o1) |> Repo.insert()
    {:ok, pk2} = PublicKey.build_for(o2) |> Repo.insert()

    {:ok, p} = GenServer.start_link(Proca.Server.Keys, o1.name)

    {o1_priv, o2_pub, nonce1, key_ids} = GenServer.call(p, {:encryption, [from: o1.id, to: o2.id]})

    assert o1_priv == pk1.private
    assert o2_pub == pk2.public
    assert key_ids[:from] == pk1.id
    assert key_ids[:to] == pk2.id

    {o1_priv, o2_pub, nonce1, _k} = GenServer.call(p, {:encryption, [to: o2.id]})

    assert o1_priv == pk1.private
    assert o2_pub == pk2.public

    {:ok, pk22} = PublicKey.build_for(o2) |> Repo.insert()

    # change a key for o2
    GenServer.cast(p, {:update_key, o2.id, fn -> pk22 end})

    {o1_priv, o2_pub, nonce1, _k} = GenServer.call(p, {:encryption, [from: o1.id, to: o2.id]})
    assert o1_priv == pk1.private
    assert o2_pub == pk22.public
  end

  test "I get null for recipient key if they don't have a key", %{red_org: o1, yellow_org: o2} do
    {:ok, pk1} =  PublicKey.build_for(o1) |> Repo.insert()

    {:ok, p} = GenServer.start_link(Proca.Server.Keys, o1.name)

    assert :plaintext == GenServer.call(p, {:encryption, [from: o1.id, to: o2.id]})
  end
end
