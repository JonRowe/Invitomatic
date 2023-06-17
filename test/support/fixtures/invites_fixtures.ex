defmodule Invitomatic.InvitesFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Invitomatic.Invites` context.
  """

  alias Invitomatic.Invites
  alias Invitomatic.Invites.Guest
  alias Invitomatic.Invites.Invite
  alias Invitomatic.Repo

  @doc """
  Generate a guest.
  """
  def guest_fixture(attrs \\ %{}) do
    %Invite{guests: [guest | _]} = invite_fixture(%{logins: [attrs]})
    Repo.preload(guest, :invite)
  end

  @doc """
  Generate an invite.
  """
  def invite_fixture(attrs \\ %{}) do
    {:ok, invite} =
      attrs
      |> valid_invite_attributes()
      |> Invites.create()

    invite
  end

  @doc """
  Add a guest to an invite with a special ability to set timestamps
  """
  def add_guest_to_invite_fixture(invite, attrs \\ %{}) do
    %Guest{invite: invite}
    |> Guest.changeset(valid_guest_attributes(attrs))
    |> Ecto.Changeset.cast(attrs, [:inserted_at])
    |> Repo.insert!()
  end

  @doc """
  Generate a unique name.
  """
  def unique_name, do: "Bending unit number #{System.unique_integer()}"

  @doc """
  Generate a complete set of valid guest attributes.
  """
  def valid_guest_attributes(attrs \\ %{}) do
    Enum.into(attrs, %{
      age: :adult,
      name: unique_name(),
      starter_menu_option: nil,
      main_menu_option: nil,
      dessert_menu_option: nil
    })
  end

  @doc """
  Generate a complete set of valid invite attributes.
  """
  def valid_invite_attributes(attrs \\ %{}) do
    guests =
      attrs
      |> Map.get(:guests, [%{}])
      |> Enum.map(&valid_guest_attributes/1)

    logins =
      attrs
      |> Map.get(:logins, [%{}])
      |> Enum.map(&Invitomatic.AccountsFixtures.valid_login_attributes/1)

    attrs
    |> Map.put(:guests, guests)
    |> Map.put(:logins, logins)
    |> Enum.into(%{
      name: unique_name()
    })
  end
end
