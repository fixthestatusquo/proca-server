defmodule Proca.Validations do
  import Ecto.Changeset

  @doc """
  Validate that change is a:
  - map
  - keys are strings
  - values are strings, numbers, or lists of strings and numbers
  """
  @spec validate_flat_map(Ecto.Changeset.t(), atom()) :: Ecto.Changeset.t()
  def validate_flat_map(changeset, fieldname) do
    validate_change(changeset, fieldname, fn f, fields ->
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

  @doc """
  Validate that two fields are Datetimes after each other.
  """
  def validate_after(%{errors: errors} = changeset, field1, field2) do
    dt1 = get_change(changeset, field1)
    dt2 = get_change(changeset, field2)

    case {dt1, dt2} do
      {%DateTime{}, %DateTime{}} ->
        case DateTime.compare(dt2, dt1) do
          :gt ->
            changeset

          _ ->
            %{
              changeset
              | errors: errors ++ [{field2, {"should be after #{field1}", [validation: :after]}}],
                valid?: false
            }
        end

      # ignore validating if not two DateTimes
      _ ->
        changeset
    end
  end

  def peek_unique_error({:ok, record} = x), do: x

  def peek_unique_error({:error, error}) do
    case error do
      %{
        errors: [
          {field, {_m, [c | _r]}}
        ]
      }
      when c in [
             constraint: :unique,
             validation: :unsafe_unique
           ] ->
        {:not_unique, field, error}

      # some other error
      e ->
        {:error, e}
    end
  end
end
