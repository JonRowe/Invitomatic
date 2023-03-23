defmodule InvitomaticWeb.GuestSessionControllerTest do
  use InvitomaticWeb.ConnCase, async: true

  import Invitomatic.InvitesFixtures

  setup do
    %{guest: guest_fixture()}
  end

  describe "POST /guest/log_in" do
    test "logs the guest in", %{conn: conn, guest: guest} do
      conn =
        post(conn, ~p"/guest/log_in", %{
          "guest" => %{"email" => guest.email}
        })

      assert get_session(conn, :guest_token)
      assert redirected_to(conn) == ~p"/"

      # Now do a logged in request and assert on the menu
      conn = get(conn, ~p"/")
      response = html_response(conn, 200)
      assert response =~ "Welcome back!"
      assert response =~ guest.email
      assert response =~ ~p"/guest/settings"
      assert response =~ ~p"/guest/log_out"
    end

    test "logs the guest in with remember me", %{conn: conn, guest: guest} do
      conn =
        post(conn, ~p"/guest/log_in", %{
          "guest" => %{
            "email" => guest.email,
            "remember_me" => "true"
          }
        })

      assert conn.resp_cookies["_invitomatic_web_guest_remember_me"]
      assert redirected_to(conn) == ~p"/"
    end

    test "logs the guest in with return to", %{conn: conn, guest: guest} do
      conn =
        conn
        |> init_test_session(guest_return_to: "/foo/bar")
        |> post(~p"/guest/log_in", %{
          "guest" => %{
            "email" => guest.email
          }
        })

      assert redirected_to(conn) == "/foo/bar"
      assert Phoenix.Flash.get(conn.assigns.flash, :info) =~ "Welcome back!"
    end

    test "redirects to login page with invalid credentials", %{conn: conn} do
      conn =
        post(conn, ~p"/guest/log_in", %{
          "guest" => %{"email" => "invalid@email.com"}
        })

      assert Phoenix.Flash.get(conn.assigns.flash, :error) == "Invalid email or password"
      assert redirected_to(conn) == ~p"/guest/log_in"
    end
  end

  describe "DELETE /guest/log_out" do
    test "logs the guest out", %{conn: conn, guest: guest} do
      conn = conn |> log_in_guest(guest) |> delete(~p"/guest/log_out")
      assert redirected_to(conn) == ~p"/"
      refute get_session(conn, :guest_token)
      assert Phoenix.Flash.get(conn.assigns.flash, :info) =~ "Logged out successfully"
    end

    test "succeeds even if the guest is not logged in", %{conn: conn} do
      conn = delete(conn, ~p"/guest/log_out")
      assert redirected_to(conn) == ~p"/"
      refute get_session(conn, :guest_token)
      assert Phoenix.Flash.get(conn.assigns.flash, :info) =~ "Logged out successfully"
    end
  end
end
