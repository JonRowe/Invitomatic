defmodule InvitomaticWeb.Live.MenuManager do
  use InvitomaticWeb, :live_view

  alias Invitomatic.Menu
  alias Invitomatic.Menu.Option

  @impl Phoenix.LiveView
  def handle_event("delete", %{"id" => id}, socket) do
    option = Menu.get_option!(id)
    {:ok, _} = Menu.delete_option(option)

    {:noreply, stream_delete(socket, :options, option)}
  end

  @impl Phoenix.LiveView
  def handle_info({InvitomaticWeb.Live.MenuManager.FormComponent, {:saved, option}}, socket) do
    {:noreply, stream_insert(socket, :options, option)}
  end

  @impl Phoenix.LiveView
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  @impl Phoenix.LiveView
  def mount(_params, _session, socket) do
    options = Menu.list()

    {:ok,
     socket
     |> assign(:order, length(options))
     |> stream(:options, options, dom_id: &"option-#{&1.id}")}
  end

  @impl Phoenix.LiveView
  def render(assigns) do
    ~H"""
    <.header>
      Menu Options
      <:actions>
        <.link patch={~p"/manage/menu/new"}>
          <.button>New Option</.button>
        </.link>
      </:actions>
    </.header>

    <.table id="option" rows={@streams.options} row_click={fn {_id, option} -> JS.patch(~p"/manage/menu/#{option}") end}>
      <:col :let={{_id, option}} label="Title"><%= option.name %></:col>
      <:col :let={{_id, option}} label="Description"><%= option.description %></:col>
      <:col :let={{_id, option}} label="Order"><%= option.order %></:col>
      <:action :let={{_id, option}}>
        <div class="sr-only">
          <.link patch={~p"/manage/menu/#{option}"}>Show</.link>
        </div>
        <.link patch={~p"/manage/menu/#{option}/edit"}>Edit</.link>
      </:action>
      <:action :let={{id, option}}>
        <.link phx-click={JS.push("delete", value: %{id: option.id}) |> hide("##{id}")} data-confirm="Are you sure?">
          Delete
        </.link>
      </:action>
    </.table>
    <.modal :if={@live_action == :show} id="option-modal" show on_cancel={JS.patch(~p"/manage/menu")}>
      <InvitomaticWeb.Live.MenuManager.ShowComponent.render option={@option} />
    </.modal>
    <.modal :if={@live_action in [:new, :edit]} id="option-modal" show on_cancel={JS.patch(~p"/manage/menu")}>
      <.live_component
        module={InvitomaticWeb.Live.MenuManager.FormComponent}
        id={@option.id || :new}
        title={@page_title}
        action={@live_action}
        option={@option}
        order={@order}
        patch={@modal_submit_patch}
      />
    </.modal>
    """
  end

  defp apply_action(socket, :edit, %{"id" => id, "return_to" => "show"}) do
    socket
    |> apply_action(:edit, %{"id" => id})
    |> assign(:modal_submit_patch, ~p"/manage/menu/#{id}")
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    socket
    |> assign(:page_title, "Edit Option")
    |> assign(:modal_submit_patch, ~p"/manage/menu")
    |> assign(:option, Menu.get_option!(id))
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Listing Menu")
    |> assign(:option, nil)
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "New Option")
    |> assign(:modal_submit_patch, ~p"/manage/menu")
    |> assign(:option, %Option{})
  end

  defp apply_action(socket, :show, %{"id" => id}) do
    socket
    |> assign(:page_title, "Invitation")
    |> assign(:modal_submit_patch, ~p"/manage/menu/#{id}")
    |> assign(:option, Menu.get_option!(id))
  end
end
