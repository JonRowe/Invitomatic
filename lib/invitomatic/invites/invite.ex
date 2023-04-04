defmodule Invitomatic.Invites.Invite do
  use Ecto.Schema

  import Ecto.Changeset

  alias Invitomatic.Accounts.Login
  alias Invitomatic.Invites.Guest

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "invite" do
    field :name, :string

    has_many :guests, Guest, on_replace: :delete
    has_many :logins, Login
    has_one :primary_login, Login, where: [primary: true]

    timestamps()
  end

  @doc false
  def changeset(invite, attrs) do
    invite
    |> cast(attrs, [:name])
    |> validate_required([:name])
    |> cast_assoc(:guests, required: true)
    |> cast_assoc(:logins, required: true, with: {Login, :registration_changeset, []})
  end
end
