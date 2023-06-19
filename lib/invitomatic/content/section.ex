defmodule Invitomatic.Content.Section do
  use Ecto.Schema

  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "content" do
    field :type, Ecto.Enum,
      values: [:invitation, :rsvp, :other, :stylesheet, :accommodation, :email_stylesheet],
      source: :section,
      default: :other

    field :other_index, :integer
    field :slug, :string, default: ""
    field :text, :string, default: ""
    field :title, :string, default: ""

    timestamps()
  end

  @doc false
  def changeset(section, attrs) do
    section
    |> cast(attrs, [:other_index, :slug, :text, :title, :type])
    |> validate_required([:slug, :text, :title, :type])
  end
end
