defmodule Invitomatic.Invites do
  @moduledoc """
  The Invites context.
  """

  import Ecto.Query, warn: false

  alias Invitomatic.Accounts.Login, as: Guest
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
  Returns an invite with guests and logins preloaded.
  """
  def get(id) do
    Repo.one(from invite in Invite, where: invite.id == ^id, preload: [:guests, :logins])
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
