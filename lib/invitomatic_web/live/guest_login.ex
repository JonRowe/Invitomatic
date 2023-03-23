defmodule InvitomaticWeb.Live.GuestLogin do
  use InvitomaticWeb, :live_view

  @impl Phoenix.LiveView
  def mount(_params, _session, socket) do
    email = live_flash(socket.assigns.flash, :email)
    form = to_form(%{"email" => email}, as: "guest")
    {:ok, assign(socket, form: form), temporary_assigns: [form: form]}
  end

  @impl Phoenix.LiveView
  def render(assigns) do
    ~H"""
    <div>
      <.header>
        Sign in to account
        <:subtitle>
          Don't have an account? Ask your host for an invite!
        </:subtitle>
      </.header>

      <.simple_form for={@form} id="login_form" action={~p"/guest/log_in"} phx-update="ignore">
        <.input field={@form[:email]} type="email" label="Email" required />

        <:actions>
          <.input field={@form[:remember_me]} type="checkbox" label="Keep me logged in" />
        </:actions>
        <:actions>
          <.button phx-disable-with="Signing in...">
            Sign in <span aria-hidden="true">→</span>
          </.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end
end
