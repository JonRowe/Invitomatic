defmodule Invitomatic.InvitesFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Invitomatic.Invites` context.
  """

  alias Invitomatic.Invites
  alias Invitomatic.Invites.Invite
  alias Invitomatic.Repo

  @doc """
  Generate a guest.
  """
  def guest_fixture(attrs \\ %{}) do
    %Invite{logins: [guest | _]} = invite_fixture(%{logins: [attrs]})
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
  Generate a unique name.
  """
  def unique_name, do: "Bending unit number #{System.unique_integer()}"

  @doc """
  Generate a complete set of valid invite attributes.
  """
  def valid_invite_attributes(attrs \\ %{}) do
    logins =
      attrs
      |> Map.get(:logins, [%{}])
      |> Enum.map(&Invitomatic.AccountsFixtures.valid_login_attributes/1)

    attrs
    |> Map.put(:logins, logins)
    |> Enum.into(%{
      name: unique_name()
    })
  end
end
