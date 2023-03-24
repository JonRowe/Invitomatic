defmodule InvitomaticWeb.SessionControllerTest do
  use InvitomaticWeb.ConnCase, async: true

  import Invitomatic.AccountsFixtures

  setup do
    %{login: login_fixture()}
  end

  describe "POST /log_in" do
    test "it sends a magic link", %{conn: conn, login: login} do
      conn =
        post(conn, ~p"/log_in", %{
          "guest" => %{"email" => login.email}
        })

      refute get_session(conn, :login_token)
      assert redirected_to(conn) == ~p"/log_in"
      assert Phoenix.Flash.get(conn.assigns.flash, :info) == "Link sent to your email."

      assert_received {:email, email}
      assert email.subject =~ ~r/Sign in to/

      "http://localhost" <> path =
        email.text_body
        |> String.split("\n")
        |> Enum.find(fn line -> line =~ "/log_in/" end)

      # Now do a logged in request and assert on the menu
      conn = get(conn, path)
      assert get_session(conn, :login_token)
      assert redirected_to(conn) == ~p"/"
      assert Phoenix.Flash.get(conn.assigns.flash, :info) == "Welcome back!"
    end
  end

  describe "GET /log_in/:token" do
    test "logs in when token is valid", %{conn: conn, login: login} do
      conn = get(conn, ~p"/log_in/#{magic_link_token(login)}")

      assert get_session(conn, :login_token)
      assert redirected_to(conn) == ~p"/"
      assert Phoenix.Flash.get(conn.assigns.flash, :info) == "Welcome back!"
    end

    test "redirects to login page with an invalid token", %{conn: conn} do
      conn = get(conn, ~p"/log_in/invalid")

      refute get_session(conn, :login_token)
      assert Phoenix.Flash.get(conn.assigns.flash, :error) == "Invalid link, please login again."
      assert redirected_to(conn) == ~p"/log_in"
    end
  end

  describe "DELETE /log_out" do
    test "logs out", %{conn: conn, login: login} do
      conn = conn |> log_in(login) |> delete(~p"/log_out")
      assert redirected_to(conn) == ~p"/"
      refute get_session(conn, :login_token)
      assert Phoenix.Flash.get(conn.assigns.flash, :info) =~ "Logged out successfully"
    end

    test "succeeds even if the not logged in", %{conn: conn} do
      conn = delete(conn, ~p"/log_out")
      assert redirected_to(conn) == ~p"/"
      refute get_session(conn, :login_token)
      assert Phoenix.Flash.get(conn.assigns.flash, :info) =~ "Logged out successfully"
    end
  end
end
