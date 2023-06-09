defmodule InvitomaticWeb.Live.Login do
  use InvitomaticWeb, :live_view

  @impl Phoenix.LiveView
  def mount(_params, _session, socket) do
    email = live_flash(socket.assigns.flash, :email)
    form = to_form(%{"email" => email}, as: "guest")
    {:ok, assign(socket, modal_open: true, form: form), temporary_assigns: [form: form]}
  end

  @impl Phoenix.LiveView
  def render(assigns) do
    ~H"""
    <.modal id="login-prompt" show no_cancel>
      <.header>
        Sign in
        <:subtitle>
          Forgotten your invite link? Enter your email below to send a new one.
        </:subtitle>
      </.header>
      <.flash_group flash={@flash} />

      <.simple_form for={@form} id="login_form" action={~p"/log_in"} phx-update="ignore">
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
    </.modal>
    """
  end
end
