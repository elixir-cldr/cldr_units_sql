DROP AGGREGATE IF EXISTS sum(cldr_unit);


DROP FUNCTION IF EXISTS unit_state_function(agg_state cldr_unit, unit cldr_unit);


DROP AGGREGATE IF EXISTS sum(cldr_unit_with_usage);


DROP FUNCTION IF EXISTS unit_state_function(agg_state cldr_unit_with_usage, unit cldr_unit_with_usage);
