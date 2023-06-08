defmodule InvitomaticWeb.Live.ContentManager.FormComponent do
  use InvitomaticWeb, :live_component

  alias Invitomatic.Content

  @impl Phoenix.LiveComponent
  def handle_event("save", %{"section" => section_params}, socket) do
    save_section(socket, socket.assigns.action, section_params)
  end

  def handle_event("validate", %{"section" => section_params}, socket) do
    changeset =
      socket.assigns.section
      |> Content.change_section(section_params)
      |> Map.put(:action, :validate)

    {:noreply, assign_form(socket, changeset)}
  end

  @impl Phoenix.LiveComponent
  def render(assigns) do
    ~H"""
    <div>
      <.header>
        <%= @title %>
        <:subtitle>Use this form to manage section records in your database.</:subtitle>
      </.header>

      <.simple_form for={@form} id="content-form" phx-target={@myself} phx-change="validate" phx-submit="save">
        <.input field={@form[:text]} type="textarea" label="Text" />
        <.input field={@form[:type]} type="select" options={@content_types} label="Type" />
        <:actions>
          <.button phx-disable-with="Saving...">Save Content</.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  @impl Phoenix.LiveComponent
  def mount(socket) do
    {:ok, assign(socket, content_types: Ecto.Enum.values(Content.Section, :type))}
  end

  @impl Phoenix.LiveComponent
  def update(%{section: section} = assigns, socket) do
    changeset = Content.change_section(section)

    {:ok,
     socket
     |> assign(assigns)
     |> assign_form(changeset)}
  end

  defp save_section(socket, :edit, section_params) do
    case Content.update_section(socket.assigns.section, section_params) do
      {:ok, section} ->
        notify_parent({:saved, section})

        {:noreply,
         socket
         |> put_flash(:info, "Content updated successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  defp save_section(socket, :new, section_params) do
    case Content.create_section(section_params) do
      {:ok, section} ->
        notify_parent({:saved, section})

        {:noreply,
         socket
         |> put_flash(:info, "Content created successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  defp assign_form(socket, %Ecto.Changeset{} = changeset) do
    assign(socket, :form, to_form(changeset))
  end

  defp notify_parent(msg), do: send(self(), {__MODULE__, msg})
end
