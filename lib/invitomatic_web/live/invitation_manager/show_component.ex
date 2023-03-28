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
          <%= for _guest <- [] do %>
          <% end %>
        </:item>
      </.list>
    </div>
    """
  end
end
