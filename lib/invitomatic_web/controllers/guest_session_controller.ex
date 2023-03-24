defmodule InvitomaticWeb.GuestSessionController do
  use InvitomaticWeb, :controller

  alias Invitomatic.Invites
  alias InvitomaticWeb.GuestAuth

  def create(conn, %{"guest" => %{"email" => email}}) do
    # TODO: rate limit this?
    # TODO: also prevent timing attacks by doing this in a job
    if guest = Invites.get_guest_by_email(email) do
      _ = Invites.deliver_guest_magic_link(guest, &url(~p"/guest/log_in/#{&1}/"))
    end

    conn
    |> put_flash(:info, "Link sent to your email.")
    |> redirect(to: ~p"/guest/log_in")
  end

  def create(conn, %{"token" => token}) do
    case Invites.get_guest_from_magic_link_token(token) do
      {:ok, guest} ->
        conn
        |> put_flash(:info, "Welcome back!")
        |> GuestAuth.log_in_guest(guest, %{})

      _ ->
        conn
        |> put_flash(:error, "Invalid link, please login again.")
        |> redirect(to: ~p"/guest/log_in")
    end
  end

  def delete(conn, _params) do
    conn
    |> put_flash(:info, "Logged out successfully.")
    |> GuestAuth.log_out_guest()
  end
end
