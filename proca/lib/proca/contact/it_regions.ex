defmodule Proca.Contact.ItRegions do
  @codes_regions %{
    "00" => "Lazio",
    "01" => "Lazio",
    "02" => "Lazio",
    "03" => "Lazio",
    "04" => "Lazio",
    "05" => "Umbria",
    "06" => "Umbria",
    "07" => "Sardinia",
    "08" => "Sardinia",
    "09" => "Sardinia",
    "10" => "Piedmont",
    "11" => "Aosta Valley",
    "12" => "Piedmont",
    "13" => "Piedmont",
    "14" => "Piedmont",
    "15" => "Piedmont",
    "16" => "Liguria",
    "17" => "Liguria",
    "18" => "Liguria",
    "19" => "Liguria",
    "20" => "Lombardy",
    "21" => "Lombardy",
    "22" => "Lombardy",
    "23" => "Lombardy",
    "24" => "Lombardy",
    "25" => "Lombardy",
    "26" => "Lombardy",
    "27" => "Lombardy",
    "28" => "Piedmont",
    "29" => "Emilia-Romagna",
    "30" => "Veneto",
    "31" => "Veneto",
    "32" => "Veneto",
    "33" => "Friuli-Venezia Giulia",
    "34" => "Friuli-Venezia Giulia",
    "35" => "Veneto",
    "36" => "Veneto",
    "37" => "Veneto",
    "38" => "Trentino-Alto Adige/Südtirol",
    "39" => "Trentino-Alto Adige/Südtirol",
    "40" => "Emilia-Romagna",
    "41" => "Emilia-Romagna",
    "42" => "Emilia-Romagna",
    "43" => "Emilia-Romagna",
    "44" => "Emilia-Romagna",
    "45" => "Veneto",
    "46" => "Lombardy",
    "47" => "Emilia-Romagna",
    "48" => "Emilia-Romagna",
    "50" => "Tuscany",
    "51" => "Tuscany",
    "52" => "Tuscany",
    "53" => "Tuscany",
    "54" => "Tuscany",
    "55" => "Tuscany",
    "56" => "Tuscany",
    "57" => "Tuscany",
    "58" => "Tuscany",
    "59" => "Tuscany",
    "60" => "Marche",
    "61" => "Marche",
    "62" => "Marche",
    "63" => "Marche",
    "64" => "Abruzzo",
    "65" => "Abruzzo",
    "66" => "Abruzzo",
    "67" => "Abruzzo",
    "70" => "Apulia",
    "71" => "Apulia",
    "72" => "Apulia",
    "73" => "Apulia",
    "74" => "Apulia",
    "75" => "Basilicata",
    "76" => "Apulia",
    "80" => "Campania",
    "81" => "Campania",
    "82" => "Campania",
    "83" => "Campania",
    "84" => "Campania",
    "85" => "Basilicata",
    "86" => "Molise",
    "87" => "Calabria",
    "88" => "Calabria",
    "89" => "Calabria",
    "90" => "Sicily",
    "91" => "Sicily",
    "92" => "Sicily",
    "93" => "Sicily",
    "94" => "Sicily",
    "95" => "Sicily",
    "96" => "Sicily",
    "97" => "Sicily",
    "98" => "Sicily"
  }

  def postcode_to_region(postcode) do
    Map.get(@codes_regions, String.slice(postcode, 0, 2), nil)
  end
end
