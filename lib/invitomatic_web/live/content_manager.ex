defmodule InvitomaticWeb.Live.ContentManager do
  use InvitomaticWeb, :live_view

  alias Invitomatic.Content
  alias Invitomatic.Content.Section

  @impl Phoenix.LiveView
  def handle_event("delete", %{"id" => id}, socket) do
    section = Content.get_section!(id)
    {:ok, _} = Content.delete_section(section)

    {:noreply, stream_delete(socket, :content, section)}
  end

  @impl Phoenix.LiveView
  def handle_info({InvitomaticWeb.Live.ContentManager.FormComponent, {:saved, section}}, socket) do
    {:noreply, stream_insert(socket, :content, section)}
  end

  @impl Phoenix.LiveView
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  @impl Phoenix.LiveView
  def mount(_params, _session, socket) do
    {:ok, stream(socket, :content, Content.list())}
  end

  @impl Phoenix.LiveView
  def render(assigns) do
    ~H"""
    <.header>
      Listing Content
      <:actions>
        <.link patch={~p"/manage/content/new"}>
          <.button>New Content</.button>
        </.link>
      </:actions>
    </.header>

    <.table id="content" rows={@streams.content}>
      <:col :let={{_id, section}} label="Type"><%= section.type %></:col>
      <:col :let={{_id, section}} label="Index"><%= section.other_index %></:col>
      <:col :let={{_id, section}} label="Title"><%= section.title %></:col>
      <:col :let={{_id, section}} label="Slug"><%= section.slug %></:col>
      <:col :let={{_id, section}} label="Text"><%= section.text %></:col>
      <:action :let={{_id, section}}>
        <.link patch={~p"/manage/content/#{section}/edit"}>Edit</.link>
      </:action>
      <:action :let={{id, section}}>
        <.link phx-click={JS.push("delete", value: %{id: section.id}) |> hide("##{id}")} data-confirm="Are you sure?">
          Delete
        </.link>
      </:action>
    </.table>

    <.modal :if={@live_action in [:new, :edit]} id="content-modal" show on_cancel={JS.patch(~p"/manage/content")}>
      <.live_component
        module={InvitomaticWeb.Live.ContentManager.FormComponent}
        id={@section.id || :new}
        title={@page_title}
        action={@live_action}
        section={@section}
        patch={~p"/manage/content"}
      />
    </.modal>
    """
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    socket
    |> assign(:page_title, "Edit Section")
    |> assign(:section, Content.get_section!(id))
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "New Section")
    |> assign(:section, %Section{})
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Listing Section")
    |> assign(:section, nil)
  end
end
