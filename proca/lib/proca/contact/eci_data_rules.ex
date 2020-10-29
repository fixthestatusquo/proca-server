defmodule Proca.Contact.EciDataRules do
  @moduledoc """
  Rules generated from SQL released by EC (see utils/ECI).
  Provides `schema` macro to generate EciData embedded schema
  """
  @rules %{
    "at" => %{
      "id.card" => %{"pattern" => "[0-9]{7}|[0-9]{8}", "skippable" => true},
      "passport" => %{"pattern_i" => "[a-z][0-9]{7,8}", "skippable" => true}
    },
    "be" => %{
      "national.id.number" => %{
        "pattern" => "([0-9][0-9]).(0?0[1-9]|1[0-2]).([0-2]?[0-2][0-9]|3[0-1])-[0-9]{3}.[0-9]{2}",
        "skippable" => true
      }
    },
    "bg" => %{
      "personal.number" => %{"pattern" => "[0-9]{10}", "skippable" => true}
    },
    "common" => %{
      "city" => %{"empty" => false, "skippable" => false},
      "country" => %{"empty" => false, "skippable" => false},
      "date.of.birth" => %{"age" => true, "empty" => false, "skippable" => false},
      "family.names" => %{"empty" => false, "skippable" => false},
      "full.first.names" => %{"empty" => false, "skippable" => false},
      "postal.code" => %{"empty" => false, "skippable" => true},
      "street" => %{"empty" => false, "skippable" => false},
      "street.number" => %{"empty" => false, "skippable" => false}
    },
    "cy" => %{
      "id.card" => %{"pattern" => "[0-9]{1,10}", "skippable" => true},
      "passport" => %{
        "pattern_i" => "([bcej][0-9]{6})|(k[0-9]{8})|([ds]p[0-9]{7})",
        "skippable" => true
      }
    },
    "cz" => %{
      "id.card" => %{
        "pattern" => "([0-9]{9})|([0-9]{6}[a-z]{2}[0-9]{2})|([0-9]{6}[a-z]{2})|([a-z]{2}[0-9]{6})",
        "skippable" => true
      },
      "passport" => %{"pattern" => "[0-9]{7,8}", "skippable" => true}
    },
    "de" => %{"postal.code" => %{"pattern" => "[0-9]{5}", "skippable" => true}},
    "dk" => %{"postal.code" => %{"pattern" => "[0-9]{4}", "skippable" => true}},
    "ee" => %{
      "personal.number" => %{"pattern" => "[0-9]{11}", "skippable" => true}
    },
    "es" => %{
      "id.card" => %{"pattern_i" => "[0-9]{8}[a-z]", "skippable" => true},
      "passport" => %{"pattern_i" => "[a-z0-9]*", "skippable" => true}
    },
    "fi" => %{"postal.code" => %{"pattern" => "[0-9]{5}", "skippable" => true}},
    "fr" => %{"postal.code" => %{"pattern" => "[0-9]{5}", "skippable" => true}},
    "gr" => %{"postal.code" => %{"pattern" => "[0-9]{5}", "skippable" => true}},
    "hr" => %{"personal.id" => %{"pattern" => "[0-9]{11}", "skippable" => true}},
    "hu" => %{
      "id.card" => %{
        "pattern_i" => "([0-9]{6}[a-z]{2})|([a-z]{2}[a-z][0-9]{6})|([a-z]{2}[a-z]{2}[0-9]{6})|([a-z]{2}[a-z]{3}[0-9]{6})|([a-z]{2}[0-9]{6})",
        "skippable" => true
      },
      "passport" => %{
        "pattern_i" => "([a-z]{2}[0-9]{6})|([a-z]{2}[0-9]{7})",
        "skippable" => true
      },
      "personal.number" => %{
        "pattern" => "[0-9][0-9]{6}[0-9]{4}",
        "skippable" => true
      }
    },
    "ie" => %{"postal.code" => %{"skippable" => true}},
    "it" => %{
      "id.card" => %{
        "pattern_i" => "([a-z]{2}[0-9]{6,8})|([0-9]{7}[a-z]{2})|([a-z]{2}[0-9]{5}[a-z]{2})",
        "skippable" => true
      },
      "issuing.authority" => %{"empty" => false, "skippable" => true},
      "passport" => %{
        "pattern_i" => "([a-z]{2}[0-9]{7})|([a-z][0-9]{6})|([0-9]{6}[a-z])",
        "skippable" => true
      }
    },
    "lt" => %{
      "personal.number" => %{"pattern" => "[0-9]{11}", "skippable" => true}
    },
    "lu" => %{"postal.code" => %{"pattern" => "[0-9]{4}", "skippable" => true}},
    "lv" => %{
      "personal.id" => %{"pattern" => "[0-9]{6}[0-9]{5}", "skippable" => true}
    },
    "mt" => %{"id.card" => %{"pattern_i" => "[a-z0-9]*", "skippable" => true}},
    "nl" => %{
      "postal.code" => %{
        "pattern_i" => "[1-9][0-9]{3}[a-z]{2}",
        "skippable" => true
      }
    },
    "pl" => %{
      "national.id.number" => %{"pattern" => "[0-9]{11}", "skippable" => true}
    },
    "pt" => %{
      "citizens.card" => %{
        "pattern_i" => "[0-9]{9}[a-z]{2}[0-9]",
        "skippable" => true
      },
      "id.card" => %{"pattern" => "[0-9]{1,8}", "skippable" => true},
      "passport" => %{
        "pattern_i" => "([a-z]{1}[0-9]{6})|([a-z]{2}[0-9]{6})",
        "skippable" => true
      }
    },
    "ro" => %{
      "id.card" => %{"pattern_i" => "[a-z]{2}[0-9]{6}", "skippable" => true},
      "passport" => %{"pattern_i" => "[a-z0-9]*", "skippable" => true},
      "personal.id" => %{"pattern" => "[0-9]{13}", "skippable" => true}
    },
    "se" => %{
      "personal.number" => %{
        "pattern" => "([0-9]{8}-[0-9]{4}|[0-9]{6}-[0-9]{4}|[0-9]{12}|[0-9]{10})",
        "skippable" => true
      }
    },
    "si" => %{
      "personal.number" => %{"pattern" => "[0-9]{13}", "skippable" => true}
    },
    "sk" => %{
      "postal.code" => %{"pattern" => "[089][0-9]{4}", "skippable" => true}
    }
  }

  # remove:
  # , "residence.permit"
  @required_fields %{
    "at" => ["passport", "id.card", "full.first.names", "family.names"],
    "be" => ["full.first.names", "family.names", "national.id.number"],
    "bg" => ["personal.number", "full.first.names", "family.names"],
    "cy" => ["full.first.names", "family.names", "passport", "id.card"],
    "cz" => ["family.names", "passport", "id.card", "full.first.names"],
    "de" => ["city", "country", "postal.code", "full.first.names", "street", "family.names", "street.number", "date.of.birth"],
    "dk" => ["country", "street", "postal.code", "street.number", "date.of.birth", "full.first.names", "family.names", "city"],
    "ee" => ["full.first.names", "family.names", "personal.number"],
    "es" => ["id.card", "full.first.names", "family.names", "passport"],
    "fi" => ["street.number", "date.of.birth", "city", "country", "postal.code", "full.first.names", "street", "family.names"],
    "fr" => ["city", "country", "postal.code", "full.first.names", "date.of.birth", "family.names", "street", "street.number"],
    "gr" => ["full.first.names", "family.names", "street", "street.number", "city", "country", "postal.code"],
    "hr" => ["full.first.names", "personal.id", "family.names", "passport"],
    "hu" => ["id.card", "full.first.names", "family.names", "passport", "personal.number"],
    "ie" => ["city", "country", "postal.code", "full.first.names", "street", "family.names", "street.number", "date.of.birth"],
    "it" => ["full.first.names", "family.names", "passport", "id.card"],
    "lt" => ["full.first.names", "personal.number", "family.names"],
    "lu" => ["postal.code", "full.first.names", "street", "family.names", "street.number", "date.of.birth", "city", "country"],
    "lv" => ["personal.id", "full.first.names", "family.names"],
    "mt" => ["full.first.names", "family.names", "id.card"],
    "nl" => ["full.first.names", "street", "family.names", "street.number", "date.of.birth", "city", "country", "postal.code"],
    "pl" => ["full.first.names", "family.names", "national.id.number"],
    "pt" => ["family.names", "citizens.card", "passport", "id.card", "full.first.names"],
    "ro" => ["personal.id", "passport", "id.card", "full.first.names", "family.names"],
    "se" => ["full.first.names", "family.names", "personal.number"],
    "si" => ["personal.number", "full.first.names", "family.names"],
    "sk" => ["street", "postal.code", "city", "country", "street.number", "full.first.names", "family.names", "date.of.birth"]
  }

  @document_types [
    "passport",
    "id.card",
    "residence.permit",
    "personal.number",
    "personal.id",
    "national.id.number",
    "citizens.card"
  ]

  @postcode_formats %{
    "at" => ~r/^.*$/,
    "be" => ~r/^.*$/,
    "bg" => ~r/^.*$/,
    "cy" => ~r/^.*$/,
    "cz" => ~r/^.*$/,
    "de" => ~r/^[0-9]{5}$/,
    "dk" => ~r/^[0-9]{4}$/,
    "ee" => ~r/^.*$/,
    "es" => ~r/^.*$/,
    "fi" => ~r/^[0-9]{5}$/,
    "fr" => ~r/^[0-9]{5}$/,
    "gr" => ~r/^[0-9]{5}$/,
    "hr" => ~r/^.*$/,
    "hu" => ~r/^.*$/,
    "ie" => ~r/^.*$/,
    "it" => ~r/^.*$/,
    "lt" => ~r/^.*$/,
    "lu" => ~r/^[0-9]{4}$/,
    "lv" => ~r/^.*$/,
    "mt" => ~r/^.*$/,
    "nl" => ~r/^.*$/,
    "pl" => ~r/^.*$/,
    "pt" => ~r/^.*$/, 
    "ro" => ~r/^.*$/,
    "se" => ~r/^.*$/,
    "si" => ~r/^.*$/,
    "sk" => ~r/^[089][0-9]{4}$/
  }

  @document_number_formats %{
    "at" => %{
      "id.card" => ~r/^[0-9]{7}|[0-9]{8}$/,
      "passport" => ~r/^[a-z][0-9]{7,8}$/i
    },
    "be" => %{
      "national.id.number" => ~r/^([0-9][0-9]).(0?0[1-9]|1[0-2]).([0-2]?[0-2][0-9]|3[0-1])-[0-9]{3}.[0-9]{2}$/
    },
    "bg" => %{"personal.number" => ~r/^[0-9]{10}$/},
    "common" => %{},
    "cy" => %{
      "id.card" => ~r/^[0-9]{1,10}$/,
      "passport" => ~r/^([bcej][0-9]{6})|(k[0-9]{8})|([ds]p[0-9]{7})$/i
    },
    "cz" => %{
      "id.card" => ~r/^([0-9]{9})|([0-9]{6}[a-z]{2}[0-9]{2})|([0-9]{6}[a-z]{2})|([a-z]{2}[0-9]{6})$/,
      "passport" => ~r/^[0-9]{7,8}$/
    },
    "de" => %{},
    "dk" => %{},
    "ee" => %{"personal.number" => ~r/^[0-9]{11}$/},
    "es" => %{"id.card" => ~r/^[0-9]{8}[a-z]$/i, "passport" => ~r/[a-z0-9]*/i},
    "fi" => %{},
    "fr" => %{},
    "gr" => %{},
    "hr" => %{"personal.id" => ~r/^[0-9]{11}$/},
    "hu" => %{
      "id.card" => ~r/^([0-9]{6}[a-z]{2})|([a-z]{2}[a-z][0-9]{6})|([a-z]{2}[a-z]{2}[0-9]{6})|([a-z]{2}[a-z]{3}[0-9]{6})|([a-z]{2}[0-9]{6})$/i,
      "passport" => ~r/^([a-z]{2}[0-9]{6})|([a-z]{2}[0-9]{7})$/i,
      "personal.number" => ~r/^[0-9][0-9]{6}[0-9]{4}$/
    },
    "ie" => %{},
    "it" => %{
      "id.card" => ~r/^([a-z]{2}[0-9]{6,8})|([0-9]{7}[a-z]{2})|([a-z]{2}[0-9]{5}[a-z]{2})$/i,
      "passport" => ~r/^([a-z]{2}[0-9]{7})|([a-z][0-9]{6})|([0-9]{6}[a-z])$/i
    },
    "lt" => %{"personal.number" => ~r/^[0-9]{11}$/},
    "lu" => %{},
    "lv" => %{"personal.id" => ~r/^[0-9]{6}[0-9]{5}$/},
    "mt" => %{"id.card" => ~r/^[a-z0-9]*$/i},
    "nl" => %{},
    "pl" => %{"national.id.number" => ~r/^[0-9]{11}$/},
    "pt" => %{
      "citizens.card" => ~r/^[0-9]{9}[a-z]{2}[0-9]$/i,
      "id.card" => ~r/^[0-9]{1,8}$/,
      "passport" => ~r/^([a-z]{1}[0-9]{6})|([a-z]{2}[0-9]{6})$/i
    },
    "ro" => %{
      "id.card" => ~r/^[a-z]{2}[0-9]{6}$/i,
      "passport" => ~r/^[a-z0-9]*$/i,
      "personal.id" => ~r/^[0-9]{13}$/
    },
    "se" => %{
      "personal.number" => ~r/^([0-9]{8}-[0-9]{4}|[0-9]{6}-[0-9]{4}|[0-9]{12}|[0-9]{10})$/
    },
    "si" => %{"personal.number" => ~r/^[0-9]{13}$/},
    "sk" => %{}
  }

  @age_limits %{
    "gr" => 17,
    "mt" => 16,
    "at" => 16,
    "ee" => 16
  }

  @countries ["at", "be", "bg", "cy", "cz", "de", "dk", "ee", "es", "fi", "fr",
              "gr", "hr", "hu", "ie", "it", "lt", "lu", "lv", "mt", "nl", "pl", "pt", "ro",
              "se", "si", "sk"]

  require Ecto.Schema

  def rules() do
    @rules
  end

  def countries() do
    @countries
  end

  def our_field(fld) do
    case fld do
      "full.first.names" -> :first_name
      "family.names" -> :last_name
      "date.of.birth" -> :birth_date
      "postal.code" -> :postcode
      x -> x |> String.replace(".", "_") |> String.to_atom
    end
  end


  def postcode_format(country) do
    Map.get(@postcode_formats, country, ~r/^.*$/)
  end


  def required(country) do
    Map.get(@required_fields, country)
    |> Enum.filter(fn f -> not Enum.member?(@document_types, f) end)
    |> Enum.map(&our_field/1)
  end

  def required_document_types(country) do
    Map.get(@required_fields, country)
    |> Enum.filter(fn f -> Enum.member?(@document_types, f) end)
  end

  def document_number_format(country, document_type) do
    p = @document_number_formats
    |> Map.get(country, %{})
    |> Map.get(document_type)

    case p  do
      nil -> ~r// #throw "no pattern for document number #{country} #{document_type}"
      p -> p
    end
  end

  def age_limit(country) do
    Map.get(@age_limits, country, 18)
  end

  # helper functions to turn @rules into other @ fields

  def fields(rls) do
    Map.values(rls)
    |> Enum.map(&(Map.keys(&1)))  # get field names from each rule
    |> List.flatten               # flatten into a list, sort, uniq
    |> Enum.sort
    |> Enum.uniq
    |> Enum.map(&String.replace(&1, ".", "_"))  # turn . -> _
    |> Enum.map(&String.to_atom(&1))            # make atoms
  end


  def postcode_formats(rls \\ @rules) do
    whatever = ~r/.*/
    Enum.map(rls, fn {c, r} ->
      case r do
        %{"postal.code" => %{"pattern" => pat}} -> {c, Regex.compile!(pat)}
        _ -> {c, whatever}
      end
    end)
    |> Map.new
  end

  def document_number_formats(rls \\ @rules) do
    Enum.map(rls, fn {c, r} ->
      k_map = r
      |> Enum.filter(fn {f, _k} -> Enum.member?( @document_types, f) end)
      |> Enum.map(fn {f, k} ->
        case k do
          %{"pattern" => reg} -> {f, Regex.compile!(reg)}
          %{"pattern_i" => reg} -> {f, Regex.compile!(reg, "i")}
          _ -> {f, ~r//}
        end
      end)
      |> Map.new
      {c, k_map}
    end)
    |> Map.new
  end

end
