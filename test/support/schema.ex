defmodule Product do
  use Ecto.Schema

  @primary_key false
  schema "products" do
    field :weight, Cldr.Unit.Ecto.Composite.Type
    field :name,   :string
    timestamps()
  end
end