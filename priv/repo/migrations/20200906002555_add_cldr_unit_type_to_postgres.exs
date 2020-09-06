defmodule Cldr.Unit.SQL.Repo.Migrations.AddCldrUnitTypeToPostgres do
  use Ecto.Migration

  def up do
    execute("CREATE TYPE public.cldr_unit AS (unit varchar, value numeric);")

    execute(
      "CREATE TYPE public.cldr_unit_with_usage AS (unit varchar, value numeric, usage varchar);"
    )
  end

  def down do
    execute("DROP TYPE public.cldr_unit;")
    execute("DROP TYPE public.cldr_unit_with_usage;")
  end
end