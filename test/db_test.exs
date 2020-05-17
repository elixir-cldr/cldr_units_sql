defmodule Cldr.Unit.DB.Test do
  use Cldr.Unit.SQL.RepoCase

  test "insert a record with a unit value" do
    m = Cldr.Unit.new!(:meter, 100)
    Repo.insert(%Product{weight: m})
    assert {:ok, struct} = Repo.insert(%Product{weight: m})
    assert Cldr.Unit.compare(m, struct.weight) == :eq
  end

  test "select aggregate function sum on a :cldr_unit type" do
    m = Cldr.Unit.new!(:meter, 100)
    {:ok, _} = Repo.insert(%Product{weight: m})
    {:ok, _} = Repo.insert(%Product{weight: m})
    {:ok, _} = Repo.insert(%Product{weight: m})
    sum = select(Product, [o], type(sum(o.weight), o.weight)) |> Repo.one
    assert Cldr.Unit.compare(sum, Cldr.Unit.new!(:meter, Decimal.new(300))) == :eq
  end

  test "Repo.aggregate function sum on a :cldr_unit type" do
    m = Cldr.Unit.new!(:meter, 100)
    {:ok, _} = Repo.insert(%Product{weight: m})
    {:ok, _} = Repo.insert(%Product{weight: m})
    {:ok, _} = Repo.insert(%Product{weight: m})
    sum = Repo.aggregate(Product, :sum, :weight)
    assert Cldr.Unit.compare(sum, Cldr.Unit.new!(:meter, Decimal.new(300))) == :eq
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
  end

  test "select distinct aggregate function sum on a :cldr_unit type" do
    m = Cldr.Unit.new!(:meter, 100)
    {:ok, _} = Repo.insert(%Product{weight: m})
    {:ok, _} = Repo.insert(%Product{weight: m})
    {:ok, _} = Repo.insert(%Product{weight: m})
    {:ok, _} = Repo.insert(%Product{weight: Cldr.Unit.new!(:meter, 200)})

    query = select(Product, [o], type(fragment("SUM(DISTINCT ?)", o.weight), o.weight))
    sum = query |> Repo.one
    assert Cldr.Unit.compare(sum, Cldr.Unit.new!(:meter, Decimal.new(300))) == :eq
  end

  test "filter on a currency type" do
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
