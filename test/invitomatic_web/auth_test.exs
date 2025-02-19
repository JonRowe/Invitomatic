defmodule InvitomaticWeb.AuthTest do
  use InvitomaticWeb.ConnCase, async: true

  alias Invitomatic.Accounts
  alias InvitomaticWeb.Auth

  import Invitomatic.AccountsFixtures

  @remember_me_cookie "_invitomatic_web_remember_me"

  setup %{conn: conn} do
    conn =
      conn
      |> Map.replace!(:secret_key_base, InvitomaticWeb.Endpoint.config(:secret_key_base))
      |> init_test_session(%{})

    %{login: login_fixture(), conn: conn}
  end

  describe "log_in/3" do
    test "stores the token in the session", %{conn: conn, login: login} do
      conn = Auth.log_in(conn, login)
      assert token = get_session(conn, :login_token)
      assert get_session(conn, :live_socket_id) == "login_sessions:#{Base.url_encode64(token)}"
      assert redirected_to(conn) == ~p"/"
      assert Accounts.get_login_by_session_token(token)
    end

    test "clears everything previously stored in the session", %{conn: conn, login: login} do
      conn = conn |> put_session(:to_be_removed, "value") |> Auth.log_in(login)
      refute get_session(conn, :to_be_removed)
    end

    test "redirects to the configured path", %{conn: conn, login: login} do
      conn = conn |> put_session(:return_to, "/hello") |> Auth.log_in(login)
      assert redirected_to(conn) == "/hello"
    end

    test "writes a cookie if remember_me is configured", %{conn: conn, login: login} do
      conn = conn |> fetch_cookies() |> Auth.log_in(login, %{"remember_me" => "true"})
      assert get_session(conn, :login_token) == conn.cookies[@remember_me_cookie]

      assert %{value: signed_token, max_age: max_age} = conn.resp_cookies[@remember_me_cookie]
      assert signed_token != get_session(conn, :login_token)
      assert max_age == 5_184_000
    end
  end

  describe "log_out/1" do
    test "erases session and cookies", %{conn: conn, login: login} do
      token = Accounts.generate_session_token(login)

      conn =
        conn
        |> put_session(:login_token, token)
        |> put_req_cookie(@remember_me_cookie, token)
        |> fetch_cookies()
        |> Auth.log_out()

      refute get_session(conn, :login_token)
      refute conn.cookies[@remember_me_cookie]
      assert %{max_age: 0} = conn.resp_cookies[@remember_me_cookie]
      assert redirected_to(conn) == ~p"/"
      refute Accounts.get_login_by_session_token(token)
    end

    test "broadcasts to the given live_socket_id", %{conn: conn} do
      live_socket_id = "login_sessions:abcdef-token"
      InvitomaticWeb.Endpoint.subscribe(live_socket_id)

      conn
      |> put_session(:live_socket_id, live_socket_id)
      |> Auth.log_out()

      assert_receive %Phoenix.Socket.Broadcast{event: "disconnect", topic: ^live_socket_id}
    end

    test "works even if login is already logged out", %{conn: conn} do
      conn = conn |> fetch_cookies() |> Auth.log_out()
      refute get_session(conn, :login_token)
      assert %{max_age: 0} = conn.resp_cookies[@remember_me_cookie]
      assert redirected_to(conn) == ~p"/"
    end
  end

  describe "fetch_current_login/2" do
    test "authenticates login from session", %{conn: conn, login: login} do
      token = Accounts.generate_session_token(login)
      conn = conn |> put_session(:login_token, token) |> Auth.fetch_current_login([])
      assert conn.assigns.current_login.id == login.id
    end

    test "authenticates login from cookies", %{conn: conn, login: login} do
      logged_in_conn = conn |> fetch_cookies() |> Auth.log_in(login, %{"remember_me" => "true"})

      token = logged_in_conn.cookies[@remember_me_cookie]
      %{value: signed_token} = logged_in_conn.resp_cookies[@remember_me_cookie]

      conn =
        conn
        |> put_req_cookie(@remember_me_cookie, signed_token)
        |> Auth.fetch_current_login([])

      assert conn.assigns.current_login.id == login.id
      assert get_session(conn, :login_token) == token

      assert get_session(conn, :live_socket_id) ==
               "login_sessions:#{Base.url_encode64(token)}"
    end

    test "does not authenticate if data is missing", %{conn: conn, login: login} do
      _ = Accounts.generate_session_token(login)
      conn = Auth.fetch_current_login(conn, [])
      refute get_session(conn, :login_token)
      refute conn.assigns.current_login
    end
  end

  describe "on_mount: mount_current_login" do
    test "assigns current_login based on a valid token ", %{conn: conn, login: login} do
      token = Accounts.generate_session_token(login)
      session = conn |> put_session(:login_token, token) |> get_session()

      {:cont, updated_socket} = Auth.on_mount(:mount_current_login, %{}, session, socket())

      assert updated_socket.assigns.current_login.id == login.id
    end

    test "assigns nil to current_login assign if there isn't a valid token ", %{conn: conn} do
      token = "invalid_token"
      session = conn |> put_session(:login_token, token) |> get_session()

      {:cont, updated_socket} = Auth.on_mount(:mount_current_login, %{}, session, socket())

      assert updated_socket.assigns.current_login == nil
    end

    test "assigns nil to current_login assign if there isn't a token", %{conn: conn} do
      session = conn |> get_session()

      {:cont, updated_socket} = Auth.on_mount(:mount_current_login, %{}, session, socket())

      assert updated_socket.assigns.current_login == nil
    end
  end

  describe "on_mount: ensure_authenticated" do
    test "authenticates current_login based on a valid token ", %{conn: conn, login: login} do
      token = Accounts.generate_session_token(login)
      session = conn |> put_session(:login_token, token) |> get_session()

      {:cont, updated_socket} = Auth.on_mount(:ensure_authenticated, %{}, session, socket())

      assert updated_socket.assigns.current_login.id == login.id
    end

    test "redirects to login page if there isn't a valid token ", %{conn: conn} do
      token = "invalid_token"
      session = conn |> put_session(:login_token, token) |> get_session()

      {:halt, updated_socket} = Auth.on_mount(:ensure_authenticated, %{}, session, socket())
      assert updated_socket.redirected == {:redirect, %{to: ~p"/log_in", status: 302}}
      assert updated_socket.assigns.current_login == nil
    end

    test "redirects to login page if there isn't a token ", %{conn: conn} do
      session = conn |> get_session()

      {:halt, updated_socket} = Auth.on_mount(:ensure_authenticated, %{}, session, socket())
      assert updated_socket.redirected == {:redirect, %{to: ~p"/log_in", status: 302}}
      assert updated_socket.assigns.current_login == nil
    end
  end

  describe "on_mount: ensure_authenticated_admin" do
    test "allows admin current_login to continue", %{conn: conn} do
      admin = admin_fixture()
      token = Accounts.generate_session_token(admin)
      session = conn |> put_session(:login_token, token) |> get_session()

      {:cont, updated_socket} = Auth.on_mount(:ensure_authenticated_admin, %{}, session, socket())

      assert updated_socket.assigns.current_login.id == admin.id
      assert updated_socket.assigns.current_login.admin == true
    end

    test "authenticated non admin current_login but redirects to / ", %{conn: conn, login: login} do
      token = Accounts.generate_session_token(login)
      session = conn |> put_session(:login_token, token) |> get_session()

      {:halt, updated_socket} = Auth.on_mount(:ensure_authenticated_admin, %{}, session, socket())

      assert updated_socket.redirected == {:redirect, %{to: ~p"/", status: 302}}
      assert updated_socket.assigns.current_login.id == login.id
      assert updated_socket.assigns.current_login.admin == false
    end

    test "redirects to login page if there isn't a valid token ", %{conn: conn} do
      token = "invalid_token"
      session = conn |> put_session(:login_token, token) |> get_session()

      {:halt, updated_socket} = Auth.on_mount(:ensure_authenticated_admin, %{}, session, socket())
      assert updated_socket.redirected == {:redirect, %{to: ~p"/log_in", status: 302}}
      assert updated_socket.assigns.current_login == nil
    end

    test "redirects to login page if there isn't a token ", %{conn: conn} do
      session = conn |> get_session()

      {:halt, updated_socket} = Auth.on_mount(:ensure_authenticated_admin, %{}, session, socket())
      assert updated_socket.redirected == {:redirect, %{to: ~p"/log_in", status: 302}}
      assert updated_socket.assigns.current_login == nil
    end
  end

  describe "on_mount: :redirect_if_authenticated" do
    test "redirects if there is an authenticated  login ", %{conn: conn, login: login} do
      token = Accounts.generate_session_token(login)
      session = conn |> put_session(:login_token, token) |> get_session()

      assert {:halt, updated_socket} =
               Auth.on_mount(
                 :redirect_if_authenticated,
                 %{},
                 session,
                 socket()
               )

      assert updated_socket.redirected == {:redirect, %{to: ~p"/", status: 302}}
    end

    test "Don't redirect is there is no authenticated login", %{conn: conn} do
      session = conn |> get_session()

      assert {:cont, updated_socket} =
               Auth.on_mount(
                 :redirect_if_authenticated,
                 %{},
                 session,
                 socket()
               )

      assert updated_socket.redirected == nil
    end
  end

  describe "redirect_if_authenticated/2" do
    test "redirects if authenticated", %{conn: conn, login: login} do
      conn = conn |> assign(:current_login, login) |> Auth.redirect_if_authenticated([])

      assert conn.halted
      assert redirected_to(conn) == ~p"/"
    end

    test "does not redirect if not authenticated", %{conn: conn} do
      conn = Auth.redirect_if_authenticated(conn, [])
      refute conn.halted
      refute conn.status
    end
  end

  describe "require_authenticated/2" do
    test "redirects if not authenticated", %{conn: conn} do
      conn = conn |> fetch_flash() |> Auth.require_authenticated([])
      assert conn.halted

      assert redirected_to(conn) == ~p"/log_in"

      assert Phoenix.Flash.get(conn.assigns.flash, :error) ==
               "You must log in to access this page."
    end

    test "stores the path to redirect to on GET", %{conn: conn} do
      halted_conn =
        %{conn | path_info: ["foo"], query_string: ""}
        |> fetch_flash()
        |> Auth.require_authenticated([])

      assert halted_conn.halted
      assert get_session(halted_conn, :return_to) == "/foo"

      halted_conn =
        %{conn | path_info: ["foo"], query_string: "bar=baz"}
        |> fetch_flash()
        |> Auth.require_authenticated([])

      assert halted_conn.halted
      assert get_session(halted_conn, :return_to) == "/foo?bar=baz"

      halted_conn =
        %{conn | path_info: ["foo"], query_string: "bar", method: "POST"}
        |> fetch_flash()
        |> Auth.require_authenticated([])

      assert halted_conn.halted
      refute get_session(halted_conn, :return_to)
    end

    test "does not redirect if authenticated", %{conn: conn, login: login} do
      conn = conn |> assign(:current_login, login) |> Auth.require_authenticated([])
      refute conn.halted
      refute conn.status
    end
  end

  describe "require_admin/2" do
    test "redirects if not an admin", %{conn: conn} do
      conn = conn |> fetch_flash() |> Auth.require_admin([])
      assert conn.halted

      assert redirected_to(conn) == ~p"/"

      assert Phoenix.Flash.get(conn.assigns.flash, :error) == "You cannot access this page."
    end

    test "does not redirect if an admin", %{conn: conn} do
      conn = conn |> assign(:current_login, admin_fixture()) |> Auth.require_authenticated([])
      refute conn.halted
      refute conn.status
    end
  end
end
