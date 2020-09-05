defmodule Cldr.Unit.SQL.Repo.Migrations.AddCldrUnitTypeToPostgres do
  use Ecto.Migration

  def up do
    execute("CREATE TYPE public.cldr_unit AS (unit varchar, value numeric, usage varchar);")
  end

  def down do
    execute("DROP TYPE public.cldr_unit;")
  end
end