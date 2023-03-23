defmodule InvitomaticWeb.Live.GuestSettings do
  use InvitomaticWeb, :live_view

  alias Invitomatic.Invites

  @impl Phoenix.LiveView
  def handle_event("validate_email", params, socket) do
    %{"guest" => guest_params} = params

    email_form =
      socket.assigns.current_guest
      |> Invites.change_guest_email(guest_params)
      |> Map.put(:action, :validate)
      |> to_form()

    {:noreply, assign(socket, email_form: email_form)}
  end

  def handle_event("update_email", params, socket) do
    %{"guest" => guest_params} = params
    guest = socket.assigns.current_guest

    case Invites.apply_guest_email(guest, guest_params) do
      {:ok, applied_guest} ->
        Invites.deliver_guest_update_email_instructions(
          applied_guest,
          guest.email,
          &url(~p"/guest/settings/confirm_email/#{&1}")
        )

        info = "A link to confirm your email change has been sent to the new address."
        {:noreply, socket |> put_flash(:info, info) |> assign(email_form_current_password: nil)}

      {:error, changeset} ->
        {:noreply, assign(socket, :email_form, to_form(Map.put(changeset, :action, :insert)))}
    end
  end

  @impl Phoenix.LiveView
  def mount(%{"token" => token}, _session, socket) do
    socket =
      case Invites.update_guest_email(socket.assigns.current_guest, token) do
        :ok ->
          put_flash(socket, :info, "Email changed successfully.")

        :error ->
          put_flash(socket, :error, "Email change link is invalid or it has expired.")
      end

    {:ok, push_navigate(socket, to: ~p"/guest/settings")}
  end

  def mount(_params, _session, socket) do
    guest = socket.assigns.current_guest
    email_changeset = Invites.change_guest_email(guest)

    socket =
      socket
      |> assign(:current_email, guest.email)
      |> assign(:email_form, to_form(email_changeset))
      |> assign(:trigger_submit, false)

    {:ok, socket}
  end

  @impl Phoenix.LiveView
  def render(assigns) do
    ~H"""
    <.header>
      Account Settings
      <:subtitle>Manage your account email address.</:subtitle>
    </.header>

    <div>
      <div>
        <.simple_form
          for={@email_form}
          id="email_form"
          phx-submit="update_email"
          phx-change="validate_email"
        >
          <.input field={@email_form[:email]} type="email" label="Email" required />
          <:actions>
            <.button phx-disable-with="Changing...">Change Email</.button>
          </:actions>
        </.simple_form>
      </div>
    </div>
    """
  end
end
