defmodule InvitomaticWeb.Live.InvitiationManager.FormComponent do
  use InvitomaticWeb, :live_component

  alias Invitomatic.Invites
  alias Invitomatic.Invites.Guest

  @impl Phoenix.LiveComponent
  def handle_event("add_guest", _, %{assigns: %{form: %{source: changeset}}} = socket) do
    guests = get_change_or_field(changeset, :guests)

    {:noreply, assign_form(socket, Ecto.Changeset.put_assoc(changeset, :guests, guests ++ [%{}]))}
  end

  def handle_event("remove_guest", %{"index" => string_index}, %{assigns: %{form: %{source: changeset}}} = socket) do
    index = String.to_integer(string_index)

    guests = get_change_or_field(changeset, :guests)

    {:noreply, assign_form(socket, Ecto.Changeset.put_assoc(changeset, :guests, List.delete_at(guests, index)))}
  end

  def handle_event("validate", %{"invite" => invite_params}, socket) do
    changeset =
      socket.assigns.invite
      |> Invites.change(invite_params)
      |> Map.put(:action, :validate)

    {:noreply, assign_form(socket, changeset)}
  end

  def handle_event("save", %{"invite" => invite_params}, socket) do
    save_invite(socket, socket.assigns.action, invite_params)
  end

  @impl Phoenix.LiveComponent
  def render(assigns) do
    ~H"""
    <div>
      <.header>
        <%= @title %>
      </.header>

      <.simple_form for={@form} id="invite-form" phx-target={@myself} phx-change="validate" phx-submit="save">
        <.inputs_for :let={form} field={@form[:logins]}>
          <.input field={form[:email]} label="Email" />
        </.inputs_for>
        <.input field={@form[:name]} label="Invite name" />
        <.inputs_for :let={form} field={@form[:guests]}>
          <div class="guest">
            <div class="name">
              <.input field={form[:name]} label="Name" />
            </div>
            <div class="age">
              <.input field={form[:age]} label="Age" type="select" options={enum(:age)} />
            </div>
            <.button phx-click="remove_guest" phx-value-index={form.index} phx-target={@myself} type="button">
              X
            </.button>
          </div>
        </.inputs_for>
        <.button phx-click="add_guest" phx-target={@myself} type="button">Add Guest</.button>
        <hr />
        <:actions>
          <.button type="submit" phx-disable-with="Saving...">Save</.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  @impl Phoenix.LiveComponent
  def update(%{invite: invite} = assigns, socket) do
    changeset = Invites.change(invite)

    {:ok,
     socket
     |> assign(assigns)
     |> assign_form(changeset)}
  end

  defp assign_form(socket, %Ecto.Changeset{} = changeset) do
    assign(socket, :form, to_form(changeset, as: "invite"))
  end

  defp enum(field) do
    Guest
    |> Ecto.Enum.values(field)
    |> Enum.map(&{String.capitalize(String.replace(to_string(&1), "_", " ")), &1})
  end

  defp get_change_or_field(changeset, field, default \\ []) do
    with nil <- Ecto.Changeset.get_change(changeset, field) do
      Ecto.Changeset.get_field(changeset, field, default)
    end
  end

  defp notify_parent(msg), do: send(self(), {__MODULE__, msg})

  defp save_invite(socket, :edit, invite_params) do
    case Invites.update(socket.assigns.invite, invite_params) do
      {:ok, invite} ->
        notify_parent({:saved, invite})

        {:noreply,
         socket
         |> put_flash(:info, "Invite updated successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  defp save_invite(socket, :new, invite_params) do
    case Invites.create(invite_params) do
      {:ok, invite} ->
        notify_parent({:saved, invite})

        {:noreply,
         socket
         |> put_flash(:info, "Invite created successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end
end
