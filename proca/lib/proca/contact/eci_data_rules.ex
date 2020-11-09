defmodule Proca.Contact.EciDataRules do
  @moduledoc """
  Rules generated from SQL released by EC (see utils/ECI).
  Provides `schema` macro to generate EciData embedded schema
  """
  @rules %{
    "AT" => %{
      "id.card" => %{"pattern" => "[0-9]{7}|[0-9]{8}", "skippable" => true},
      "passport" => %{"pattern_i" => "[a-z][0-9]{7,8}", "skippable" => true}
    },
    "BE" => %{
      "national.id.number" => %{
        "pattern" => "([0-9][0-9]).(0?0[1-9]|1[0-2]).([0-2]?[0-2][0-9]|3[0-1])-[0-9]{3}.[0-9]{2}",
        "skippable" => true
      }
    },
    "BG" => %{
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
    "CY" => %{
      "id.card" => %{"pattern" => "[0-9]{1,10}", "skippable" => true},
      "passport" => %{
        "pattern_i" => "([bcej][0-9]{6})|(k[0-9]{8})|([ds]p[0-9]{7})",
        "skippable" => true
      }
    },
    "CZ" => %{
      "id.card" => %{
        "pattern" =>
          "([0-9]{9})|([0-9]{6}[a-z]{2}[0-9]{2})|([0-9]{6}[a-z]{2})|([a-z]{2}[0-9]{6})",
        "skippable" => true
      },
      "passport" => %{"pattern" => "[0-9]{7,8}", "skippable" => true}
    },
    "DE" => %{"postal.code" => %{"pattern" => "[0-9]{5}", "skippable" => true}},
    "DK" => %{"postal.code" => %{"pattern" => "[0-9]{4}", "skippable" => true}},
    "EE" => %{
      "personal.number" => %{"pattern" => "[0-9]{11}", "skippable" => true}
    },
    "ES" => %{
      "id.card" => %{"pattern_i" => "[0-9]{8}[a-z]", "skippable" => true},
      "passport" => %{"pattern_i" => "[a-z0-9]*", "skippable" => true}
    },
    "FI" => %{"postal.code" => %{"pattern" => "[0-9]{5}", "skippable" => true}},
    "FR" => %{"postal.code" => %{"pattern" => "[0-9]{5}", "skippable" => true}},
    "GR" => %{"postal.code" => %{"pattern" => "[0-9]{5}", "skippable" => true}},
    "HR" => %{"personal.id" => %{"pattern" => "[0-9]{11}", "skippable" => true}},
    "HU" => %{
      "id.card" => %{
        "pattern_i" =>
          "([0-9]{6}[a-z]{2})|([a-z]{2}[a-z][0-9]{6})|([a-z]{2}[a-z]{2}[0-9]{6})|([a-z]{2}[a-z]{3}[0-9]{6})|([a-z]{2}[0-9]{6})",
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
    "IE" => %{"postal.code" => %{"skippable" => true}},
    "IT" => %{
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
    "LT" => %{
      "personal.number" => %{"pattern" => "[0-9]{11}", "skippable" => true}
    },
    "LU" => %{"postal.code" => %{"pattern" => "[0-9]{4}", "skippable" => true}},
    "LV" => %{
      "personal.id" => %{"pattern" => "[0-9]{6}[0-9]{5}", "skippable" => true}
    },
    "MT" => %{"id.card" => %{"pattern_i" => "[a-z0-9]*", "skippable" => true}},
    "NL" => %{
      "postal.code" => %{
        "pattern_i" => "[1-9][0-9]{3}[a-z]{2}",
        "skippable" => true
      }
    },
    "PL" => %{
      "national.id.number" => %{"pattern" => "[0-9]{11}", "skippable" => true}
    },
    "PT" => %{
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
    "RO" => %{
      "id.card" => %{"pattern_i" => "[a-z]{2}[0-9]{6}", "skippable" => true},
      "passport" => %{"pattern_i" => "[a-z0-9]*", "skippable" => true},
      "personal.id" => %{"pattern" => "[0-9]{13}", "skippable" => true}
    },
    "SE" => %{
      "personal.number" => %{
        "pattern" => "([0-9]{8}-[0-9]{4}|[0-9]{6}-[0-9]{4}|[0-9]{12}|[0-9]{10})",
        "skippable" => true
      }
    },
    "SI" => %{
      "personal.number" => %{"pattern" => "[0-9]{13}", "skippable" => true}
    },
    "SK" => %{
      "postal.code" => %{"pattern" => "[089][0-9]{4}", "skippable" => true}
    }
  }

  # remove:
  # , "residence.permit"
  @required_fields %{
    "AT" => ["passport", "id.card", "full.first.names", "family.names"],
    "BE" => ["full.first.names", "family.names", "national.id.number"],
    "BG" => ["personal.number", "full.first.names", "family.names"],
    "CY" => ["full.first.names", "family.names", "passport", "id.card"],
    "CZ" => ["family.names", "passport", "id.card", "full.first.names"],
    "DE" => [
      "city",
      "country",
      "postal.code",
      "full.first.names",
      "street",
      "family.names",
      "street.number",
      "date.of.birth"
    ],
    "DK" => [
      "country",
      "street",
      "postal.code",
      "street.number",
      "date.of.birth",
      "full.first.names",
      "family.names",
      "city"
    ],
    "EE" => ["full.first.names", "family.names", "personal.number"],
    "ES" => ["id.card", "full.first.names", "family.names", "passport"],
    "FI" => [
      "street.number",
      "date.of.birth",
      "city",
      "country",
      "postal.code",
      "full.first.names",
      "street",
      "family.names"
    ],
    "FR" => [
      "city",
      "country",
      "postal.code",
      "full.first.names",
      "date.of.birth",
      "family.names",
      "street",
      "street.number"
    ],
    "GR" => [
      "full.first.names",
      "family.names",
      "street",
      "street.number",
      "city",
      "country",
      "postal.code"
    ],
    "HR" => ["full.first.names", "personal.id", "family.names", "passport"],
    "HU" => ["id.card", "full.first.names", "family.names", "passport", "personal.number"],
    "IE" => [
      "city",
      "country",
      "postal.code",
      "full.first.names",
      "street",
      "family.names",
      "street.number",
      "date.of.birth"
    ],
    "IT" => ["full.first.names", "family.names", "passport", "id.card"],
    "LT" => ["full.first.names", "personal.number", "family.names"],
    "LU" => [
      "postal.code",
      "full.first.names",
      "street",
      "family.names",
      "street.number",
      "date.of.birth",
      "city",
      "country"
    ],
    "LV" => ["personal.id", "full.first.names", "family.names"],
    "MT" => ["full.first.names", "family.names", "id.card"],
    "NL" => [
      "full.first.names",
      "street",
      "family.names",
      "street.number",
      "date.of.birth",
      "city",
      "country",
      "postal.code"
    ],
    "PL" => ["full.first.names", "family.names", "national.id.number"],
    "PT" => ["family.names", "citizens.card", "passport", "id.card", "full.first.names"],
    "RO" => ["personal.id", "passport", "id.card", "full.first.names", "family.names"],
    "SE" => ["full.first.names", "family.names", "personal.number"],
    "SI" => ["personal.number", "full.first.names", "family.names"],
    "SK" => [
      "street",
      "postal.code",
      "city",
      "country",
      "street.number",
      "full.first.names",
      "family.names",
      "date.of.birth"
    ]
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
    "AT" => ~r/^.*$/,
    "BE" => ~r/^.*$/,
    "BG" => ~r/^.*$/,
    "CY" => ~r/^.*$/,
    "CZ" => ~r/^.*$/,
    "DE" => ~r/^[0-9]{5}$/,
    "DK" => ~r/^[0-9]{4}$/,
    "EE" => ~r/^.*$/,
    "ES" => ~r/^.*$/,
    "FI" => ~r/^[0-9]{5}$/,
    "FR" => ~r/^[0-9]{5}$/,
    "GR" => ~r/^[0-9]{5}$/,
    "HR" => ~r/^.*$/,
    "HU" => ~r/^.*$/,
    "IE" => ~r/^.*$/,
    "IT" => ~r/^.*$/,
    "LT" => ~r/^.*$/,
    "LU" => ~r/^[0-9]{4}$/,
    "LV" => ~r/^.*$/,
    "MT" => ~r/^.*$/,
    "NL" => ~r/^.*$/,
    "PL" => ~r/^.*$/,
    "PT" => ~r/^.*$/,
    "RO" => ~r/^.*$/,
    "SE" => ~r/^.*$/,
    "SI" => ~r/^.*$/,
    "SK" => ~r/^[089][0-9]{4}$/
  }

  @document_number_formats %{
    "AT" => %{
      "id.card" => ~r/^[0-9]{7}|[0-9]{8}$/,
      "passport" => ~r/^[a-z][0-9]{7,8}$/i
    },
    "BE" => %{
      "national.id.number" =>
        ~r/^([0-9][0-9]).(0?0[1-9]|1[0-2]).([0-2]?[0-2][0-9]|3[0-1])-[0-9]{3}.[0-9]{2}$/
    },
    "BG" => %{"personal.number" => ~r/^[0-9]{10}$/},
    "common" => %{},
    "CY" => %{
      "id.card" => ~r/^[0-9]{1,10}$/,
      "passport" => ~r/^([bcej][0-9]{6})|(k[0-9]{8})|([ds]p[0-9]{7})$/i
    },
    "CZ" => %{
      "id.card" =>
        ~r/^([0-9]{9})|([0-9]{6}[a-z]{2}[0-9]{2})|([0-9]{6}[a-z]{2})|([a-z]{2}[0-9]{6})$/,
      "passport" => ~r/^[0-9]{7,8}$/
    },
    "DE" => %{},
    "DK" => %{},
    "EE" => %{"personal.number" => ~r/^[0-9]{11}$/},
    "ES" => %{"id.card" => ~r/^[0-9]{8}[a-z]$/i, "passport" => ~r/[a-z0-9]*/i},
    "FI" => %{},
    "FR" => %{},
    "GR" => %{},
    "HR" => %{"personal.id" => ~r/^[0-9]{11}$/},
    "HU" => %{
      "id.card" =>
        ~r/^([0-9]{6}[a-z]{2})|([a-z]{2}[a-z][0-9]{6})|([a-z]{2}[a-z]{2}[0-9]{6})|([a-z]{2}[a-z]{3}[0-9]{6})|([a-z]{2}[0-9]{6})$/i,
      "passport" => ~r/^([a-z]{2}[0-9]{6})|([a-z]{2}[0-9]{7})$/i,
      "personal.number" => ~r/^[0-9][0-9]{6}[0-9]{4}$/
    },
    "IE" => %{},
    "IT" => %{
      "id.card" => ~r/^([a-z]{2}[0-9]{6,8})|([0-9]{7}[a-z]{2})|([a-z]{2}[0-9]{5}[a-z]{2})$/i,
      "passport" => ~r/^([a-z]{2}[0-9]{7})|([a-z][0-9]{6})|([0-9]{6}[a-z])$/i
    },
    "LT" => %{"personal.number" => ~r/^[0-9]{11}$/},
    "LU" => %{},
    "LV" => %{"personal.id" => ~r/^[0-9]{6}[0-9]{5}$/},
    "MT" => %{"id.card" => ~r/^[a-z0-9]*$/i},
    "NL" => %{},
    "PL" => %{"national.id.number" => ~r/^[0-9]{11}$/},
    "PT" => %{
      "citizens.card" => ~r/^[0-9]{9}[a-z]{2}[0-9]$/i,
      "id.card" => ~r/^[0-9]{1,8}$/,
      "passport" => ~r/^([a-z]{1}[0-9]{6})|([a-z]{2}[0-9]{6})$/i
    },
    "RO" => %{
      "id.card" => ~r/^[a-z]{2}[0-9]{6}$/i,
      "passport" => ~r/^[a-z0-9]*$/i,
      "personal.id" => ~r/^[0-9]{13}$/
    },
    "SE" => %{
      "personal.number" => ~r/^([0-9]{8}-[0-9]{4}|[0-9]{6}-[0-9]{4}|[0-9]{12}|[0-9]{10})$/
    },
    "SI" => %{"personal.number" => ~r/^[0-9]{13}$/},
    "SK" => %{}
  }

  @age_limits %{
    "GR" => 17,
    "MT" => 16,
    "AT" => 16,
    "EE" => 16
  }

  @countries [
    "AT",
    "BE",
    "BG",
    "CY",
    "CZ",
    "DE",
    "DK",
    "EE",
    "ES",
    "FI",
    "FR",
    "GR",
    "HR",
    "HU",
    "IE",
    "IT",
    "LT",
    "LU",
    "LV",
    "MT",
    "NL",
    "PL",
    "PT",
    "RO",
    "SE",
    "SI",
    "SK"
  ]

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
      "city" -> :locality
      x -> x |> String.replace(".", "_") |> String.to_atom()
    end
  end

  def postcode_format(country) do
    Map.get(@postcode_formats, country, ~r/^.*$/)
  end

  def required(country) do
    Map.fetch!(@required_fields, country)
    |> Enum.filter(fn f -> not Enum.member?(@document_types, f) end)
    |> Enum.map(&our_field/1)
  end

  def required_document_types(country) do
    Map.fetch!(@required_fields, country)
    |> Enum.filter(fn f -> Enum.member?(@document_types, f) end)
  end

  def document_number_format(country, document_type) do
    p =
      @document_number_formats
      |> Map.get(country, %{})
      |> Map.get(document_type)

    case p do
      # throw "no pattern for document number #{country} #{document_type}"
      nil -> ~r//
      p -> p
    end
  end

  def age_limit(country) do
    Map.get(@age_limits, country, 18)
  end

  # helper functions to turn @rules into other @ fields

  def fields(rls) do
    Map.values(rls)
    # get field names from each rule
    |> Enum.map(&Map.keys(&1))
    # flatten into a list, sort, uniq
    |> List.flatten()
    |> Enum.sort()
    |> Enum.uniq()
    # turn . -> _
    |> Enum.map(&String.replace(&1, ".", "_"))
    # make atoms
    |> Enum.map(&String.to_atom(&1))
  end

  def postcode_formats(rls \\ @rules) do
    whatever = ~r/.*/

    Enum.map(rls, fn {c, r} ->
      case r do
        %{"postal.code" => %{"pattern" => pat}} -> {c, Regex.compile!(pat)}
        _ -> {c, whatever}
      end
    end)
    |> Map.new()
  end

  def document_number_formats(rls \\ @rules) do
    Enum.map(rls, fn {c, r} ->
      k_map =
        r
        |> Enum.filter(fn {f, _k} -> Enum.member?(@document_types, f) end)
        |> Enum.map(&format_desc_to_re/1)
        |> Map.new()

      {c, k_map}
    end)
    |> Map.new()
  end

  defp format_desc_to_re({field, desc}) do
    case desc do
      %{"pattern" => reg} -> {field, Regex.compile!(reg)}
      %{"pattern_i" => reg} -> {field, Regex.compile!(reg, "i")}
      _ -> {field, ~r//}
    end
  end
end
