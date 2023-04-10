defmodule Invitomatic.Menu.Option do
  use Ecto.Schema

  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "menu_option" do
    field :description, :string
    field :name, :string
    field :order, :integer

    timestamps()
  end

  @doc false
  def changeset(menu_option, attrs) do
    menu_option
    |> cast(attrs, [:name, :description, :order])
    |> validate_required([:name, :description])
  end
end
