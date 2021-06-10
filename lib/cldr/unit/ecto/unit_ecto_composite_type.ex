if Code.ensure_loaded?(Ecto.Type) do
  defmodule Cldr.Unit.Ecto.Composite.Type do
    @moduledoc """
    Implements the Ecto.Type behaviour for a user-defined Postgres composite type
    called `:cldr_unit`.

    This is the preferred option for Postgres database since the serialized unit
    value is stored as a decimal number,
    """

    @behaviour Ecto.Type

    def type do
      :cldr_unit
    end

    def blank?(_) do
      false
    end

    def load({unit_name, unit_value}) do
      with {:ok, unit} <- Cldr.Unit.new(unit_name, unit_value) do
        {:ok, unit}
      else
        _ -> :error
      end
    end

    # Dumping to the database.  We make the assumption that
    # since we are dumping from %Cldr.Unit{} structs that the
    # data is ok
    def dump(%Cldr.Unit{value: %Ratio{} = value} = unit) do
      value = Decimal.div(Decimal.new(value.numerator), Decimal.new(value.denominator))
      {:ok, {to_string(unit.unit), value}}
    end

    def dump(%Cldr.Unit{} = unit) do
      {:ok, {to_string(unit.unit), unit.value}}
    end

    def dump(_) do
      :error
    end

    # Casting in changesets
    def cast(%Cldr.Unit{} = unit) do
      {:ok, unit}
    end

    def cast(%{"unit" => _, "value" => ""}) do
      {:ok, nil}
    end

    def cast(%{"unit" => unit_name, "value" => value})
        when (is_binary(unit_name) or is_atom(unit_name)) and is_number(value) do
      with decimal_value <- Decimal.new(value),
           {:ok, unit} <- Cldr.Unit.new(unit_name, decimal_value) do
        {:ok, unit}
      else
        {:error, {_, message}} -> {:error, message: message}
      end
    end

    def cast(%{"unit" => unit_name, "value" => value})
        when (is_binary(unit_name) or is_atom(unit_name)) and is_binary(value) do
      with {value, ""} <- Cldr.Decimal.parse(value),
           {:ok, unit} <- Cldr.Unit.new(unit_name, value) do
        {:ok, unit}
      else
        {:error, {_, message}} -> {:error, message: message}
        :error -> {:error, message: "Couldn't parse value #{inspect value}"}
      end
    end

    def cast(%{"unit" => unit_name, "value" => %Decimal{} = value})
        when is_binary(unit_name) or is_atom(unit_name) do
      with {:ok, unit} <- Cldr.Unit.new(unit_name, value) do
        {:ok, unit}
      else
        {:error, {_, message}} -> {:error, message: message}
      end
    end

    def cast(%{unit: unit_name, value: value}) do
      cast(%{"unit" => unit_name, "value" => value})
    end

    def cast(_money) do
      :error
    end

    # New for ecto_sql 3.2
    def embed_as(_), do: :self
    def equal?(term1, term2), do: term1 == term2
  end
end
