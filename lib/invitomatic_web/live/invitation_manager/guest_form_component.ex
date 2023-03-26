defmodule InvitomaticWeb.Live.InvitiationManager.GuestFormComponent do
  use InvitomaticWeb, :live_component

  alias Invitomatic.Guests

  @impl Phoenix.LiveComponent
  def handle_event("validate", %{"guest" => guest_params}, socket) do
    changeset =
      socket.assigns.guest
      |> Guests.change(guest_params)
      |> Map.put(:action, :validate)

    {:noreply, assign_form(socket, changeset)}
  end

  def handle_event("save", %{"guest" => guest_params}, socket) do
    save_guest(socket, socket.assigns.action, guest_params)
  end

  @impl Phoenix.LiveComponent
  def render(assigns) do
    ~H"""
    <div>
      <.header>
        <%= @title %>
        <:subtitle>Use this form to manage guest records in your database.</:subtitle>
      </.header>

      <.simple_form
        for={@form}
        id="guest-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >
        <.input field={@form[:email]} label="Email" />
        <:actions>
          <.button phx-disable-with="Saving...">Save Guest</.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  @impl Phoenix.LiveComponent
  def update(%{guest: guest} = assigns, socket) do
    changeset = Guests.change(guest)

    {:ok,
     socket
     |> assign(assigns)
     |> assign_form(changeset)}
  end

  defp assign_form(socket, %Ecto.Changeset{} = changeset) do
    assign(socket, :form, to_form(changeset, as: "guest"))
  end

  defp notify_parent(msg), do: send(self(), {__MODULE__, msg})

  defp save_guest(socket, :edit, guest_params) do
    case Guests.update(socket.assigns.guest, guest_params) do
      {:ok, guest} ->
        notify_parent({:saved, guest})

        {:noreply,
         socket
         |> put_flash(:info, "Guest updated successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  defp save_guest(socket, :new, guest_params) do
    case Guests.create(guest_params) do
      {:ok, guest} ->
        notify_parent({:saved, guest})

        {:noreply,
         socket
         |> put_flash(:info, "Guest created successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end
end
