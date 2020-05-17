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


CREATE AGGREGATE sum(cldr_unit)
(
  sfunc = unit_state_function,
  stype = cldr_unit
);
