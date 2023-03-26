defmodule InvitomaticWeb.Live.InvitationManager do
  use InvitomaticWeb, :live_view

  alias Invitomatic.Accounts
  alias Invitomatic.Accounts.Login
  alias Invitomatic.Guests
  alias InvitomaticWeb.Live.InvitiationManager.GuestFormComponent

  @impl Phoenix.LiveView
  def handle_event("delete", %{"id" => id}, socket) do
    guest = Accounts.get_login!(id)
    {:ok, _} = Guests.delete(guest)

    {:noreply, stream_delete(socket, :guests, guest)}
  end

  @impl Phoenix.LiveView
  def handle_info({GuestFormComponent, {:saved, guest}}, socket) do
    {:noreply, stream_insert(socket, :guests, guest)}
  end

  @impl Phoenix.LiveView
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  @impl Phoenix.LiveView
  def mount(_params, _session, socket) do
    {:ok, stream(socket, :guests, Guests.list(), dom_id: &"guest-#{&1.id}")}
  end

  @impl Phoenix.LiveView
  def render(assigns) do
    ~H"""
    <.header>Invitation Management</.header>
    <nav>
      <.link class="button" patch={~p"/manage/guests/new"}>Add Guest</.link>
    </nav>
    <.table id="guests" rows={@streams.guests}>
      <:col :let={{_id, guest}} label="EMail"><%= guest.email %></:col>
      <:action :let={{_id, guest}}>
        <.link patch={~p"/manage/guests/#{guest}/edit"}>Edit</.link>
      </:action>
      <:action :let={{id, guest}}>
        <.link
          phx-click={JS.push("delete", value: %{id: guest.id}) |> hide("##{id}")}
          data-confirm="Are you sure?"
        >
          Delete
        </.link>
      </:action>
    </.table>
    <.modal
      :if={@live_action in [:new, :edit]}
      id="new-guest-modal"
      show
      on_cancel={JS.patch(~p"/manage")}
    >
      <.live_component
        module={InvitomaticWeb.Live.InvitiationManager.GuestFormComponent}
        id={@guest.id || :new}
        title={@page_title}
        action={@live_action}
        guest={@guest}
        patch={~p"/manage"}
      />
    </.modal>
    """
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    socket
    |> assign(:page_title, "Edit Guest")
    |> assign(:guest, Accounts.get_login!(id))
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "New Guest")
    |> assign(:guest, %Login{})
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Listing Guest")
    |> assign(:guest, nil)
  end
end
