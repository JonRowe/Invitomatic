defmodule InvitomaticWeb.GuestLoginLiveTest do
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
    test "redirects if guest login with valid credentials", %{conn: conn} do
      guest = guest_fixture()

      {:ok, lv, _html} = live(conn, ~p"/guest/log_in")

      form = form(lv, "#login_form", guest: %{email: guest.email, remember_me: true})

      conn = submit_form(form, conn)

      assert redirected_to(conn) == ~p"/"
    end

    test "redirects to login page with a flash error if there are no valid credentials", %{
      conn: conn
    } do
      {:ok, lv, _html} = live(conn, ~p"/guest/log_in")

      form =
        form(lv, "#login_form",
          guest: %{email: "test@email.com", password: "123456", remember_me: true}
        )

      conn = submit_form(form, conn)

      assert Phoenix.Flash.get(conn.assigns.flash, :error) == "Invalid email or password"

      assert redirected_to(conn) == "/guest/log_in"
    end
  end
end
