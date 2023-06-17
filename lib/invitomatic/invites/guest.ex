defmodule Invitomatic.Invites.Guest do
  use Ecto.Schema

  import Ecto.Changeset

  alias Invitomatic.Invites.Invite

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "guest" do
    belongs_to :invite, Invite
    belongs_to :starter_menu_option, Invitomatic.Menu.Option
    belongs_to :main_menu_option, Invitomatic.Menu.Option
    belongs_to :dessert_menu_option, Invitomatic.Menu.Option

    field :name, :string
    field :age, Ecto.Enum, values: [:adult, :child, :under_three]
    field :rsvp, Ecto.Enum, values: [:yes, :no, :maybe]
    field :dietary_requirements, :string, default: ""

    timestamps()
  end

  @doc false
  def changeset(guest, attrs) do
    guest
    |> cast(attrs, [
      :name,
      :age,
      :rsvp,
      :dietary_requirements,
      :starter_menu_option_id,
      :main_menu_option_id,
      :dessert_menu_option_id
    ])
    |> cast_assoc(:starter_menu_option)
    |> cast_assoc(:main_menu_option)
    |> cast_assoc(:dessert_menu_option)
    |> validate_required([:name, :age])
  end

  def enum_options(field) do
    __MODULE__
    |> Ecto.Enum.values(field)
    |> Enum.map(&{String.capitalize(String.replace(to_string(&1), "_", " ")), &1})
  end
end
