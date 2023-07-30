defmodule Invitomatic.Invites.Guest do
  use Ecto.Schema

  import Ecto.Changeset

  alias Ecto.Changeset
  alias Invitomatic.Invites.Invite
  alias __MODULE__

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
    |> common_changeset(attrs)
    |> validate_invite_unlocked()
  end

  def enum_options(field) do
    __MODULE__
    |> Ecto.Enum.values(field)
    |> Enum.map(&{String.capitalize(String.replace(to_string(&1), "_", " ")), &1})
  end

  def management_changeset(guest, attrs), do: common_changeset(guest, attrs)

  defp common_changeset(guest, attrs) do
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

  defp validate_invite_unlocked(%Changeset{data: %Guest{invite: %Invite{locked: true}}} = changeset) do
    add_error(changeset, :invite, "is locked")
  end

  defp validate_invite_unlocked(%Changeset{data: %Guest{invite: %Invite{locked: false}}} = changeset), do: changeset
  defp validate_invite_unlocked(%Changeset{data: %Guest{invite_id: nil}} = changeset), do: changeset
end
