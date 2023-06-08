defmodule InvitomaticWeb.Live.ContentManagerTest do
  use InvitomaticWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import Invitomatic.AccountsFixtures
  import Invitomatic.ContentFixtures

  @create_attrs %{text: "some text", type: "invitation"}
  @update_attrs %{text: "some updated text", type: "rsvp"}
  @invalid_attrs %{text: nil, type: "invitation"}

  describe "managing content" do
    setup do
      %{section: content_fixture()}
    end

    test "lists all content", %{conn: conn, section: section} do
      {:ok, _index_live, html} = live(log_in(conn, admin_fixture()), ~p"/manage/content")

      assert html =~ "Listing Content"
      assert html =~ section.text
    end

    test "redirects if not an admin", %{conn: conn} do
      assert {:error, redirect} = live(log_in(conn, login_fixture()), ~p"/manage/content")

      assert {:redirect, %{to: path, flash: flash}} = redirect
      assert path == ~p"/"
      assert %{"error" => "You cannot access this page."} = flash
    end

    test "redirects if not logged in", %{conn: conn} do
      assert {:error, redirect} = live(conn, ~p"/manage/content")

      assert {:redirect, %{to: path, flash: flash}} = redirect
      assert path == ~p"/log_in"
      assert %{"error" => "You must log in to access this page."} = flash
    end

    test "saves new content", %{conn: conn} do
      {:ok, index_live, _html} = live(log_in(conn, admin_fixture()), ~p"/manage/content")

      assert index_live |> element("a", "New Content") |> render_click() =~
               "New Content"

      assert_patch(index_live, ~p"/manage/content/new")

      assert index_live
             |> form("#content-form", section: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert index_live
             |> form("#content-form", section: @create_attrs)
             |> render_submit()

      assert_patch(index_live, ~p"/manage/content")

      html = render(index_live)
      assert html =~ "Content created successfully"
      assert html =~ "some text"
    end

    test "updates content in listing", %{conn: conn, section: section} do
      {:ok, index_live, _html} = live(log_in(conn, admin_fixture()), ~p"/manage/content")

      assert index_live |> element("#content-#{section.id} a", "Edit") |> render_click() =~
               "Edit Section"

      assert_patch(index_live, ~p"/manage/content/#{section}/edit")

      assert index_live
             |> form("#content-form", section: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert index_live
             |> form("#content-form", section: @update_attrs)
             |> render_submit()

      assert_patch(index_live, ~p"/manage/content")

      html = render(index_live)
      assert html =~ "Content updated successfully"
      assert html =~ "some updated text"
    end

    test "deletes content in listing", %{conn: conn, section: section} do
      {:ok, index_live, _html} = live(log_in(conn, admin_fixture()), ~p"/manage/content")

      assert index_live |> element("#content-#{section.id} a", "Delete") |> render_click()
      refute has_element?(index_live, "#content-#{section.id}")
    end
  end
end
