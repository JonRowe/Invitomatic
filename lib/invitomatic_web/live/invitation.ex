defmodule InvitomaticWeb.Live.Invitation do
  use InvitomaticWeb, :live_view

  alias Invitomatic.Content
  alias Invitomatic.Invites
  alias InvitomaticWeb.Components.Content, as: ContentComponent

  @impl Phoenix.LiveView
  def mount(_session, _params, socket) do
    invite = Invites.get_for(socket.assigns.current_login)
    [content] = Content.get(:invitation)
    {:ok, assign(socket, content: content, invite: invite)}
  end

  @impl Phoenix.LiveView
  def render(assigns) do
    ~H"""
    <ContentComponent.render content={@content} invite={@invite} />
    """
  end
end
