defmodule InvitomaticWeb.Live.Invitation do
  use InvitomaticWeb, :live_view

  alias Invitomatic.Content
  alias Invitomatic.Invites
  alias InvitomaticWeb.Components.Content, as: ContentComponent
  alias InvitomaticWeb.Components.RSVP

  @impl Phoenix.LiveView
  def handle_event("rsvp", _params, socket) do
    {:noreply, assign(socket, :open, true)}
  end

  @impl Phoenix.LiveView
  def handle_info({:rsvp, message}, socket) do
    {:noreply, socket |> put_flash(:info, message)}
  end

  def handle_info({:error, message}, socket), do: {:noreply, put_flash(socket, :error, message)}

  @impl Phoenix.LiveView
  def mount(_session, _params, socket) do
    invite = Invites.get_for(socket.assigns.current_login)
    [content] = Content.get(:rsvp)
    {:ok, assign(socket, content: content, invite: invite, open: already_rsvped?(invite.guests))}
  end

  @impl Phoenix.LiveView
  def render(assigns) do
    ~H"""
    <section class="content invite">
      <ContentComponent.render content={@content} invite={@invite} />
      <button :if={!@open} phx-click="rsvp" type="button">RSVP</button>
    </section>
    <%= if @open do %>
      <section class="rsvp-group">
        <h1>Your Guests:</h1>
        <%= for guest <- @invite.guests do %>
          <.live_component module={RSVP} id={ "rsvp-#{guest.id}" } guest={guest} />
        <% end %>
      </section>
    <% end %>
    """
  end

  defp already_rsvped?(guests), do: Enum.any?(guests, fn %{rsvp: rsvp} -> rsvp != nil end)
end
