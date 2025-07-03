defmodule Proca.Contact.EciBgTest do
  use ExUnit.Case
  # use Proca.DataCase

  import Proca.Contact.EciBg

  test "should detect correct UCI number from 1907" do
    assert is_valid("0701270855") == true
  end

  test "should detect correct UCI number from 2009" do
    assert is_valid("0948220092") == true
  end

  test "should detect correct UCI number from 1899" do
    assert is_valid("9926177023") == true
  end

  test "should detect UCI with wrong checksum" do
    assert is_valid("0701270845") == false
  end

  test "should detect UCI with invalid month" do
    assert is_valid("0775270849") == false
  end

  test "should detect February 29th on non leap year as incorrect" do
    assert is_valid("0702290849") == false
  end

  test "should detect February 29th on leap year as correct" do
    assert is_valid("0802290844") == true
  end

  test "should detect March 32th as incorrect" do
    assert is_valid("0703320847") == false
  end

  test "should detect less than 10 characters as incorrect" do
    assert is_valid("07033") == false
  end

  test "should detect presence of not numbers as incorrect" do
    assert is_valid("0703320_47") == false
  end

  test "should detect birthday from the future as incorrect" do
    assert is_valid("3043290844") == false
  end

  @correct_ucis [
    "0006241052",
    "0048195952",
    "0052214707",
    "0107130416",
    "0247236062",
    "0248126497",
    "0409197132",
    "0452284817",
    "0501059660",
    "0610043193",
    "0749024728",
    "0803206463",
    "0805051798",
    "0809142237",
    "0846093170",
    "0904039488",
    "0905156600",
    "0942164089",
    "0947285951",
    "1005094175",
    "1011099540",
    "1203054870",
    "1305044679",
    "1307033565",
    "1307109296",
    "1604071264",
    "1612089087",
    "1711048913",
    "1804309160",
    "1901132027",
    "1907164042",
    "1910104100",
    "1911024760",
    "2002019673",
    "2002270138",
    "2010240996",
    "2010250103",
    "2211249402",
    "2304290900",
    "2312301469",
    "2502274907",
    "2605126070",
    "2711200186",
    "3106070621",
    "3106157193",
    "3107189282",
    "3305164430",
    "3503207166",
    "3504128122",
    "3509280740",
    "4010255372",
    "4210093807",
    "4508035631",
    "4803060381",
    "4909107999",
    "5007221430",
    "5009016959",
    "5202106003",
    "5207255294",
    "5308281922",
    "5309037865",
    "5507225773",
    "5507230620",
    "5606039510",
    "5705315052",
    "5712285624",
    "5907041723",
    "6105313168",
    "6210187577",
    "6310068587",
    "6412217580",
    "6507031002",
    "6606030453",
    "6707252952",
    "6908165398",
    "7003061445",
    "7003145361",
    "7011256229",
    "7202161318",
    "7212094412",
    "7302069740",
    "7307066214",
    "7309083083",
    "7405193928",
    "7405222369",
    "7512254770",
    "7611187412",
    "7807249825",
    "7912248895",
    "8004279120",
    "8307304926",
    "8405168526",
    "8609092874",
    "8903028502",
    "8908020058",
    "8912221242",
    "9006256634",
    "9512167895",
    "9802064381"
  ]

  test "should detect 99 random correct UCI numbers as correct" do
    Enum.each(@correct_ucis, fn uci ->
      assert is_valid(uci)
    end)
  end
end
