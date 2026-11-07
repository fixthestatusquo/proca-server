defmodule Proca.Actions.SourceLocationTest do
  use Proca.DataCase
  import Proca.Source, only: [get_tracking_location: 2]

  @urls [
    origin: "https://saveoceans.org",
    domain_only: "https://saveoceans.org/",
    full_url: "https://saveoceans.org/reefmiracle",
    other_origin: "https://www.saveoceans.org",
    full_url_with_query: "https://saveoceans.org/reefmiracle?foo=bar&baz=123"
  ]

  test "location on the same origin is kept, minus query" do
    assert get_tracking_location(@urls[:full_url], @urls[:origin]) == @urls[:full_url]
    assert get_tracking_location(@urls[:full_url], @urls[:domain_only]) == @urls[:full_url]

    assert get_tracking_location(@urls[:full_url_with_query], @urls[:origin]) ==
             "https://saveoceans.org/reefmiracle"

    # default port is the same origin
    assert get_tracking_location("https://saveoceans.org:443/reef", @urls[:origin]) ==
             "https://saveoceans.org/reef"
  end

  test "location on another origin falls back to the origin" do
    assert get_tracking_location(@urls[:other_origin], @urls[:origin]) == @urls[:origin]

    assert get_tracking_location("http://saveoceans.org/x", @urls[:origin]) == @urls[:origin]

    assert get_tracking_location("http://saveoceans.org:3000/x", "https://saveoceans.org") ==
             "https://saveoceans.org"

    # lookalike host, the old String.starts_with? guard let this through
    assert get_tracking_location("https://saveoceans.org.evil.com/x", @urls[:origin]) ==
             @urls[:origin]
  end

  test "malformed location falls back to the origin" do
    assert get_tracking_location("whatever", @urls[:origin]) == @urls[:origin]
    assert get_tracking_location(nil, @urls[:full_url]) == @urls[:full_url]
  end

  test "no usable origin means no location" do
    assert get_tracking_location(@urls[:full_url], "whatever") == nil
    assert get_tracking_location(@urls[:full_url], "null") == nil
    assert get_tracking_location(nil, "whatever") == nil
    assert get_tracking_location(nil, "null") == nil
  end

  test "disallowed dev hosts are never stored as location" do
    assert get_tracking_location(nil, "http://localhost:4000/x") == nil
    assert get_tracking_location(nil, "http://127.0.0.1:4000/x") == nil
    assert get_tracking_location(nil, "http://0.0.0.0:4000/x") == nil
    assert get_tracking_location(nil, "http://app.localhost:4000/x") == nil

    # allowed origin, disallowed location falls back to the origin
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
