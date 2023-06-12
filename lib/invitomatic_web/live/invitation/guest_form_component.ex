defmodule InvitomaticWeb.Live.Invitiation.GuestFormComponent do
  use InvitomaticWeb, :live_component

  alias Invitomatic.Invites
  alias Invitomatic.Invites.Guest

  @impl Phoenix.LiveComponent
  def handle_event("validate", %{"guest" => guest_params}, socket) do
    changeset =
      socket.assigns.guest
      |> Invites.change_guest(guest_params)
      |> Map.put(:action, :validate)

    {:noreply, assign_form(socket, changeset)}
  end

  def handle_event("save", %{"guest" => guest_params}, socket) do
    case Invites.update_guest(socket.assigns.guest, guest_params) do
      {:ok, guest} ->
        send(self(), {__MODULE__, {:updated, guest}})

        {:noreply,
         socket
         |> put_flash(:info, "Guest details updated successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  @impl Phoenix.LiveComponent
  def render(assigns) do
    ~H"""
    <div>
      <.header>
        Edit Guest Details
      </.header>

      <.simple_form
        for={@form}
        id={ "edit-guest-#{@guest.id}-form" }
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >
        <.input field={@form[:name]} label="Guest name" />
        <.input field={@form[:age]} label="Age" type="select" options={Guest.enum_options(:age)} />
        <:actions>
          <.button type="submit" phx-disable-with="Saving...">Save</.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  @impl Phoenix.LiveComponent
  def update(%{guest: guest} = assigns, socket) do
    changeset = Invites.change_guest(guest)

    {:ok,
     socket
     |> assign(assigns)
     |> assign_form(changeset)}
  end

  defp assign_form(socket, %Ecto.Changeset{} = changeset) do
    assign(socket, :form, to_form(changeset, as: "guest"))
  end
end
