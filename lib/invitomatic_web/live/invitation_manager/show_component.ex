defmodule InvitomaticWeb.Live.InvitiationManager.ShowComponent do
  use InvitomaticWeb, :html

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
        <:item title="Emails that can login to the invite">
          <%= for login <- @invite.logins do %>
            <%= login.email %><br />
          <% end %>
        </:item>
        <:item title="Guests for this invite">
          <.table id={"invite-#{@invite.id}-guests"} rows={@invite.guests}>
            <:col :let={guest} label="Name"><%= guest.name %></:col>
            <:col :let={guest} label="Age"><%= guest.age %></:col>
            <:col :let={guest} label="RSVP"><%= guest.rsvp %></:col>
          </.table>
        </:item>
      </.list>
    </div>
    """
  end
end