defmodule InvitomaticWeb.GuestAuthTest do
  use InvitomaticWeb.ConnCase, async: true

  alias Phoenix.LiveView
  alias Invitomatic.Invites
  alias InvitomaticWeb.GuestAuth
  import Invitomatic.InvitesFixtures

  @remember_me_cookie "_invitomatic_web_guest_remember_me"

  setup %{conn: conn} do
    conn =
      conn
      |> Map.replace!(:secret_key_base, InvitomaticWeb.Endpoint.config(:secret_key_base))
      |> init_test_session(%{})

    %{guest: guest_fixture(), conn: conn}
  end

  describe "log_in_guest/3" do
    test "stores the guest token in the session", %{conn: conn, guest: guest} do
      conn = GuestAuth.log_in_guest(conn, guest)
      assert token = get_session(conn, :guest_token)
      assert get_session(conn, :live_socket_id) == "guest_sessions:#{Base.url_encode64(token)}"
      assert redirected_to(conn) == ~p"/"
      assert Invites.get_guest_by_session_token(token)
    end

    test "clears everything previously stored in the session", %{conn: conn, guest: guest} do
      conn = conn |> put_session(:to_be_removed, "value") |> GuestAuth.log_in_guest(guest)
      refute get_session(conn, :to_be_removed)
    end

    test "redirects to the configured path", %{conn: conn, guest: guest} do
      conn = conn |> put_session(:guest_return_to, "/hello") |> GuestAuth.log_in_guest(guest)
      assert redirected_to(conn) == "/hello"
    end

    test "writes a cookie if remember_me is configured", %{conn: conn, guest: guest} do
      conn = conn |> fetch_cookies() |> GuestAuth.log_in_guest(guest, %{"remember_me" => "true"})
      assert get_session(conn, :guest_token) == conn.cookies[@remember_me_cookie]

      assert %{value: signed_token, max_age: max_age} = conn.resp_cookies[@remember_me_cookie]
      assert signed_token != get_session(conn, :guest_token)
      assert max_age == 5_184_000
    end
  end

  describe "logout_guest/1" do
    test "erases session and cookies", %{conn: conn, guest: guest} do
      guest_token = Invites.generate_guest_session_token(guest)

      conn =
        conn
        |> put_session(:guest_token, guest_token)
        |> put_req_cookie(@remember_me_cookie, guest_token)
        |> fetch_cookies()
        |> GuestAuth.log_out_guest()

      refute get_session(conn, :guest_token)
      refute conn.cookies[@remember_me_cookie]
      assert %{max_age: 0} = conn.resp_cookies[@remember_me_cookie]
      assert redirected_to(conn) == ~p"/"
      refute Invites.get_guest_by_session_token(guest_token)
    end

    test "broadcasts to the given live_socket_id", %{conn: conn} do
      live_socket_id = "guest_sessions:abcdef-token"
      InvitomaticWeb.Endpoint.subscribe(live_socket_id)

      conn
      |> put_session(:live_socket_id, live_socket_id)
      |> GuestAuth.log_out_guest()

      assert_receive %Phoenix.Socket.Broadcast{event: "disconnect", topic: ^live_socket_id}
    end

    test "works even if guest is already logged out", %{conn: conn} do
      conn = conn |> fetch_cookies() |> GuestAuth.log_out_guest()
      refute get_session(conn, :guest_token)
      assert %{max_age: 0} = conn.resp_cookies[@remember_me_cookie]
      assert redirected_to(conn) == ~p"/"
    end
  end

  describe "fetch_current_guest/2" do
    test "authenticates guest from session", %{conn: conn, guest: guest} do
      guest_token = Invites.generate_guest_session_token(guest)
      conn = conn |> put_session(:guest_token, guest_token) |> GuestAuth.fetch_current_guest([])
      assert conn.assigns.current_guest.id == guest.id
    end

    test "authenticates guest from cookies", %{conn: conn, guest: guest} do
      logged_in_conn =
        conn |> fetch_cookies() |> GuestAuth.log_in_guest(guest, %{"remember_me" => "true"})

      guest_token = logged_in_conn.cookies[@remember_me_cookie]
      %{value: signed_token} = logged_in_conn.resp_cookies[@remember_me_cookie]

      conn =
        conn
        |> put_req_cookie(@remember_me_cookie, signed_token)
        |> GuestAuth.fetch_current_guest([])

      assert conn.assigns.current_guest.id == guest.id
      assert get_session(conn, :guest_token) == guest_token

      assert get_session(conn, :live_socket_id) ==
               "guest_sessions:#{Base.url_encode64(guest_token)}"
    end

    test "does not authenticate if data is missing", %{conn: conn, guest: guest} do
      _ = Invites.generate_guest_session_token(guest)
      conn = GuestAuth.fetch_current_guest(conn, [])
      refute get_session(conn, :guest_token)
      refute conn.assigns.current_guest
    end
  end

  describe "on_mount: mount_current_guest" do
    test "assigns current_guest based on a valid guest_token ", %{conn: conn, guest: guest} do
      guest_token = Invites.generate_guest_session_token(guest)
      session = conn |> put_session(:guest_token, guest_token) |> get_session()

      {:cont, updated_socket} =
        GuestAuth.on_mount(:mount_current_guest, %{}, session, %LiveView.Socket{})

      assert updated_socket.assigns.current_guest.id == guest.id
    end

    test "assigns nil to current_guest assign if there isn't a valid guest_token ", %{conn: conn} do
      guest_token = "invalid_token"
      session = conn |> put_session(:guest_token, guest_token) |> get_session()

      {:cont, updated_socket} =
        GuestAuth.on_mount(:mount_current_guest, %{}, session, %LiveView.Socket{})

      assert updated_socket.assigns.current_guest == nil
    end

    test "assigns nil to current_guest assign if there isn't a guest_token", %{conn: conn} do
      session = conn |> get_session()

      {:cont, updated_socket} =
        GuestAuth.on_mount(:mount_current_guest, %{}, session, %LiveView.Socket{})

      assert updated_socket.assigns.current_guest == nil
    end
  end

  describe "on_mount: ensure_authenticated" do
    test "authenticates current_guest based on a valid guest_token ", %{conn: conn, guest: guest} do
      guest_token = Invites.generate_guest_session_token(guest)
      session = conn |> put_session(:guest_token, guest_token) |> get_session()

      {:cont, updated_socket} =
        GuestAuth.on_mount(:ensure_authenticated, %{}, session, %LiveView.Socket{})

      assert updated_socket.assigns.current_guest.id == guest.id
    end

    test "redirects to login page if there isn't a valid guest_token ", %{conn: conn} do
      guest_token = "invalid_token"
      session = conn |> put_session(:guest_token, guest_token) |> get_session()

      socket = %LiveView.Socket{
        endpoint: InvitomaticWeb.Endpoint,
        assigns: %{__changed__: %{}, flash: %{}}
      }

      {:halt, updated_socket} = GuestAuth.on_mount(:ensure_authenticated, %{}, session, socket)
      assert updated_socket.assigns.current_guest == nil
    end

    test "redirects to login page if there isn't a guest_token ", %{conn: conn} do
      session = conn |> get_session()

      socket = %LiveView.Socket{
        endpoint: InvitomaticWeb.Endpoint,
        assigns: %{__changed__: %{}, flash: %{}}
      }

      {:halt, updated_socket} = GuestAuth.on_mount(:ensure_authenticated, %{}, session, socket)
      assert updated_socket.assigns.current_guest == nil
    end
  end

  describe "on_mount: :redirect_if_guest_is_authenticated" do
    test "redirects if there is an authenticated  guest ", %{conn: conn, guest: guest} do
      guest_token = Invites.generate_guest_session_token(guest)
      session = conn |> put_session(:guest_token, guest_token) |> get_session()

      assert {:halt, _updated_socket} =
               GuestAuth.on_mount(
                 :redirect_if_guest_is_authenticated,
                 %{},
                 session,
                 %LiveView.Socket{}
               )
    end

    test "Don't redirect is there is no authenticated guest", %{conn: conn} do
      session = conn |> get_session()

      assert {:cont, _updated_socket} =
               GuestAuth.on_mount(
                 :redirect_if_guest_is_authenticated,
                 %{},
                 session,
                 %LiveView.Socket{}
               )
    end
  end

  describe "redirect_if_guest_is_authenticated/2" do
    test "redirects if guest is authenticated", %{conn: conn, guest: guest} do
      conn =
        conn |> assign(:current_guest, guest) |> GuestAuth.redirect_if_guest_is_authenticated([])

      assert conn.halted
      assert redirected_to(conn) == ~p"/"
    end

    test "does not redirect if guest is not authenticated", %{conn: conn} do
      conn = GuestAuth.redirect_if_guest_is_authenticated(conn, [])
      refute conn.halted
      refute conn.status
    end
  end

  describe "require_authenticated_guest/2" do
    test "redirects if guest is not authenticated", %{conn: conn} do
      conn = conn |> fetch_flash() |> GuestAuth.require_authenticated_guest([])
      assert conn.halted

      assert redirected_to(conn) == ~p"/guest/log_in"

      assert Phoenix.Flash.get(conn.assigns.flash, :error) ==
               "You must log in to access this page."
    end

    test "stores the path to redirect to on GET", %{conn: conn} do
      halted_conn =
        %{conn | path_info: ["foo"], query_string: ""}
        |> fetch_flash()
        |> GuestAuth.require_authenticated_guest([])

      assert halted_conn.halted
      assert get_session(halted_conn, :guest_return_to) == "/foo"

      halted_conn =
        %{conn | path_info: ["foo"], query_string: "bar=baz"}
        |> fetch_flash()
        |> GuestAuth.require_authenticated_guest([])

      assert halted_conn.halted
      assert get_session(halted_conn, :guest_return_to) == "/foo?bar=baz"

      halted_conn =
        %{conn | path_info: ["foo"], query_string: "bar", method: "POST"}
        |> fetch_flash()
        |> GuestAuth.require_authenticated_guest([])

      assert halted_conn.halted
      refute get_session(halted_conn, :guest_return_to)
    end

    test "does not redirect if guest is authenticated", %{conn: conn, guest: guest} do
      conn = conn |> assign(:current_guest, guest) |> GuestAuth.require_authenticated_guest([])
      refute conn.halted
      refute conn.status
    end
  end
end
