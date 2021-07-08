defmodule Cldr.Unit.SQL.Test do
  use Cldr.Unit.SQL.RepoCase

  test "insert a record with a unit value" do
    m = Cldr.Unit.new!(:meter, 100)
    Repo.insert(%Product{weight: m})
    assert {:ok, struct} = Repo.insert(%Product{weight: m})
    assert Cldr.Unit.compare(m, struct.weight) == :eq
  end

  test "select aggregate function sum on a :cldr_unit type" do
    m = Cldr.Unit.new!(:meter, 100, usage: :person)
    {:ok, _} = Repo.insert(%Product{weight: m})
    {:ok, _} = Repo.insert(%Product{weight: m})
    {:ok, _} = Repo.insert(%Product{weight: m})
    sum = select(Product, [o], type(sum(o.weight), o.weight)) |> Repo.one
    assert Cldr.Unit.compare(sum, Cldr.Unit.new!(:meter, Decimal.new(300))) == :eq

    {:ok, _} = Repo.insert(%Product{length: m})
    {:ok, _} = Repo.insert(%Product{length: m})
    {:ok, _} = Repo.insert(%Product{length: m})
    sum = select(Product, [o], type(sum(o.length), o.length)) |> Repo.one
    assert Cldr.Unit.compare(sum, Cldr.Unit.new!(:meter, Decimal.new(300))) == :eq
    assert sum.usage == :person
  end

  test "Repo.aggregate function sum on a :cldr_unit type" do
    m = Cldr.Unit.new!(:meter, 100, usage: :person)
    {:ok, _} = Repo.insert(%Product{weight: m})
    {:ok, _} = Repo.insert(%Product{weight: m})
    {:ok, _} = Repo.insert(%Product{weight: m})
    sum = Repo.aggregate(Product, :sum, :weight)
    assert Cldr.Unit.compare(sum, Cldr.Unit.new!(:meter, Decimal.new(300))) == :eq

    {:ok, _} = Repo.insert(%Product{length: m})
    {:ok, _} = Repo.insert(%Product{length: m})
    {:ok, _} = Repo.insert(%Product{length: m})
    sum = Repo.aggregate(Product, :sum, :length)
    assert Cldr.Unit.compare(sum, Cldr.Unit.new!(:meter, Decimal.new(300))) == :eq
    assert sum.usage == :person
  end

  test "Exception is raised if trying to sum different units" do
    m = Cldr.Unit.new!(:meter, 100)
    m2 = Cldr.Unit.new!(:foot, 100)
    {:ok, _} = Repo.insert(%Product{weight: m})
    {:ok, _} = Repo.insert(%Product{weight: m})
    {:ok, _} = Repo.insert(%Product{weight: m2})
    assert_raise Postgrex.Error, fn ->
      Repo.aggregate(Product, :sum, :weight)
    end

    {:ok, _} = Repo.insert(%Product{length: m})
    {:ok, _} = Repo.insert(%Product{length: m})
    {:ok, _} = Repo.insert(%Product{length: m2})
    assert_raise Postgrex.Error, fn ->
      Repo.aggregate(Product, :sum, :length)
    end
  end

  test "select distinct aggregate function sum on a :cldr_unit type" do
    m = Cldr.Unit.new!(:meter, 100, usage: :person)
    {:ok, _} = Repo.insert(%Product{weight: m})
    {:ok, _} = Repo.insert(%Product{weight: m})
    {:ok, _} = Repo.insert(%Product{weight: m})
    {:ok, _} = Repo.insert(%Product{weight: Cldr.Unit.new!(:meter, 200, usage: :person)})

    query = select(Product, [o], type(fragment("SUM(DISTINCT ?)", o.weight), o.weight))
    sum = query |> Repo.one
    assert Cldr.Unit.compare(sum, Cldr.Unit.new!(:meter, Decimal.new(300))) == :eq

    {:ok, _} = Repo.insert(%Product{length: m})
    {:ok, _} = Repo.insert(%Product{length: m})
    {:ok, _} = Repo.insert(%Product{length: m})
    {:ok, _} = Repo.insert(%Product{length: Cldr.Unit.new!(:meter, 200, usage: :person)})

    query = select(Product, [o], type(fragment("SUM(DISTINCT ?)", o.length), o.length))
    sum = query |> Repo.one
    assert Cldr.Unit.compare(sum, Cldr.Unit.new!(:meter, Decimal.new(300))) == :eq
    assert sum.usage == :person
  end

  test "select distinct aggregate function sum on a :cldr_unit_with_usage type" do
    m = Cldr.Unit.new!(:meter, 100)
    {:ok, _} = Repo.insert(%Product{length: m})
    {:ok, _} = Repo.insert(%Product{length: m})
    {:ok, _} = Repo.insert(%Product{length: m})
    {:ok, _} = Repo.insert(%Product{length: Cldr.Unit.new!(:meter, 200)})

    query = select(Product, [o], type(fragment("SUM(DISTINCT ?)", o.length), o.length))
    sum = query |> Repo.one
    assert Cldr.Unit.compare(sum, Cldr.Unit.new!(:meter, Decimal.new(300))) == :eq
  end

  test "inserting a unit with a usage" do
    weight = Cldr.Unit.new!(:meter, 200, usage: :person)
    {:ok, _} = Repo.insert(%Product{length: weight})

    result = select(Product, [o], o.length) |> Repo.one
    assert result.usage == :person
  end

  test "filter on a unit type" do
    m = Cldr.Unit.new!(:meter, 100)
    m2 = Cldr.Unit.new!(:foot, 200)

    {:ok, _} = Repo.insert(%Product{weight: m})
    {:ok, _} = Repo.insert(%Product{weight: m2})
    {:ok, _} = Repo.insert(%Product{weight: m})
    {:ok, _} = Repo.insert(%Product{weight: m2})

    query = from o in Product,
              where: fragment("unit(weight)") == "meter",
              select: sum(o.weight)

    result = query |> Repo.one

    assert result == Cldr.Unit.new!(:meter, Decimal.new(200))
  end

end
