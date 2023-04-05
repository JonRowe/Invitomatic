defmodule Invitomatic.Invites do
  @moduledoc """
  The Invites context.
  """

  import Ecto.Query, warn: false

  alias Invitomatic.Accounts.Login, as: Guest
  alias Invitomatic.Invites.Guest, as: InviteGuest
  alias Invitomatic.Invites.Invite
  alias Invitomatic.Repo

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking invitation changes.

  ## Examples

      iex> change(invite)
      %Ecto.Changeset{data: %Invite{}}

  """
  def change(%Invite{} = invite, attrs \\ %{}) do
    Invite.changeset(invite, attrs)
  end

  @doc """
  Creates an invite.

  ## Examples

      iex> create(%{name: value})
      {:ok, %Invite{}}

      iex> create(%{name: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create(attrs \\ %{}) do
    attrs_with_primary_login =
      case attrs do
        %{logins: [login]} -> Map.put(attrs, :logins, [Map.put(login, :primary, true)])
        _ -> attrs
      end

    %Invite{}
    |> Invite.changeset(attrs_with_primary_login)
    |> Repo.insert()
  end

  @doc """
  Deletes a guest.

  ## Examples

      iex> delete_guest(invite, guest)
      {:ok, %InviteGuest{}}

      iex> delete_guest(invite, guest)
      {:error, %Ecto.Changeset{}}

  """
  def delete_guest(%Invite{} = invite, guest_id) do
    with %InviteGuest{} = guest <- get_guest(invite, guest_id) do
      Repo.delete(guest)
    else
      _ -> {:error, Ecto.Changeset.add_error(Ecto.Changeset.change(%InviteGuest{}), :invite, "did not match", [])}
    end
  end

  @doc """
  Returns an invite with guests and logins preloaded.
  """
  def get(id) do
    Repo.one(from invite in Invite, where: invite.id == ^id, preload: [:guests, :logins])
  end

  @doc """

  ## Examples

      iex> get_guest(invite, guest_id)
      %InviteGuest{}

      iex> get_guest(invite, missing_guest_id)
      nil
  """
  def get_guest(%Invite{id: invite_id}, id) do
    Repo.one(from(guest in InviteGuest, where: guest.invite_id == ^invite_id and guest.id == ^id))
  end

  @doc """
  Returns the list of guests ordered by invite.

  ## Examples

      iex> list_guests()
      [%Guest{}, ...]

  """
  def list_guests do
    Repo.all(
      from guest in Guest,
        join: invite in assoc(guest, :invite),
        preload: [invite: invite],
        order_by: invite.id
    )
  end

  @doc """
  Updates an invite.

  ## Examples

      iex> update(invite, %{name: new_value})
      {:ok, %Invite{}}

      iex> update(invite, %{name: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update(%Invite{} = invite, attrs) do
    invite
    |> Invite.changeset(attrs)
    |> Repo.update()
  end
end
