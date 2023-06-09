defmodule Invitomatic.Invites.Guest do
  use Ecto.Schema

  import Ecto.Changeset

  alias Invitomatic.Invites.Invite

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "guest" do
    belongs_to :invite, Invite
    belongs_to :menu_option, Invitomatic.Menu.Option

    field :name, :string
    field :age, Ecto.Enum, values: [:adult, :child, :under_three]
    field :rsvp, Ecto.Enum, values: [:yes, :no, :maybe]

    timestamps()
  end

  @doc false
  def changeset(guest, attrs) do
    guest
    |> cast(attrs, [:name, :age, :rsvp])
    |> cast_assoc(:menu_option)
    |> validate_required([:name, :age])
  end
end
