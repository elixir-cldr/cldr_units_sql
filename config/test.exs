use Mix.Config

config :ex_cldr_units_sql, Cldr.Unit.SQL.Repo,
    username: "kip",
    database: "money_dev",
    hostname: "localhost",
    pool: Ecto.Adapters.SQL.Sandbox

config :ex_cldr_units_sql,
  ecto_repos: [Cldr.Unit.SQL.Repo]

config :logger, level: :error
