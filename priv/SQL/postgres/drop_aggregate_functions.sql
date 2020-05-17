DROP AGGREGATE IF EXISTS sum(unit);


DROP FUNCTION IF EXISTS unit_state_function(agg_state cldr_unit, unit cldr_unit);
