defmodule Invitomatic.MenuTest do
  use Invitomatic.DataCase, async: true

  alias Invitomatic.Menu
  alias Invitomatic.Menu.Option

  import Invitomatic.MenuFixtures

  @invalid_option_attrs %{name: nil}

  describe "add_option/1" do
    test "with valid data creates a menu option" do
      valid_attrs = %{age_group: :adult, course: :main, name: "some name", order: 2}

      assert {:ok, %Option{} = option} = Menu.add_option(valid_attrs)
      assert option.name == "some name"
      assert option.order == 2
    end

    test "with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Menu.add_option(@invalid_option_attrs)
    end
  end

  describe "change_option/1" do
    test "returns a changeset" do
      option = menu_option_fixture()
      assert %Ecto.Changeset{} = Menu.change_option(option)
    end
  end

  describe "delete_option/1" do
    test "deletes the menu option" do
      option = menu_option_fixture()
      assert {:ok, %Option{}} = Menu.delete_option(option)
      assert_raise Ecto.NoResultsError, fn -> Menu.get_option!(option.id) end
    end
  end

  describe "get_option!/1" do
    test "returns the menu option with given id" do
      option = menu_option_fixture()
      assert Menu.get_option!(option.id) == option
    end
  end

  describe "list/0" do
    test "returns all menu options" do
      option_four = menu_option_fixture(course: :dessert, age_group: :child,  order: 1)
      option_three = menu_option_fixture(course: :dessert, age_group: :adult,  order: 1)
      option_two = menu_option_fixture(course: :main, age_group: :adult, order: 2)
      option_one = menu_option_fixture(course: :main, age_group: :adult, order: 1)

      assert Menu.list() == [option_one, option_two, option_three, option_four]
    end
  end

  describe "update_option/2" do
    test "with valid data updates the menu option" do
      option = menu_option_fixture()
      update_attrs = %{name: "some updated name"}

      assert {:ok, %Option{} = option} = Menu.update_option(option, update_attrs)
      assert option.name == "some updated name"
    end

    test "with invalid data returns error changeset" do
      option = menu_option_fixture()
      assert {:error, %Ecto.Changeset{}} = Menu.update_option(option, @invalid_option_attrs)
      assert option == Menu.get_option!(option.id)
    end
  end
end
