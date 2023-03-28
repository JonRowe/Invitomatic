defmodule InvitomaticWeb.Live.InvitationManager do
  use InvitomaticWeb, :live_view

  alias Invitomatic.Accounts
  alias Invitomatic.Accounts.Login
  alias Invitomatic.Guests
  alias Invitomatic.Invites
  alias Invitomatic.Invites.Guest
  alias Invitomatic.Invites.Invite
  alias InvitomaticWeb.Live.InvitiationManager.FormComponent

  @impl Phoenix.LiveView
  def handle_event("delete", %{"id" => id}, socket) do
    guest = Accounts.get_login!(id)
    {:ok, _} = Guests.delete(guest)

    {:noreply, stream_delete(socket, :guests, guest)}
  end

  @impl Phoenix.LiveView
  def handle_info({FormComponent, {:saved, invite}}, socket) do
    {:noreply, Enum.reduce(invite.logins, socket, &stream_insert(&2, :guests, Map.put(&1, :invite, invite)))}
  end

  @impl Phoenix.LiveView
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  @impl Phoenix.LiveView
  def mount(_params, _session, socket) do
    {:ok, stream(socket, :guests, Invites.list_guests(), dom_id: &"guest-#{&1.id}")}
  end

  @impl Phoenix.LiveView
  def render(assigns) do
    ~H"""
    <.header>Invitation Management</.header>
    <nav>
      <.link class="button" patch={~p"/manage/invites/new"}>New Invite</.link>
    </nav>
    <.table
      id="guests"
      rows={@streams.guests}
      row_click={fn {_id, guest} -> JS.patch(~p"/manage/invites/#{guest.invite}") end}
    >
      <:col :let={{_id, guest}} label="Email"><%= guest.email %></:col>
      <:col :let={{_id, guest}} label="Name"><%= guest.invite.name %></:col>
      <:action :let={{_id, guest}}>
        <div class="sr-only">
          <.link patch={~p"/manage/invites/#{guest.invite}"}>Show</.link>
        </div>
        <.link patch={~p"/manage/invites/#{guest.invite}/edit"}>Edit</.link>
      </:action>
      <:action :let={{id, guest}}>
        <.link phx-click={JS.push("delete", value: %{id: guest.id}) |> hide("##{id}")} data-confirm="Are you sure?">
          Delete
        </.link>
      </:action>
    </.table>
    <.modal :if={@live_action == :show} id="invite-modal" show on_cancel={JS.patch(~p"/manage")}>
      <InvitomaticWeb.Live.InvitiationManager.ShowComponent.details invite={@invite} />
    </.modal>
    <.modal :if={@live_action in [:new, :edit]} id="invite-form-modal" show on_cancel={JS.patch(~p"/manage")}>
      <.live_component
        module={InvitomaticWeb.Live.InvitiationManager.FormComponent}
        id={@invite.id || :new}
        title={@page_title}
        action={@live_action}
        invite={@invite}
        patch={~p"/manage"}
      />
    </.modal>
    """
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    socket
    |> assign(:page_title, "Edit Invite")
    |> assign(:invite, Invites.get(id))
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "New Invite")
    |> assign(:invite, %Invite{guests: [%Guest{}], logins: [%Login{}]})
  end

  defp apply_action(socket, :show, %{"id" => id}) do
    socket
    |> assign(:page_title, "Invitation")
    |> assign(:invite, Invites.get(id))
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Listing Guest")
    |> assign(:invite, nil)
  end
end
