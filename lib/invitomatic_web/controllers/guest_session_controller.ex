defmodule InvitomaticWeb.GuestSessionController do
  use InvitomaticWeb, :controller

  alias Invitomatic.Invites
  alias InvitomaticWeb.GuestAuth

  def create(conn, %{"guest" => %{"email" => email} = guest_params}) do
    # TODO: magic link this
    if guest = Invites.get_guest_by_email(email) do
      conn
      |> put_flash(:info, "Welcome back!")
      |> GuestAuth.log_in_guest(guest, guest_params)
    else
      # In order to prevent user enumeration attacks, don't disclose whether the email is registered.
      conn
      |> put_flash(:error, "Invalid email or password")
      |> put_flash(:email, String.slice(email, 0, 160))
      |> redirect(to: ~p"/guest/log_in")
    end
  end

  def delete(conn, _params) do
    conn
    |> put_flash(:info, "Logged out successfully.")
    |> GuestAuth.log_out_guest()
  end
end
