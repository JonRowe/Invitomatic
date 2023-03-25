defmodule InvitomaticWeb.Live.InvitationManagerTest do
  use InvitomaticWeb.ConnCase

  import Phoenix.LiveViewTest
  import Invitomatic.AccountsFixtures

  describe "Management page" do
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
  end
end
