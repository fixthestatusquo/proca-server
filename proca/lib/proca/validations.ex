defmodule Proca.Validations do
  @doc """
  Validate that change is a:
  - map
  - keys are strings
  - values are strings, numbers, or lists of strings and numbers
  """
  @spec validate_flat_map(Ecto.Changeset.t(), atom()) :: Changeset.t()
  def validate_flat_map(changeset, fieldname) do
    Ecto.Changeset.validate_change(changeset, fieldname, fn f, fields ->
      valid =
        is_map(fields) and
          Enum.all?(
            Enum.map(fields, fn {k, v} ->
              is_bitstring(k) and
                (is_bitstring(v) or is_number(v) or
                   (is_list(v) and
                      (Enum.all?(Enum.map(v, &is_bitstring/1)) or
                         Enum.all?(Enum.map(v, &is_number/1)))))
            end)
          )

      if valid do
        []
      else
        [{f, "must be a map of string to values of strings or numbers, or lists of them"}]
      end
    end)
  end
end
