defmodule InvitomaticWeb.Live.InvitationManager do
  use InvitomaticWeb, :live_view

  alias Invitomatic.Guests

  @impl Phoenix.LiveView
  def mount(_params, _session, socket) do
    {:ok, stream(socket, :guests, Guests.list(), dom_id: &"guest-#{&1.id}")}
  end

  @impl Phoenix.LiveView
  def render(assigns) do
    ~H"""
    <h1>Invitation Management</h1>
    <.table id="guests" rows={@streams.guests}>
      <:col :let={{_id, guest}} label="EMail"><%= guest.email %></:col>
    </.table>
    """
  end
end
