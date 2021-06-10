if Code.ensure_loaded?(Ecto.Type) do
  defmodule Cldr.Unit.Ecto.Map.Type do
    @moduledoc """
    Implements Ecto.Type behaviour for `Cldr.Unit`, where the underlying schema type
    is a map.

    This is the required option for databases such as MySQL that do not support
    composite types.

    In order to preserve precision, the value is serialized as a string since the
    JSON representation of a numeric value is either an integer or a float.

    `Decimal.to_string/1` is not guaranteed to produce a string that will round-trip
    convert back to the identical number.  However given enough precision in the
    `Decimal.get_context/0` then round trip conversion should be expected.  The default
    precision in the context is 28 digits.
    """

    @behaviour Ecto.Type

    defdelegate cast(money), to: Cldr.Unit.Ecto.Composite.Type

    # New for ecto_sql 3.2
    defdelegate  embed_as(term), to: Cldr.Unit.Ecto.Composite.Type
    defdelegate  equal?(term1, term2), to: Cldr.Unit.Ecto.Composite.Type

    def type() do
      :map
    end

    # "New" values with usage
    def load(%{"unit" => unit_name, "value" => value, "usage" => usage}) when is_binary(value) do
      with {value, ""} <- Cldr.Decimal.parse(value),
           {:ok, unit} <- Cldr.Unit.new(unit_name, value, usage: usage) do
        {:ok, unit}
      else
        _ -> :error
      end
    end

    # "New" values with usage
    def load(%{"unit" => unit_name, "value" => value, "usage" => usage}) when is_integer(value) do
      with {:ok, unit} <- Cldr.Unit.new(unit_name, value, usage: usage) do
        {:ok, unit}
      else
        _ -> :error
      end
    end

    # "Old" values
    def load(%{"unit" => unit_name, "value" => value}) when is_binary(value) do
      with {value, ""} <- Cldr.Decimal.parse(value),
           {:ok, unit} <- Cldr.Unit.new(unit_name, value) do
        {:ok, unit}
      else
        _ -> :error
      end
    end

    # "Old" values
    def load(%{"unit" => unit_name, "value" => value}) when is_integer(value) do
      with {:ok, unit} <- Cldr.Unit.new(unit_name, value) do
        {:ok, unit}
      else
        _ -> :error
      end
    end

    def dump(%Cldr.Unit{unit: unit_name, value: value}) do
      {:ok,
        %{"unit" => to_string(unit_name), "value" => to_string(value)}}
    end

    def dump(_) do
      :error
    end

  end
end
