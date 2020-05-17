defmodule Cldr.Unit.Repo.Migrations.CreateProductTable do
  use Ecto.Migration

  def change do
    create table(:products) do
      add :name,            :string
      add :weight,         :cldr_unit
      timestamps()
    end
  end
end
