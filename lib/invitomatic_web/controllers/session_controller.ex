defmodule InvitomaticWeb.SessionController do
  use InvitomaticWeb, :controller

  alias Invitomatic.Accounts
  alias InvitomaticWeb.Auth

  require Logger

  def create(conn, %{"guest" => %{"email" => email}}) do
    # TODO: rate limit this?
    # TODO: also prevent timing attacks by doing this in a job
    if login = Accounts.get_login_by_email(email) do
      _ = Accounts.deliver_magic_link(login, &url(~p"/log_in/#{&1}/"))
    else
      Logger.warn("Warning login attempt for #{email} and no login found.")
    end

    conn
    |> put_flash(:info, "Link sent to your email.")
    |> redirect(to: ~p"/log_in")
  end

  def create(conn, %{"token" => token}) do
    case Accounts.get_login_from_magic_link_token(token) do
      {:ok, login} ->
        conn
        |> put_flash(:info, "Welcome back!")
        |> Auth.log_in(login, %{})

      _ ->
        conn
        |> put_flash(:error, "Invalid link, please login again.")
        |> redirect(to: ~p"/log_in")
    end
  end

  def delete(conn, _params) do
    conn
    |> put_flash(:info, "Logged out successfully.")
    |> Auth.log_out()
  end
end
