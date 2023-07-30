defmodule Invitomatic.Invites.Invite do
  use Ecto.Schema

  import Ecto.Changeset

  alias Invitomatic.Accounts.Login
  alias Invitomatic.Invites.Guest

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "invite" do
    field :name, :string
    field :extra_content, Ecto.Enum, values: [:accommodation]
    field :locked, :boolean, default: false
    field :sent_at, :naive_datetime

    has_many :guests, Guest, on_replace: :delete
    has_many :logins, Login
    has_one :primary_login, Login, where: [primary: true]

    timestamps()
  end

  @doc false
  def changeset(invite, attrs), do: changeset_common(invite, attrs, &Guest.changeset/2)

  def enum_options(field) do
    __MODULE__
    |> Ecto.Enum.values(field)
    |> Enum.map(&{String.capitalize(String.replace(to_string(&1), "_", " ")), &1})
  end

  def management_changeset(invite, attrs), do: changeset_common(invite, attrs, &Guest.management_changeset/2)

  defp changeset_common(invite, attrs, guest_with) do
    invite
    |> cast(attrs, [:name, :extra_content, :locked])
    |> validate_required([:name])
    |> cast_assoc(:guests, required: true, with: guest_with)
    |> cast_assoc(:logins, required: true, with: &Login.registration_changeset/2)
  end
end
