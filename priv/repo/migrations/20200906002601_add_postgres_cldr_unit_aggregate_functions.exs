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
        addition numeric;
      BEGIN
        if unit(agg_state) IS NULL then
          expected_unit := unit(unit);
          aggregate := 0;
        else
          expected_unit := unit(agg_state);
          aggregate := value(agg_state);
        end if;

        IF unit(unit) = expected_unit THEN
          addition := aggregate + value(unit);
          return row(expected_unit, addition);
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

    execute("""
    CREATE OR REPLACE FUNCTION unit_with_usage_state_function(agg_state cldr_unit_with_usage, unit cldr_unit_with_usage)
    RETURNS cldr_unit_with_usage
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
    CREATE AGGREGATE sum(cldr_unit_with_usage)
    (
      sfunc = unit_with_usage_state_function,
      stype = cldr_unit_with_usage
    );
    """)
  end

  def down do
    execute("DROP AGGREGATE IF EXISTS sum(cldr_unit);")
    execute("DROP FUNCTION IF EXISTS unit_state_function(agg_state cldr_unit, unit cldr_unit);")
    execute("DROP AGGREGATE IF EXISTS sum(cldr_unit_with_usage);")

    execute(
      "DROP FUNCTION IF EXISTS unit_state_function(agg_state cldr_unit_with_usage, unit cldr_unit_with_usage);"
    )
  end
end