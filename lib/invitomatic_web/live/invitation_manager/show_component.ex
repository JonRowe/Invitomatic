defmodule InvitomaticWeb.Live.InvitiationManager.ShowComponent do
  use InvitomaticWeb, :html

  alias Invitomatic.Menu.Option

  attr :invite, :map

  def details(assigns) do
    ~H"""
    <div>
      <.header>
        Invite
      </.header>
      <.list>
        <:item title="Name for invite">
          <%= @invite.name %>
        </:item>
        <:item title="Extra content">
          <%= @invite.extra_content %>
        </:item>
        <:item title="Emails that can login to the invite">
          <%= for login <- @invite.logins do %>
            <%= login.email %>
            <a phx-click="send_invite_to_email" phx-value-email={login.email} phx-value-id={@invite.id}>
              <%= if @invite.sent_at, do: "Resend", else: "Send" %> invite.
            </a>
            <br />
          <% end %>
        </:item>
        <:item title="Guests for this invite">
          <.table id={"invite-#{@invite.id}-guests"} rows={@invite.guests}>
            <:col :let={guest} label="Name"><%= guest.name %></:col>
            <:col :let={guest} label="Age"><%= guest.age %></:col>
            <:col :let={guest} label="RSVP"><%= guest.rsvp %></:col>
            <:col :let={guest} :for={{course_name, course} <- Option.enum_options(:course)} label={course_name}>
              <%= if Map.get(guest, course), do: Map.get(guest, course).name, else: "Not picked" %>
            </:col>
          </.table>
        </:item>
      </.list>
    </div>
    """
  end
end
