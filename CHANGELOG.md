# Changelog

##  Cldr Units SQL v0.3.0

This is the changelog for Cldr Units SQL v0.3.0 released on June 11th, 2021.  For older changelogs please consult the release tag on [GitHub](https://github.com/elixir-cldr/cldr_units_sql/tags)

### Bug Fixes

* Fix parsing to be independent of Decimal 1.x or Decimal 2.x

##  Cldr Units SQL v0.2.0

This is the changelog for Cldr Units SQL v0.2.0 released on September 6th, 2020.  For older changelogs please consult the release tag on [GitHub](https://github.com/elixir-cldr/cldr_units_sql/tags)

### Enhancements

* Add `:unit_with_usage` type to serialize units including the usage field. This requires more database storage but is a more complete serialization for round tripping unit data. The type modules are `Cldr.UnitWithUsage.Ecto.Composite.Type` and `Cldr.UnitWithUsage.Ecto.Map.Type`.

## Cldr Units SQL v0.1.0

This is the changelog for Cldr Units SQL released on May 17th, 2020.

### Enhancements

* Initial release
