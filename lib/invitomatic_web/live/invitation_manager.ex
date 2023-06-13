defmodule InvitomaticWeb.Live.InvitationManager do
  use InvitomaticWeb, :live_view

  alias Invitomatic.Accounts.Login
  alias Invitomatic.Invites
  alias Invitomatic.Invites.Guest
  alias Invitomatic.Invites.Invite
  alias InvitomaticWeb.Live.InvitiationManager.FormComponent

  @impl Phoenix.LiveView
  def handle_info({FormComponent, {:saved, invite}}, socket) do
    {:noreply, stream_insert(socket, :invites, invite)}
  end

  @impl Phoenix.LiveView
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  @impl Phoenix.LiveView
  def mount(_params, _session, socket) do
    {:ok, stream(socket, :invites, Invites.list(), dom_id: &"invite-#{&1.id}")}
  end

  @impl Phoenix.LiveView
  def render(assigns) do
    ~H"""
    <.header>Invitation Management</.header>
    <nav>
      <.link class="button" patch={~p"/manage/invites/new"}>New Invite</.link>
    </nav>
    <table id="guests" phx-update="stream">
      <thead id="invite-header">
        <tr>
          <th>Email</th>
          <th>Invite Name</th>
          <th>Content</th>
          <th>Guest Name</th>
          <th>Age</th>
          <th>RSVP</th>
          <th class="actions"><span class="sr-only">Actions</span></th>
        </tr>
      </thead>
      <tbody :for={{row_id, invite} <- @streams.invites} id={row_id}>
        <tr :for={{guest, index} <- Enum.with_index(invite.guests)} phx-click={JS.patch(~p"/manage/invites/#{invite}")}>
          <td :if={index == 0} rowspan={length(invite.guests)}>
            <%= List.first(invite.logins).email %>
          </td>
          <td :if={index == 0} rowspan={length(invite.guests)}>
            <%= invite.name %>
          </td>
          <td :if={index == 0} rowspan={length(invite.guests)}>
            <%= invite.extra_content %>
          </td>
          <td><%= guest.name %></td>
          <td><%= format_age(guest) %></td>
          <td><%= format_rsvp(guest) %></td>
          <td :if={index == 0} rowspan={length(invite.guests)} class="actions">
            <div class="sr-only">
              <.link patch={~p"/manage/invites/#{invite}"}>Show</.link>
            </div>
            <.link patch={~p"/manage/invites/#{invite}/edit"}>Edit</.link>
          </td>
        </tr>
      </tbody>
    </table>
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

  defp format_age(%Guest{age: :under_three}), do: "< 3"
  defp format_age(%Guest{age: age}), do: String.capitalize(to_string(age))

  defp format_rsvp(%Guest{rsvp: nil}), do: "Not replied"
  defp format_rsvp(%Guest{rsvp: rsvp}), do: String.capitalize(to_string(rsvp))
end
