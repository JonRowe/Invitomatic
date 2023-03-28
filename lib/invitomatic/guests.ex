defmodule Invitomatic.Guests do
  @moduledoc """
  The Guests context.
  """

  import Ecto.Query, warn: false

  alias Invitomatic.Accounts.Login, as: Guest
  alias Invitomatic.Repo

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
end
