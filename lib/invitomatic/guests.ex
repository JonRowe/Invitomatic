defmodule Invitomatic.Guests do
  @moduledoc """
  The Guests context.
  """

  import Ecto.Query, warn: false

  alias Invitomatic.Accounts.Login, as: Guest
  alias Invitomatic.Repo

  ## Database getters

  @doc """
  Lists guests.

  ## Examples

      iex> list()
      [%Login{}]

  """
  def list do
    Repo.all(Guest)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking guest changes.

  ## Examples

      iex> change(guest)
      %Ecto.Changeset{data: %Guest{}}

  """
  def change(%Guest{} = guest, attrs \\ %{}) do
    Guest.registration_changeset(guest, attrs)
  end

  @doc """
  Creates a guest.

  ## Examples

      iex> create(%{field: value})
      {:ok, %Guest{}}

      iex> create(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create(attrs \\ %{}) do
    %Guest{}
    |> Guest.registration_changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Deletes a guest.

  ## Examples

      iex> delete(guest)
      {:ok, %Guest{}}

      iex> delete(guest)
      {:error, %Ecto.Changeset{}}

  """
  def delete(%Guest{} = guest) do
    Repo.delete(guest)
  end

  @doc """
  Updates a guest.

  ## Examples

      iex> update(guest, %{field: new_value})
      {:ok, %Guest{}}

      iex> update(guest, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update(%Guest{} = guest, attrs) do
    guest
    |> Guest.registration_changeset(attrs)
    |> Repo.update()
  end
end
