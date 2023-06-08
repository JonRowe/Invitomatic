defmodule Invitomatic.Content.Section do
  use Ecto.Schema

  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "content" do
    field :type, Ecto.Enum, values: [:invitation, :rsvp, :other, :stylesheet], source: :section, default: :other
    field :text, :string, default: ""

    timestamps()
  end

  @doc false
  def changeset(section, attrs) do
    section
    |> cast(attrs, [:text, :type])
    |> validate_required([:text, :type])
  end
end
