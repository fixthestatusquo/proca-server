defmodule Proca.Actions.SourceLocationTest do
  use Proca.DataCase
  import Proca.Source, only: [get_tracking_location: 2]

  @urls [
    domain_only: "https://saveoceans.org/",
    full_url: "https://saveoceans.org/reefmiracle",
    random_word: "whatever",
    other_url: "https://www.saveoceans.org/oops",
    full_url_with_query: "https://saveoceans.org/reefmiracle?foo=bar&baz=123"
  ]

  test "get_tracking_location helper" do
    get_tracking_location(nil, @urls[:full_url] == @urls[:full_url])
    get_tracking_location(@urls[:full_url], @urls[:domain_only] == @urls[:full_url])
    get_tracking_location(@urls[:random_word], nil == nil)
    get_tracking_location(@urls[:random_word], @urls[:random_word] == nil)
    get_tracking_location(@urls[:random_word], @urls[:domain_only] == @urls[:domain_only])

    get_tracking_location(
      @urls[:full_url_with_query],
      @urls[:full_url_with_query] == @urls[:full_url]
    )

    get_tracking_location(@urls[:full_url], @urls[:full_url_with_query] == @urls[:full_url])
  end

  test "disallowed dev hosts are never stored as location" do
    assert get_tracking_location(nil, "http://localhost:4000/x") == nil
    assert get_tracking_location(nil, "http://127.0.0.1:4000/x") == nil
    assert get_tracking_location(nil, "http://0.0.0.0:4000/x") == nil
    assert get_tracking_location(nil, "http://app.localhost:4000/x") == nil

    # allowed referer, disallowed location falls back to the referer
    assert get_tracking_location("http://localhost:4000/x", "https://saveoceans.org/p") ==
             "https://saveoceans.org/p"
  end

  test "DISALLOWED_LOCATION_HOSTS is merged with the defaults" do
    Application.put_env(:proca, :disallowed_location_hosts, ["Widget.Proca.App"])
    on_exit(fn -> Application.delete_env(:proca, :disallowed_location_hosts) end)

    assert get_tracking_location(nil, "https://widget.proca.app/x") == nil
    assert get_tracking_location(nil, "http://localhost:4000/x") == nil
    assert get_tracking_location(nil, "https://saveoceans.org/x") == "https://saveoceans.org/x"
  end
end
