defmodule Invitomatic.MenuFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Invitomatic.FoodChoices` context.
  """

  @doc """
  Generate a menu option
  """
  def menu_option_fixture(attrs \\ %{}) do
    {:ok, option} =
      attrs
      |> Enum.into(%{
        age_group: :adult,
        course: :main,
        name: "some name"
      })
      |> Invitomatic.Menu.add_option()

    option
  end
end
