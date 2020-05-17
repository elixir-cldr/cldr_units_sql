if Code.ensure_loaded?(Ecto.Type) do
  defmodule Cldr.Unit.Ecto.Composite.Type do
    @moduledoc """
    Implements the Ecto.Type behaviour for a user-defined Postgres composite type
    called `:money_with_currency`.

    This is the preferred option for Postgres database since the serialized money
    amount is stored as a decimal number,
    """

    @behaviour Ecto.Type

    def type do
      :unit
    end

    def blank?(_) do
      false
    end

    # When loading from the database
    def load({unit_name, unit_amount}) do
      with {:ok, unit} <- Cldr.Unit.new(unit_name, unit_amount) do
        {:ok, unit}
      else
        _ -> :error
      end
    end

    # Dumping to the database.  We make the assumption that
    # since we are dumping from %Money{} structs that the
    # data is ok
    def dump(%Cldr.Unit{} = unit) do
      {:ok, {unit.name, unit.value}}
    end

    def dump(_) do
      :error
    end

    # Casting in changesets
    def cast(%Cldr.Unit{} = unit) do
      {:ok, unit}
    end

    def cast(%{"unit" => _, "amount" => ""}) do
      {:ok, nil}
    end

    def cast(%{"unit" => unit_name, "amount" => amount})
        when (is_binary(unit_name) or is_atom(unit_name)) and is_number(amount) do
      with decimal_amount <- Decimal.new(amount),
           {:ok, unit} <- Cldr.Unit.new(unit_name, decimal_amount) do
        {:ok, unit}
      else
        {:error, {_, message}} -> {:error, message: message}
      end
    end

    def cast(%{"unit" => unit_name, "amount" => amount})
        when (is_binary(unit_name) or is_atom(unit_name)) and is_binary(amount) do
      with {:ok, amount} <- Decimal.parse(amount),
           {:ok, unit} <- Cldr.Unit.new(unit_name, amount) do
        {:ok, unit}
      else
        {:error, {_, message}} -> {:error, message: message}
        :error -> {:error, message: "Couldn't parse amount #{inspect amount}"}
      end
    end

    def cast(%{"unit" => unit_name, "amount" => %Decimal{} = amount})
        when is_binary(unit_name) or is_atom(unit_name) do
      with {:ok, unit} <- Cldr.Unit.new(unit_name, amount) do
        {:ok, unit}
      else
        {:error, {_, message}} -> {:error, message: message}
      end
    end

    def cast(%{unit: unit_name, amount: amount}) do
      cast(%{"unit" => unit_name, "amount" => amount})
    end

    def cast(_money) do
      :error
    end

    # New for ecto_sql 3.2
    def embed_as(_), do: :self
    def equal?(term1, term2), do: term1 == term2
  end
end
