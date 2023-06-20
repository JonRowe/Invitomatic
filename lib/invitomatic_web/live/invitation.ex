defmodule InvitomaticWeb.Live.Invitation do
  use InvitomaticWeb, :live_view

  alias Invitomatic.Content
  alias Invitomatic.Invites
  alias InvitomaticWeb.Components.Content, as: ContentComponent
  alias InvitomaticWeb.Components.RSVP
  alias InvitomaticWeb.Live.Invitiation.GuestFormComponent

  @impl Phoenix.LiveView
  def handle_event("rsvp", _params, socket) do
    {:noreply, assign(socket, :open, true)}
  end

  @impl Phoenix.LiveView
  def handle_info({:rsvp, message}, socket) do
    {:noreply, socket |> put_flash(:info, message)}
  end

  def handle_info({GuestFormComponent, {:updated, _guest}}, socket) do
    socket
    |> assign(:page_title, "")
    |> assign(:guest, nil)
    |> assign(:invite, Invites.get_for(socket.assigns.current_login))
    |> put_flash(:info, "Updated guest details.")
    |> then(&{:noreply, &1})
  end

  def handle_info({:error, message}, socket), do: {:noreply, put_flash(socket, :error, message)}

  @impl Phoenix.LiveView
  def handle_params(%{"id" => id}, _url, %{assigns: %{invite: invite, live_action: :edit}} = socket) do
    socket
    |> assign(:page_title, "Edit Guest Details")
    |> assign(:guest, Invites.get_guest(invite, id))
    |> then(&{:noreply, &1})
  end

  def handle_params(%{"content" => slug}, url, %{assigns: %{other_content: other_content}} = socket) do
    if content = other_content[slug] do
      socket
      |> assign(:open, true)
      |> assign(:page_title, content.title)
      |> assign(:selected_content, content)
      |> then(&{:noreply, &1})
    else
      handle_params(%{}, url, socket)
    end
  end

  def handle_params(_params, _url, socket) do
    socket
    |> assign(:page_title, "")
    |> assign(:selected_content, nil)
    |> then(&{:noreply, &1})
  end

  @impl Phoenix.LiveView
  def mount(_session, _params, socket) do
    invite = Invites.get_for(socket.assigns.current_login)
    [content] = Content.get(:rsvp)

    extra_content =
      if invite.extra_content do
        [invite_extra_content] = Content.get(invite.extra_content)
        invite_extra_content
      end

    other_content = Enum.reduce(Content.get(:other), %{}, fn content, map -> Map.put(map, content.slug, content) end)

    socket
    |> assign(content: content, extra_content: extra_content, other_content: other_content, selected_content: nil)
    |> assign(invite: invite, open: already_rsvped?(invite.guests))
    |> then(&{:ok, &1})
  end

  @impl Phoenix.LiveView
  def render(assigns) do
    ~H"""
    <section class="content invite">
      <ContentComponent.render content={@content} invite={@invite} />
      <ContentComponent.render :if={@extra_content} content={@extra_content} invite={@invite} />
      <button :if={!@open} phx-click="rsvp" type="button">Enter</button>
    </section>
    <nav :if={@open} class="tabs">
      <.link patch={~p"/"} class="button">RSVP</.link>
      <%= for {slug, content} <- @other_content do %>
        <.link patch={~p"/#{slug}"} class="button"><%= content.title %></.link>
      <% end %>
    </nav>
    <%= if @open && !@selected_content do %>
      <section class="hero rsvp-group">
        <h1>Your Guests:</h1>
        <%= for guest <- @invite.guests do %>
          <.live_component module={RSVP} id={ "rsvp-#{guest.id}" } guest={guest} />
        <% end %>
      </section>
    <% end %>
    <section :if={@selected_content} class="content hero other">
      <ContentComponent.render content={@selected_content} invite={@invite} />
    </section>
    <.modal :if={@live_action == :edit} id="invite-guest-edit-form-modal" show on_cancel={JS.patch(~p"/")}>
      <.live_component module={GuestFormComponent} id={ "edit-guest-#{@guest.id}" } guest={@guest} patch={~p"/"} />
    </.modal>
    """
  end

  defp already_rsvped?(guests), do: Enum.any?(guests, fn %{rsvp: rsvp} -> rsvp != nil end)
end
