defmodule InvitomaticWeb.Auth do
  use InvitomaticWeb, :verified_routes

  import Plug.Conn
  import Phoenix.Controller

  alias Invitomatic.Accounts

  # Make the remember me cookie valid for 60 days.
  # If you want bump or reduce this value, also change
  # the token expiry itself in Token.
  @max_age 60 * 60 * 24 * 60
  @remember_me_cookie "_invitomatic_web_remember_me"
  @remember_me_options [sign: true, max_age: @max_age, same_site: "Lax"]

  @doc """
  Logs in.

  It renews the session ID and clears the whole session
  to avoid fixation attacks. See the renew_session
  function to customize this behaviour.

  It also sets a `:live_socket_id` key in the session,
  so LiveView sessions are identified and automatically
  disconnected on log out. The line can be safely removed
  if you are not using LiveView.
  """
  def log_in(conn, login, params \\ %{}) do
    token = Accounts.generate_session_token(login)
    return_to = get_session(conn, :return_to)

    conn
    |> renew_session()
    |> put_token_in_session(token)
    |> maybe_write_remember_me_cookie(token, params)
    |> redirect(to: return_to || signed_in_path(conn))
  end

  defp maybe_write_remember_me_cookie(conn, token, %{"remember_me" => "true"}) do
    put_resp_cookie(conn, @remember_me_cookie, token, @remember_me_options)
  end

  defp maybe_write_remember_me_cookie(conn, _token, _params) do
    conn
  end

  # This function renews the session ID and erases the whole
  # session to avoid fixation attacks. If there is any data
  # in the session you may want to preserve after log in/log out,
  # you must explicitly fetch the session data before clearing
  # and then immediately set it after clearing, for example:
  #
  #     defp renew_session(conn) do
  #       preferred_locale = get_session(conn, :preferred_locale)
  #
  #       conn
  #       |> configure_session(renew: true)
  #       |> clear_session()
  #       |> put_session(:preferred_locale, preferred_locale)
  #     end
  #
  defp renew_session(conn) do
    conn
    |> configure_session(renew: true)
    |> clear_session()
  end

  @doc """
  Logs out.

  It clears all session data for safety. See renew_session.
  """
  def log_out(conn) do
    token = get_session(conn, :login_token)
    token && Accounts.delete_session_token(token)

    if live_socket_id = get_session(conn, :live_socket_id) do
      InvitomaticWeb.Endpoint.broadcast(live_socket_id, "disconnect", %{})
    end

    conn
    |> renew_session()
    |> delete_resp_cookie(@remember_me_cookie)
    |> redirect(to: ~p"/")
  end

  @doc """
  Authenticates by looking into the session
  and remember me token.
  """
  def fetch_current_login(conn, _opts) do
    {token, conn} = ensure_token(conn)
    login = token && Accounts.get_login_by_session_token(token)
    assign(conn, :current_login, login)
  end

  defp ensure_token(conn) do
    if token = get_session(conn, :login_token) do
      {token, conn}
    else
      conn = fetch_cookies(conn, signed: [@remember_me_cookie])

      if token = conn.cookies[@remember_me_cookie] do
        {token, put_token_in_session(conn, token)}
      else
        {nil, conn}
      end
    end
  end

  @doc """
  Handles mounting and authenticating the current_login in LiveViews.

  ## `on_mount` arguments

    * `:mount_current_login` - Assigns current_login
      to socket assigns based on login_token, or nil if
      there's no login_token or no matching login.

    * `:ensure_authenticated` - Authenticates the login from the session,
      and assigns the current_login to socket assigns based
      on login_token.
      Redirects to login page if there's no logged login.

    * `:redirect_if_authenticated` - Authenticates from the session.
      Redirects to signed_in_path if there's a login.

  ## Examples

  Use the `on_mount` lifecycle macro in LiveViews to mount or authenticate
  the current_login:

      defmodule InvitomaticWeb.PageLive do
        use InvitomaticWeb, :live_view

        on_mount {InvitomaticWeb.Auth, :mount_current_login}
        ...
      end

  Or use the `live_session` of your router to invoke the on_mount callback:

      live_session :authenticated, on_mount: [{InvitomaticWeb.Auth, :ensure_authenticated}] do
        live "/profile", ProfileLive, :index
      end
  """
  def on_mount(:mount_current_login, _params, session, socket) do
    {:cont, mount_current_login(session, socket)}
  end

  def on_mount(:ensure_authenticated, _params, session, socket) do
    socket = mount_current_login(session, socket)

    if socket.assigns.current_login do
      {:cont, socket}
    else
      socket =
        socket
        |> Phoenix.LiveView.put_flash(:error, "You must log in to access this page.")
        |> Phoenix.LiveView.redirect(to: ~p"/log_in")

      {:halt, socket}
    end
  end

  def on_mount(:ensure_authenticated_admin, params, session, socket) do
    case on_mount(:ensure_authenticated, params, session, socket) do
      {:cont, %{assigns: %{current_login: %_{admin: true}}} = authenticated_socket} ->
        {:cont, authenticated_socket}

      {:cont, socket} ->
        socket =
          socket
          |> Phoenix.LiveView.put_flash(:error, "You cannot access this page.")
          |> Phoenix.LiveView.redirect(to: ~p"/")

        {:halt, socket}

      {:halt, socket} ->
        {:halt, socket}
    end
  end

  def on_mount(:redirect_if_authenticated, _params, session, socket) do
    socket = mount_current_login(session, socket)

    if socket.assigns.current_login do
      {:halt, Phoenix.LiveView.redirect(socket, to: signed_in_path(socket))}
    else
      {:cont, socket}
    end
  end

  defp mount_current_login(session, socket) do
    Phoenix.Component.assign_new(socket, :current_login, fn ->
      if login_token = session["login_token"] do
        Accounts.get_login_by_session_token(login_token)
      end
    end)
  end

  @doc """
  Used for routes that require not being authenticated.
  """
  def redirect_if_authenticated(conn, _opts) do
    if conn.assigns[:current_login] do
      conn
      |> redirect(to: signed_in_path(conn))
      |> halt()
    else
      conn
    end
  end

  @doc """
  Used for routes that require being authenticated.

  If you want to enforce the login email is confirmed before
  they use the application at all, here would be a good place.
  """
  def require_authenticated(conn, _opts) do
    if conn.assigns[:current_login] do
      conn
    else
      conn
      |> put_flash(:error, "You must log in to access this page.")
      |> maybe_store_return_to()
      |> redirect(to: ~p"/log_in")
      |> halt()
    end
  end

  @doc """
  Used for routes that require being an admin.
  """
  def require_admin(conn, _opts) do
    case conn.assigns[:current_login] do
      %_{admin: true} ->
        conn

      _ ->
        conn
        |> put_flash(:error, "You cannot access this page.")
        |> redirect(to: ~p"/")
        |> halt()
    end
  end

  defp put_token_in_session(conn, token) do
    conn
    |> put_session(:login_token, token)
    |> put_session(:live_socket_id, "login_sessions:#{Base.url_encode64(token)}")
  end

  defp maybe_store_return_to(%{method: "GET"} = conn) do
    put_session(conn, :return_to, current_path(conn))
  end

  defp maybe_store_return_to(conn), do: conn

  defp signed_in_path(_conn), do: ~p"/"
end
