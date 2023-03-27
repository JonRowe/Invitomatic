defmodule InvitomaticWeb.Live.InvitationManagerTest do
  use InvitomaticWeb.ConnCase

  import Phoenix.LiveViewTest
  import Invitomatic.AccountsFixtures

  @guest_create_attrs %{"email" => "another@example.com"}
  @guest_update_attrs %{"email" => "new@example.com"}
  @guest_invalid_attrs %{"email" => ""}

  describe "Management page" do
    setup do
      %{guest: guest_fixture()}
    end

    test "renders the index table", %{conn: conn} do
      guest_fixture(email: "invitee_1@example.com")
      guest_fixture(email: "invitee_2@example.com")

      {:ok, _lv, html} =
        conn
        |> log_in(admin_fixture())
        |> live(~p"/manage")

      assert html =~ "Invitation Management"
      assert html =~ "invitee_1@example.com"
      assert html =~ "invitee_2@example.com"
    end

    test "redirects if not an admin", %{conn: conn} do
      assert {:error, redirect} = live(log_in(conn, login_fixture()), ~p"/manage")

      assert {:redirect, %{to: path, flash: flash}} = redirect
      assert path == ~p"/"
      assert %{"error" => "You cannot access this page."} = flash
    end

    test "redirects if not logged in", %{conn: conn} do
      assert {:error, redirect} = live(conn, ~p"/settings")

      assert {:redirect, %{to: path, flash: flash}} = redirect
      assert path == ~p"/log_in"
      assert %{"error" => "You must log in to access this page."} = flash
    end

    test "it can display a guest", %{conn: conn, guest: guest} do
      {:ok, index_live, _html} = live(log_in(conn, admin_fixture()), ~p"/manage")

      result =
        index_live
        |> element("#guest-#{guest.id} td:last-child a", "Show")
        |> render_click()

      assert result =~ "Guest"
      assert_patch(index_live, ~p"/manage/guests/#{guest}")
    end

    test "it can create a new guest", %{conn: conn} do
      {:ok, index_live, _html} = live(log_in(conn, admin_fixture()), ~p"/manage")

      assert index_live |> element("a", "Add Guest") |> render_click() =~
               "New Guest"

      assert_patch(index_live, ~p"/manage/guests/new")

      assert index_live
             |> form("#guest-form", guest: @guest_invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert index_live
             |> form("#guest-form", guest: @guest_create_attrs)
             |> render_submit()

      assert_patch(index_live, ~p"/manage")

      html = render(index_live)
      assert html =~ "Guest created successfully"
    end

    test "it can update a guest", %{conn: conn, guest: guest} do
      {:ok, index_live, _html} = live(log_in(conn, admin_fixture()), ~p"/manage")

      assert index_live |> element("#guest-#{guest.id} a", "Edit") |> render_click() =~
               "Edit Guest"

      assert_patch(index_live, ~p"/manage/guests/#{guest}/edit")

      assert index_live
             |> form("#guest-form", guest: @guest_invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert index_live
             |> form("#guest-form", guest: @guest_update_attrs)
             |> render_submit()

      assert_patch(index_live, ~p"/manage")

      html = render(index_live)
      assert html =~ "Guest updated successfully"
    end

    test "it can delete a guest in listing", %{conn: conn, guest: guest} do
      {:ok, index_live, _html} = live(log_in(conn, admin_fixture()), ~p"/manage")

      assert index_live |> element("#guest-#{guest.id} a", "Delete") |> render_click()
      refute has_element?(index_live, "#guest-#{guest.id}")
    end
  end
end
