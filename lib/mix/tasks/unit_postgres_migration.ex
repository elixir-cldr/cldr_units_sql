if Code.ensure_loaded?(Ecto) do
  defmodule Mix.Tasks.Units.Gen.Postgres.CldrUnitsMigration do
    use Mix.Task

    import Macro, only: [camelize: 1, underscore: 1]
    import Mix.Generator
    import Mix.Ecto, except: [migrations_path: 1]
    import Cldr.Unit.Migration

    @shortdoc "Generates a migration to create the :cldr_unit composite " <>
                "database type for Postgres"

    @moduledoc """
    Generates a migration to add a composite type called `:money_with_currency`
    to a Postgres database.

    The `:money_with_currency` type created is a composite type and
    therefore may not be supported in other databases.
    """

    @doc false
    @dialyzer {:no_return, run: 1}

    def run(args) do
      no_umbrella!("units.gen.cldr_unit")
      repos = parse_repo(args)
      name = "add_cldr_unit_type_to_postgres"

      Enum.each(repos, fn repo ->
        ensure_repo(repo, args)
        path = Path.relative_to(migrations_path(repo), Mix.Project.app_path())
        file = Path.join(path, "#{timestamp()}_#{underscore(name)}.exs")
        create_directory(path)

        assigns = [mod: Module.concat([repo, Migrations, camelize(name)])]

        content =
          assigns
          |> migration_template
          |> format_string!

        create_file(file, content)

        if open?(file) and Mix.shell().yes?("Do you want to run this migration?") do
          Mix.Task.run("ecto.migrate", [repo])
        end
      end)
    end

    defp timestamp do
      {{y, m, d}, {hh, mm, ss}} = :calendar.universal_time()
      "#{y}#{pad(m)}#{pad(d)}#{pad(hh)}#{pad(mm)}#{pad(ss)}"
    end

    defp pad(i) when i < 10, do: <<?0, ?0 + i>>
    defp pad(i), do: to_string(i)

    embed_template(:migration, """
    defmodule <%= inspect @mod %> do
      use Ecto.Migration

      def up do
        <%= Money.DDL.execute(Money.DDL.create_cldr_unit) %>
      end

      def down do
        <%= Money.DDL.execute(Money.DDL.drop_cldr_unit) %>
      end
    end
    """)
  end
end
