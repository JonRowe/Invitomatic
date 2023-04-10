defmodule Invitomatic.Menu do
  @moduledoc """
  The Menu context.
  """

  import Ecto.Query, warn: false

  alias Invitomatic.Menu.Option
  alias Invitomatic.Repo

  @doc """
  Adds a menu option.

  ## Examples

      iex> add_option(%{field: value})
      {:ok, %Option{}}

      iex> add_option(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def add_option(attrs \\ %{}) do
    %Option{}
    |> Option.changeset(attrs)
    |> Repo.insert(returning: true)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking menu option changes.

  ## Examples

      iex> change_option(menu_option)
      %Ecto.Changeset{data: %Option{}}

  """
  def change_option(%Option{} = option, attrs \\ %{}) do
    Option.changeset(option, attrs)
  end

  @doc """
  Deletes a menu option.

  ## Examples

      iex> delete_option(menu_option)
      {:ok, %Option{}}

      iex> delete_option(menu_option)
      {:error, %Ecto.Changeset{}}

  """
  def delete_option(%Option{} = option) do
    Repo.delete(option)
  end

  @doc """
  Gets a single menu option

  Raises `Ecto.NoResultsError` if the Food choice does not exist.

  ## Examples

      iex> get_option!(123)
      %Option{}

      iex> get_option!(456)
      ** (Ecto.NoResultsError)

  """
  def get_option!(id), do: Repo.get!(Option, id)

  @doc """
  Returns the list of menu options.

  ## Examples

      iex> list()
      [%Option{}, ...]

  """
  def list do
    Repo.all(from option in Option, order_by: option.order)
  end

  @doc """
  Updates a menu option.

  ## Examples

      iex> update_option(menu_option, %{field: new_value})
      {:ok, %Option{}}

      iex> update_option(menu_option, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_option(%Option{} = option, attrs) do
    option
    |> Option.changeset(attrs)
    |> Repo.update()
  end
end
