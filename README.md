# Introduction to Cldr Units SQL
![Build Status](http://sweatbox.noexpectations.com.au:8080/buildStatus/icon?job=cldr_units_sql)
[![Hex pm](http://img.shields.io/hexpm/v/ex_cldr_units_sql.svg?style=flat)](https://hex.pm/packages/ex_cldr_units_sql)
[![License](https://img.shields.io/badge/license-Apache%202-blue.svg)](https://github.com/elixir-cldr/cldr_units_sql/blob/master/LICENSE)

`ex_cldr_units_sql` implements a set of functions to store and retrieve data structured as a `Cldr.Unit.t()` type that represents a unit of measure and a value. See [ex_cldr_units](https://hex.pm/packages/ex_cldr_units) for details of using `Cldr.Unit`.  Note that `ex_cldr_units_sql` depends on `ex_cldr_units`.

## Prerequisities

* `ex_cldr_units_sql` is supported on Elixir 1.11 and later only.

> #### Make sure the Ecto type and the database type match! {: .warning}
>
> It's important that the Ecto type `Cldr.Unit.Ecto.Composite.Type` is matched with the correct database type in the migration: `:cldr_unit` or `:cldr_unit_with_usage`.  Similarly `Cldr.Unit.Ecto.Map.Type` must be matched with the database type `map()` in the migration.

## Serializing to a Postgres database with Ecto

`ex_cldr_units_sql` provides custom Ecto data types and two custom Postgres data types to provide serialization of `Cldr.Unit.t` types without losing precision whilst also maintaining the integrity of the `{unit, value}` relationship.  To serialise and retrieve unit types from a database the following steps should be followed:

1. First generate the migration to create the custom type:

```elixir
mix units.gen.postgres.cldr_units_migration
* creating priv/repo/migrations
* creating priv/repo/migrations/20161007234652_add_cldr_unit_type_to_postgres.exs
```

2. Then migrate the database:

```elixir
mix ecto.migrate
21:01:29.527 [info]  == Running 20200517121207 Cldr.Unit.SQL.Repo.Migrations.AddCldrUnitTypeToPostgres.up/0 forward

21:01:29.529 [info]  execute "CREATE TYPE public.cldr_unit AS (unit varchar, value numeric);"

21:01:29.532 [info]  execute "CREATE TYPE public.cldr_unit_with_usage AS (unit varchar, value numeric, usage varchar);"

21:01:29.546 [info]  == Migrated 20200517121207 in 0.0s
```

3. Create your database migration with the new type (don't forget to `mix ecto.migrate` as well):

```elixir
defmodule Cldr.Unit.Repo.Migrations.CreateProduct do
  use Ecto.Migration

  def change do
    create table(:products) do
      add :weight, :cldr_unit
      add :length, :cldr_unit_with_usage
      timestamps()
    end
  end
end
```

4. Create your schema using the `Cldr.Unit.Ecto.Composite.Type` ecto type:

```elixir
defmodule Product do
  use Ecto.Schema

  schema "products" do
    field :weight, Cldr.Unit.Ecto.Composite.Type
    field :length, Cldr.UnitWithUsage.Ecto.Composite.Type

    timestamps()
  end
end
```

5. Insert into the database:

```elixir
iex> Repo.insert %Product{weight: Cldr.Unit.new(:kilogram, Decimal.new(100))}
[debug] QUERY OK db=4.5ms
INSERT INTO "products" ("value","inserted_at","updated_at") VALUES ($1,$2,$3)
[{"meter", #Decimal<100>}, {{2016, 10, 7}, {23, 12, 13, 0}}, {{2016, 10, 7}, {23, 12, 13, 0}}]
```

6. Retrieve from the database:

```elixir
iex> Repo.all Product
[debug] QUERY OK source="products" db=5.3ms decode=0.1ms queue=0.1ms
SELECT p0."amount", p0."inserted_at", p0."updated_at" FROM "products" AS p0 []
[%Product{__meta__: #Ecto.Schema.Metadata<:loaded, "products">, weight: #Cldr.Unit<:meter, 100>,
  inserted_at: ~N[2017-02-21 00:15:40.979576],
  updated_at: ~N[2017-02-21 00:15:40.991391]}]
```

## Serializing to a MySQL (or other non-Postgres) database with Ecto

Since MySQL does not support composite types, the `:map` type is used which in MySQL is implemented as a `JSON` column.  The currency code and amount are serialised into this column.
```elixir
defmodule Cldr.Unit.Repo.Migrations.CreateProduct do
  use Ecto.Migration

  def change do
    create table(:products) do
      add :weight_map, :map
      add :length_map, :map
      timestamps()
    end
  end
end
```

Create your schema using the `Cldr.Unit.Ecto.Map.Type` ecto type:
```elixir
defmodule Product do
  use Ecto.Schema

  schema "products" do
    field :weight_map, Cldr.Unit.Ecto.Map.Type
    field :length_map, Cldr.UnitWithUsage.Ecto.Map.Type

    timestamps()
  end
end
```

Insert into the database:
```elixir
iex> Repo.insert %Product{weight_map: Cldr.Unit.new!(:kilogram, 100)}
[debug] QUERY OK db=25.8ms
INSERT INTO "products" ("weight_map","inserted_at","updated_at") VALUES ($1,$2,$3)
RETURNING "id" [%{value: "100", unit: "kilogram"},
{{2017, 2, 21}, {0, 15, 40, 979576}}, {{2017, 2, 21}, {0, 15, 40, 991391}}]

{:ok,
 %Product{__meta__: #Ecto.Schema.Metadata<:loaded, "products">,
  amount: nil, weight_map: #Cldr.Unit<:kilogram, 100>, id: 3,
  inserted_at: ~N[2017-02-21 00:15:40.979576],
  updated_at: ~N[2017-02-21 00:15:40.991391]}}
```

Retrieve from the database:
```elixir
iex> Repo.all Product
[debug] QUERY OK source="products" db=16.1ms decode=0.1ms
SELECT t0."id", t0."weight_map", t0."inserted_at", t0."updated_at" FROM "products" AS t0 []
[%Ledger{__meta__: #Ecto.Schema.Metadata<:loaded, "products">,
  weight_map: #Cldr.Unit<:kilogram, 100>, id: 3,
  inserted_at: ~N[2017-02-21 00:15:40.979576],
  updated_at: ~N[2017-02-21 00:15:40.991391]}]
```

### Notes:

1.  In order to preserve precision of the decimal amount, the amount part of the `Cldr.Unit.t()` struct is serialised as a string. This is done because JSON serializes numeric values as either `integer` or `float`, neither of which would preserve precision of a decimal value.

2.  The precision of the serialized string value is affected by the setting of `Decimal.get_context`.  The default is 28 digits which should cater for your requirements.

3.  Serializing the amount as a string means that SQL query arithmetic and equality operators will not work as expected.  You may find that `CAST`ing the string value will restore some of that functionality.  For example:

```sql
CAST(JSON_EXTRACT(amount_map, '$.value') AS DECIMAL(20, 8)) AS amount;
```

## Postgres Database functions

Since the datatype used to store `Cldr.Unit` in Postgres is a composite type (called `:cldr_unit`), the standard aggregation functions like `sum` and `average` are not supported and the `order_by` clause doesn't perform as expected.  `ex_cldr_units_sql` provides mechanisms to provide these functions.

### Aggregate functions: sum()

`ex_cldr_unit_sql` provides a migration generator which, when migrated to the database with `mix ecto.migrate`, supports performing `sum()` aggregation on `:cldr_unit` types. The steps are:

1. Generate the migration by executing `mix units.gen.postgres.aggregate_functions`

2. Migrate the database by executing `mix ecto.migrate`

3. Formulate an Ecto query to use the aggregate function `sum()`

```elixir
  # Formulate the query.  Note the required use of the type()
  # expression which is needed to inform Ecto of the return
  # type of the function
  iex> q = Ecto.Query.select Product, [p], type(sum(p.weight), p.weight)
  #Ecto.Query<from p in Product select: type(sum(p.weight), p.weight)>
  iex> Repo.all q
  [debug] QUERY OK source="products" db=6.1ms
  SELECT sum(p0."weight")::cldr_unit_with_usage FROM "products" AS l0 []
  [#Cldr.Unit<:meter, 600>]
```

The function `Repo.aggregate/3` can also be used. However at least [ecto version 3.2.4](https://hex/pm/packages/ecto/3.2.4) is required for this to work correctly for custom ecto types such as `:cldr_unit`.

```elixir
  iex> Repo.aggregate(Product, :sum, :weight)
  #Cldr.Unit<:kilogram, 100>
```

**Note** that to preserve the integrity of `Cldr.Unit` it is not permissible to aggregate units that has different unit types.  If you attempt to aggregate unit with different unit types the query will abort and an exception will be raised:
```elixir
  iex> Repo.all q
  [debug] QUERY ERROR source="products" db=4.5ms
  SELECT sum(p0."weight")::cldr_unit_with_usage FROM "products" AS p0 []
  ** (Postgrex.Error) ERROR 22033 (): Incompatible units. Expected all units to be :kilogram
```

### Order_by with cldr_unit type

Since `:cldr_unit` is a composite type, the default `order_by` results may surprise since the ordering is based upon the type structure, not the unit value.  Postgres defines a means to access the components of a composite type and therefore sorting can be done in a more predictable fashion.  For example:
```elixir
  # In this example we are decomposing the the composite column called
  # `price` and using the sub-field `value` to perform the ordering.
  iex> q = from p in Product, select: p.weight, order_by: fragment("value(weight)")
  #Ecto.Query<from p in Product, order_by: [asc: fragment("value(weight)")],
   select: p.weight>
  iex> Repo.all q
  [debug] QUERY OK source="products" db=2.0ms
  SELECT p0."weight" FROM "products" AS p0 ORDER BY value(weight) []
  [#Cldr.Unit<:kilogram, 100>, #Cldr.Unit<:pound, 200>,
   #Cldr.Unit<:pound, 300>, #Cldr.Unit<:kilogram, 300>]
```
**Note** that the results may still be unexpected.  The example above shows the correct ascending ordering by `value(weight)` however the ordering is not unit aware and therefore mixed units will return a largely meaningless order.

## Installation

`ex_cldr_units_sql` can be installed by adding `ex_cldr_units_sql` to your list of dependencies in `mix.exs` and then executing `mix deps.get`

```elixir
def deps do
  [
    {:ex_cldr_units_sql, "~> 0.3"},
    ...
  ]
end
```
