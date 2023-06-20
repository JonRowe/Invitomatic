defmodule Invitomatic.Invites do
  @moduledoc """
  The Invites context.
  """

  import Ecto.Query, warn: false

  alias Invitomatic.Accounts
  alias Invitomatic.Invites.Guest
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
  Returns an `%Ecto.Changeset{}` for tracking guest rsvp changes.

  ## Examples

      iex> change_rsvp(guest, %{})
      %Ecto.Changeset{data: %Guest{}}

  """
  def change_guest(%Guest{} = guest, attrs \\ %{}) do
    Guest.changeset(guest, attrs)
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
      {:ok, %Guest{}}

      iex> delete_guest(invite, guest)
      {:error, %Ecto.Changeset{}}

  """
  def delete_guest(%Invite{} = invite, guest_id) do
    with %Guest{} = guest <- get_guest(invite, guest_id) do
      Repo.delete(guest)
    else
      _ -> {:error, Ecto.Changeset.add_error(Ecto.Changeset.change(%Guest{}), :invite, "did not match", [])}
    end
  end

  @doc """
  Sends an invite email.
  """
  def deliver_invite(%Invite{} = invite, url_fun) when is_function(url_fun, 1) do
    for %Accounts.Login{} = login <- invite.logins do
      Accounts.deliver_invite(login, url_fun)
    end

    Repo.update(Ecto.Changeset.change(invite, sent_at: NaiveDateTime.truncate(NaiveDateTime.utc_now(), :second)))
  end

  @doc """
  Returns an invite with guests and logins preloaded.
  """
  def get(id) do
    guests =
      from(g in Guest, preload: [:starter_menu_option, :main_menu_option, :dessert_menu_option], order_by: g.inserted_at)

    Repo.one(from invite in Invite, where: invite.id == ^id, preload: [:logins, guests: ^guests])
  end

  @doc """
  Returns an invite with guests and logins preloaded for a relation, convience funciton
  to hide details of the primary key.
  """
  def get_for(%_{invite_id: id}), do: get(id)

  @doc """

  ## Examples

      iex> get_guest(invite, guest_id)
      %Guest{}

      iex> get_guest(invite, missing_guest_id)
      nil
  """
  def get_guest(%Invite{id: invite_id}, id) do
    Repo.one(
      from(guest in Guest,
        where: guest.invite_id == ^invite_id and guest.id == ^id,
        preload: [:starter_menu_option, :main_menu_option, :dessert_menu_option]
      )
    )
  end

  @doc """
  Returns the list of invites with guests and logins.

  ## Examples

      iex> list()
      [%Invite{}, ...]

  """
  def list do
    Repo.all(from invite in Invite, preload: [:guests, :logins], order_by: :inserted_at)
  end

  @doc """
  Updates a guest.

  ## Examples

      iex> update_guest(guest, %{rsvp: :yes})
      {:ok, %Guest{}}

      iex> update_guest(guest, %{rsvp: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_guest(guest, attrs) do
    Repo.update(change_guest(guest, attrs))
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
