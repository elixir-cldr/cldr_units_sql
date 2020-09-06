defmodule Cldr.UnitWithUsage.Ecto.Test do
  use ExUnit.Case

  describe "Cldr.UnitWithUsage.Ecto.Composite.Type specific tests" do
    test "load a tuple with an unknown unit produces an error" do
      assert Cldr.UnitWithUsage.Ecto.Composite.Type.load({"ABC", 100, "default"}) == :error
    end

    test "load a tuple produces a Cldr.Unit struct" do
      assert Cldr.UnitWithUsage.Ecto.Composite.Type.load({"meter", 100, "default"}) ==
        {:ok, Cldr.Unit.new!(:meter, 100)}
    end

    test "dump a money struct" do
      assert Cldr.UnitWithUsage.Ecto.Composite.Type.dump(Cldr.Unit.new!(:meter, 100)) ==
        {:ok, {"meter", 100, "default"}}
    end
  end

  describe "Cldr.UnitWithUsage.Ecto.Map.Type specific tests" do
    test "load a json map with a string value produces a Cldr.Unit struct" do
      assert Cldr.UnitWithUsage.Ecto.Map.Type.load(%{"unit" => "meter", "value" => "100", "usage" => "default"}) ==
               {:ok, Cldr.Unit.new!(:meter, Decimal.new(100))}
    end

    test "load a json map with a number value produces a Cldr.Unit struct" do
      assert Cldr.UnitWithUsage.Ecto.Map.Type.load(%{"unit" => "meter", "value" => 100, "usage" => "default"}) ==
               {:ok, Cldr.Unit.new!(:meter, 100)}
    end

    test "load a json map with an unknown unit code produces an error" do
      assert Cldr.UnitWithUsage.Ecto.Map.Type.load(%{"unit" => "AAA", "value" => 100, "usage" => "default"}) == :error
    end

    test "dump a money struct" do
      assert Cldr.UnitWithUsage.Ecto.Map.Type.dump(Cldr.Unit.new!(:meter, 100)) ==
               {:ok, %{"value" => "100", "unit" => "meter", "usage" => "default"}}
    end
  end

  for ecto_type_module <- [Cldr.UnitWithUsage.Ecto.Composite.Type, Cldr.UnitWithUsage.Ecto.Map.Type] do
    test "#{inspect(ecto_type_module)}: dump anything other than a Cldr.Unit struct or a 2-tuple is an error" do
      assert unquote(ecto_type_module).dump(100) == :error
    end

    test "#{inspect(ecto_type_module)}: cast a map with the current structure but an empty value" do
      assert unquote(ecto_type_module).cast(%{"unit" => "meter", "value" => "", "usage" => "default"}) == {:ok, nil}
    end

    test "#{inspect(ecto_type_module)}: cast a unit struct" do
      assert unquote(ecto_type_module).cast(Cldr.Unit.new!(:meter, 100)) == {:ok, Cldr.Unit.new!(:meter, 100)}
    end

    test "#{inspect(ecto_type_module)}: cast a map with string keys and values" do
      assert unquote(ecto_type_module).cast(%{"unit" => "meter", "value" => "100", "usage" => "default"}) ==
               {:ok, Cldr.Unit.new!(:meter, Decimal.new(100))}
    end

    test "#{inspect(ecto_type_module)}: cast a map with string keys and numeric value" do
      assert unquote(ecto_type_module).cast(%{"unit" => "meter", "value" => 100, "usage" => "default"}) ==
               {:ok, Cldr.Unit.new!(:meter, Decimal.new(100))}
    end

    test "#{inspect(ecto_type_module)}: cast a map with string keys, atom unit, and string value" do
      assert unquote(ecto_type_module).cast(%{"unit" => :meter, "value" => "100", "usage" => "default"}) ==
               {:ok, Cldr.Unit.new!(Decimal.new(100), :meter)}
    end

    test "#{inspect(ecto_type_module)}: cast a map with string keys, atom unit, and numeric value" do
      assert unquote(ecto_type_module).cast(%{"unit" => :meter, "value" => 100, "usage" => "default"}) ==
               {:ok, Cldr.Unit.new!(Decimal.new(100), :meter)}
    end

    test "#{inspect(ecto_type_module)}: cast a map with string keys and invalid unit" do
      assert unquote(ecto_type_module).cast(%{"unit" => "AAA", "value" => 100, "usage" => "default"}) ==
               {:error, [message: "Unknown unit was detected at \"AAA\""]}
    end

    test "#{inspect(ecto_type_module)}: cast a map with atom keys and values" do
      assert unquote(ecto_type_module).cast(%{unit: "meter", value: "100", usage: :default}) ==
               {:ok, Cldr.Unit.new!(Decimal.new(100), :meter)}
    end

    test "#{inspect(ecto_type_module)}: cast a map with atom keys and numeric value" do
      assert unquote(ecto_type_module).cast(%{unit: "meter", value: 100, usage: :default}) ==
               {:ok, Cldr.Unit.new!(Decimal.new(100), :meter)}
    end

    test "#{inspect(ecto_type_module)}: cast a map with atom keys, atom unit, and numeric value" do
      assert unquote(ecto_type_module).cast(%{unit: :meter, value: 100, usage: :default}) ==
               {:ok, Cldr.Unit.new!(Decimal.new(100), :meter)}
    end

    test "#{inspect(ecto_type_module)}: cast a map with atom keys, atom unit, and string value" do
      assert unquote(ecto_type_module).cast(%{unit: :meter, value: "100", usage: :default}) ==
               {:ok, Cldr.Unit.new!(Decimal.new(100), :meter)}
    end

    test "#{inspect(ecto_type_module)}: cast a map with atom keys and invalid unit" do
      assert unquote(ecto_type_module).cast(%{unit: "AAA", value: 100, usage: :default}) ==
               {:error, [message: "Unknown unit was detected at \"AAA\""]}
    end

    test "#{inspect(ecto_type_module)}: cast anything else is an error" do
      assert unquote(ecto_type_module).cast(:atom) == :error
    end
  end
end
