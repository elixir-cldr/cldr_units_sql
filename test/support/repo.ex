defmodule Cldr.Unit.SQL.Repo do
  use Ecto.Repo,
    otp_app: :ex_cldr_units_sql,
    adapter: Ecto.Adapters.Postgres

end

