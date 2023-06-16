defmodule InvitomaticWeb.Live.MenuManagerTest do
  use InvitomaticWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import Invitomatic.AccountsFixtures
  import Invitomatic.MenuFixtures

  @create_attrs %{age_group: :adult, course: :main, name: "Main"}
  @update_attrs %{name: "Vegan"}
  @invalid_attrs %{name: ""}

  describe "managing menu options" do
    setup do
      %{option: menu_option_fixture()}
    end

    test "renders the index table", %{conn: conn} do
      menu_option_fixture(name: "Very Tasty", order: 2)
      menu_option_fixture(name: "The main menu", order: 1)
      menu_option_fixture(name: "Strangely Satisfying", course: :dessert, order: 1)
      menu_option_fixture(name: "Strangely Satisfying", age_group: :child, course: :dessert, order: 1)

      {:ok, view, html} =
        conn
        |> log_in(admin_fixture())
        |> live(~p"/manage/menu")

      assert html =~ "Menu Options"

      [row_one, row_two, _, row_three, row_four | _] = render_rows(view)

      assert row_one =~ "The main menu | main | adult | 1"
      assert row_two =~ "Very Tasty | main | adult | 2"
      assert row_three =~ "Strangely Satisfying | dessert | adult | 1"
      assert row_four =~ "Strangely Satisfying | dessert | child | 1"
    end

    test "redirects if not an admin", %{conn: conn} do
      assert {:error, redirect} = live(log_in(conn, login_fixture()), ~p"/manage/menu")

      assert {:redirect, %{to: path, flash: flash}} = redirect
      assert path == ~p"/"
      assert %{"error" => "You cannot access this page."} = flash
    end

    test "redirects if not logged in", %{conn: conn} do
      assert {:error, redirect} = live(conn, ~p"/manage/menu")

      assert {:redirect, %{to: path, flash: flash}} = redirect
      assert path == ~p"/log_in"
      assert %{"error" => "You must log in to access this page."} = flash
    end

    test "it can display a menu option", %{conn: conn, option: option} do
      {:ok, index_live, _html} = live(log_in(conn, admin_fixture()), ~p"/manage/menu")

      index_live
      |> element("#option-#{option.id} td:last-child a", "Show")
      |> render_click()

      html = render(element(index_live, "#option-modal"))

      assert html =~ option.name
      assert html =~ to_string(option.order)
    end

    test "it can add a new option", %{conn: conn} do
      {:ok, index_live, _html} = live(log_in(conn, admin_fixture()), ~p"/manage/menu")

      assert index_live |> element("a", "New Option") |> render_click() =~
               "New Option"

      assert_patch(index_live, ~p"/manage/menu/new")

      assert index_live
             |> form("#option-form", option: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert index_live
             |> form("#option-form", option: @create_attrs)
             |> render_submit()

      assert_patch(index_live, ~p"/manage/menu")

      html = render(index_live)
      assert html =~ "Option created successfully"
    end

    test "it can edit an option", %{conn: conn, option: option} do
      {:ok, index_live, _html} = live(log_in(conn, admin_fixture()), ~p"/manage/menu")

      assert index_live |> element("#option-#{option.id} a", "Edit") |> render_click() =~
               "Edit Option"

      assert_patch(index_live, ~p"/manage/menu/#{option}/edit")

      assert index_live
             |> form("#option-form", option: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert index_live
             |> form("#option-form", option: @update_attrs)
             |> render_submit()

      assert_patch(index_live, ~p"/manage/menu")

      html = render(index_live)
      assert html =~ "Option updated successfully"
    end

    test "it can edit an option from a modal", %{conn: conn, option: option} do
      {:ok, index_live, _html} = live(log_in(conn, admin_fixture()), ~p"/manage/menu")

      index_live
      |> element("#option-#{option.id} td:last-child a", "Show")
      |> render_click()

      assert index_live |> element("#option-modal-container a", "Edit") |> render_click() =~
               "Edit Option"

      assert_patch(index_live, ~p"/manage/menu/#{option}")

      assert index_live
             |> form("#option-form", option: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert index_live
             |> form("#option-form", option: @update_attrs)
             |> render_submit()

      assert_patch(index_live, ~p"/manage/menu/#{option}")

      html = render(index_live)
      assert html =~ "Option updated successfully"
    end

    test "it can delete an option", %{conn: conn, option: option} do
      {:ok, index_live, _html} = live(log_in(conn, admin_fixture()), ~p"/manage/menu")

      assert index_live |> element("#option-#{option.id} a", "Delete") |> render_click()
      refute has_element?(index_live, "#option-#{option.id}")
    end
  end

  defp render_rows(view) do
    [{"tbody", _, rows}] = Floki.parse_fragment!(render(element(view, "tbody")))
    Enum.map(rows, &String.trim(String.replace(Floki.text(&1, sep: " | "), ~r/\s+/, " ")))
  end
end
