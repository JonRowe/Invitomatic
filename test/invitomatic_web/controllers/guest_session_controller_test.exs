defmodule InvitomaticWeb.GuestSessionControllerTest do
  use InvitomaticWeb.ConnCase, async: true

  import Invitomatic.InvitesFixtures

  setup do
    %{guest: guest_fixture()}
  end

  describe "POST /guest/log_in" do
    test "it sends the guest a magic link", %{conn: conn, guest: guest} do
      conn =
        post(conn, ~p"/guest/log_in", %{
          "guest" => %{"email" => guest.email}
        })

      refute get_session(conn, :guest_token)
      assert redirected_to(conn) == ~p"/guest/log_in"
      assert Phoenix.Flash.get(conn.assigns.flash, :info) == "Link sent to your email."

      assert_received {:email, email}
      assert email.subject =~ ~r/Sign in to/

      "http://localhost" <> path =
        email.text_body
        |> String.split("\n")
        |> Enum.find(fn line -> line =~ "/guest/log_in/" end)

      # Now do a logged in request and assert on the menu
      conn = get(conn, path)
      assert get_session(conn, :guest_token)
      assert redirected_to(conn) == ~p"/"
      assert Phoenix.Flash.get(conn.assigns.flash, :info) == "Welcome back!"
    end
  end

  describe "GET /guest/log_in/:token" do
    test "logs the guest in when token is valid", %{conn: conn, guest: guest} do
      conn = get(conn, ~p"/guest/log_in/#{magic_link_token(guest)}")

      assert get_session(conn, :guest_token)
      assert redirected_to(conn) == ~p"/"
      assert Phoenix.Flash.get(conn.assigns.flash, :info) == "Welcome back!"
    end

    test "redirects to login page with an invalid token", %{conn: conn} do
      conn = get(conn, ~p"/guest/log_in/invalid")

      refute get_session(conn, :guest_token)
      assert Phoenix.Flash.get(conn.assigns.flash, :error) == "Invalid link, please login again."
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
