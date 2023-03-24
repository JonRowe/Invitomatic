defmodule InvitomaticWeb.Live.LoginTest do
  use InvitomaticWeb.ConnCase

  import Phoenix.LiveViewTest
  import Invitomatic.AccountsFixtures

  describe "Log in page" do
    test "renders log in page", %{conn: conn} do
      {:ok, _lv, html} = live(conn, ~p"/log_in")

      assert html =~ "Sign in"
    end

    test "redirects if already logged in", %{conn: conn} do
      result =
        conn
        |> log_in(login_fixture())
        |> live(~p"/log_in")
        |> follow_redirect(conn, "/")

      assert {:ok, _conn} = result
    end
  end

  describe "login" do
    test "sends an email to login and displays a message", %{conn: conn} do
      login = login_fixture()

      {:ok, lv, _html} = live(conn, ~p"/log_in")

      form = form(lv, "#login_form", guest: %{email: login.email, remember_me: true})

      conn = submit_form(form, conn)

      assert redirected_to(conn) == ~p"/log_in"
    end
  end
end
