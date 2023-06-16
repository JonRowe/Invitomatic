defmodule Invitomatic.Menu.Option do
  use Ecto.Schema

  alias Invitomatic.Invites.Guest

  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "menu_option" do
    field :age_group, Ecto.Enum, values: Ecto.Enum.values(Guest, :age)
    field :course, Ecto.Enum, values: [:starter, :main, :dessert]
    field :name, :string
    field :order, :integer

    timestamps()
  end

  @doc false
  def changeset(menu_option, attrs) do
    menu_option
    |> cast(attrs, [:age_group, :course, :name, :order])
    |> validate_required([:age_group, :course, :name])
  end

  def enum_options(field) do
    __MODULE__
    |> Ecto.Enum.values(field)
    |> Enum.map(&{String.capitalize(String.replace(to_string(&1), "_", " ")), &1})
  end
end
