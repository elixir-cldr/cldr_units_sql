defmodule Cldr.Unit.SQL.Repo.Migrations.AddPostgresCldrUnitAggregateFunctions do
  use Ecto.Migration

  def up do
    execute("""
    CREATE OR REPLACE FUNCTION unit_state_function(agg_state cldr_unit, unit cldr_unit)
    RETURNS cldr_unit
    IMMUTABLE
    STRICT
    LANGUAGE plpgsql
    AS $$
      DECLARE
        expected_unit varchar;
        aggregate numeric;
        usage varchar;
        addition numeric;
      BEGIN
        if unit(agg_state) IS NULL then
          expected_unit := unit(unit);
          aggregate := 0;
          usage := usage(unit);
        else
          expected_unit := unit(agg_state);
          aggregate := value(agg_state);
          usage := usage(unit);
        end if;

        IF unit(unit) = expected_unit THEN
          addition := aggregate + value(unit);
          return row(expected_unit, addition, usage);
        ELSE
          RAISE EXCEPTION
            'Incompatible units. Expected all unit names to be %', expected_unit
            USING HINT = 'Please ensure all columns have the same unit type',
            ERRCODE = '22033';
        END IF;
      END;
    $$;
    """)

    execute("""
    CREATE AGGREGATE sum(cldr_unit)
    (
      sfunc = unit_state_function,
      stype = cldr_unit
    );
    """)
  end

  def down do
    execute("DROP AGGREGATE IF EXISTS sum(cldr_unit);")
    execute("DROP FUNCTION IF EXISTS unit_state_function(agg_state cldr_unit, unit cldr_unit);")
  end
end