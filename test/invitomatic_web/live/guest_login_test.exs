defmodule InvitomaticWeb.Live.GuestLoginTest do
  use InvitomaticWeb.ConnCase

  import Phoenix.LiveViewTest
  import Invitomatic.InvitesFixtures

  describe "Log in page" do
    test "renders log in page", %{conn: conn} do
      {:ok, _lv, html} = live(conn, ~p"/guest/log_in")

      assert html =~ "Sign in"
    end

    test "redirects if already logged in", %{conn: conn} do
      result =
        conn
        |> log_in_guest(guest_fixture())
        |> live(~p"/guest/log_in")
        |> follow_redirect(conn, "/")

      assert {:ok, _conn} = result
    end
  end

  describe "guest login" do
    test "sends an email to the guest to login and displays a message", %{conn: conn} do
      guest = guest_fixture()

      {:ok, lv, _html} = live(conn, ~p"/guest/log_in")

      form = form(lv, "#login_form", guest: %{email: guest.email, remember_me: true})

      conn = submit_form(form, conn)

      assert redirected_to(conn) == ~p"/guest/log_in"
    end
  end
end
