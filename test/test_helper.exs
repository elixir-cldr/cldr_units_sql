ExUnit.start()
{:ok, _pid} = Cldr.Unit.SQL.Repo.start_link
:ok = Ecto.Adapters.SQL.Sandbox.mode(Cldr.Unit.SQL.Repo, :manual)

defmodule Cldr.Unit.SQL.RepoCase do
  use ExUnit.CaseTemplate

  using do
    quote do
      alias Cldr.Unit.SQL.Repo

      import Ecto
      import Ecto.Query
      import Cldr.Unit.SQL.RepoCase

      # and any other stuff
    end
  end

  setup tags do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Cldr.Unit.SQL.Repo)

    unless tags[:async] do
      Ecto.Adapters.SQL.Sandbox.mode(Cldr.Unit.SQL.Repo, {:shared, self()})
    end

    :ok
  end


end

