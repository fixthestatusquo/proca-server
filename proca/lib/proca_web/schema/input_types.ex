defmodule ProcaWeb.Schema.InputTypes do
  use Absinthe.Schema.Notation

  @desc "Type to describe an area (identified by area_code) in some administrative division (area_type). Area code can be an official code or just a name, provided they are unique."
  input_object :area_input do
    field :area_code, :string
    field :area_type, :string
  end

end
