defmodule InvitomaticWeb.Live.InvitiationManager.FormComponent do
  use InvitomaticWeb, :live_component

  alias Invitomatic.Invites

  @impl Phoenix.LiveComponent
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
        <:actions>
          <.button phx-disable-with="Saving...">Save</.button>
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
