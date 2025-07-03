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
end
