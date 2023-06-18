defmodule InvitomaticWeb.Live.Settings do
  use InvitomaticWeb, :live_view

  alias Invitomatic.Accounts

  @impl Phoenix.LiveView
  def handle_event("validate_email", params, socket) do
    %{"guest" => login_params} = params

    email_form =
      socket.assigns.current_login
      |> Accounts.change_email(login_params)
      |> Map.put(:action, :validate)
      |> to_form()

    {:noreply, assign(socket, email_form: email_form)}
  end

  def handle_event("update_email", params, socket) do
    %{"guest" => login_params} = params
    login = socket.assigns.current_login

    case Accounts.apply_email(login, login_params) do
      {:ok, applied_login} ->
        Accounts.deliver_update_email_instructions(
          applied_login,
          login.email,
          &url(~p"/settings/confirm_email/#{&1}")
        )

        info = "A link to confirm your email change has been sent to the new address."
        {:noreply, socket |> put_flash(:info, info) |> assign(email_form_current_password: nil)}

      {:error, changeset} ->
        {:noreply, assign(socket, :email_form, to_form(Map.put(changeset, :action, :insert), as: "guest"))}
    end
  end

  @impl Phoenix.LiveView
  def mount(%{"token" => token}, _session, socket) do
    socket =
      case Accounts.update_email(socket.assigns.current_login, token) do
        :ok ->
          put_flash(socket, :info, "Email changed successfully.")

        :error ->
          put_flash(socket, :error, "Email change link is invalid or it has expired.")
      end

    {:ok, push_navigate(socket, to: ~p"/settings")}
  end

  def mount(_params, _session, socket) do
    login = socket.assigns.current_login
    email_changeset = Accounts.change_email(login)

    socket =
      socket
      |> assign(:current_email, login.email)
      |> assign(:email_form, to_form(email_changeset, as: "guest"))
      |> assign(:trigger_submit, false)

    {:ok, socket}
  end

  @impl Phoenix.LiveView
  def render(assigns) do
    ~H"""
    <.modal id="login-prompt" show on_cancel={JS.navigate(~p"/")}>
      <.header>
        Account Settings
        <:subtitle>Manage your account email address.</:subtitle>
      </.header>

      <div>
        <div>
          <.simple_form for={@email_form} id="email_form" phx-submit="update_email" phx-change="validate_email">
            <.input field={@email_form[:email]} type="email" label="Email" required />
            <:actions>
              <.button phx-disable-with="Changing...">Change Email</.button>
            </:actions>
          </.simple_form>
        </div>
      </div>
    </.modal>
    """
  end
end
