defmodule InvitomaticWeb.Components.RSVP do
  use InvitomaticWeb, :live_component

  alias Invitomatic.Invites

  @rsvp_options [
    {"Please select your rsvp...", ""},
    {"Yes I'm going", :yes},
    {"Sadly I can't make it", :no},
    {"I'm not sure", :maybe}
  ]

  @impl Phoenix.LiveComponent
  def handle_event("rsvp", %{"guest" => params}, %{assigns: %{guest: guest}} = socket) do
    updated_socket =
      with {:ok, %{rsvp: rsvp} = updated_guest} <- Invites.set_rsvp(guest, params) do
        send(self(), {:rsvp, rsvp_message(updated_guest, rsvp)})

        assign(socket, guest: updated_guest, form: Invites.change_rsvp(updated_guest, %{}))
      else
        {:error, changeset} ->
          send(self(), {:error, "Something went wrong..."})

          assign(socket, form: changeset)
      end

    {:noreply, updated_socket}
  end

  @impl Phoenix.LiveComponent
  def mount(socket) do
    {:ok, socket |> assign(rsvp_options: @rsvp_options)}
  end

  @impl Phoenix.LiveComponent
  def update(%{guest: guest} = assigns, socket) do
    {:ok, socket |> assign(assigns) |> assign(form: Invites.change_rsvp(guest, %{}))}
  end

  @impl Phoenix.LiveComponent
  def render(assigns) do
    ~H"""
    <section class="rsvp" id={@id}>
      <.simple_form :let={form} for={@form} phx-target={@myself} phx-change="rsvp">
        <.input field={form[:rsvp]} label={@guest.name} options={@rsvp_options} type="select" />
        <:actions></:actions>
      </.simple_form>
    </section>
    """
  end

  defp rsvp_message(guest, :yes), do: "#{guest.name} is going!"
  defp rsvp_message(guest, :maybe), do: "We hope #{guest.name} can make it, please let us know asap."
  defp rsvp_message(guest, :no), do: "We're sorry #{guest.name} can't make it :("
end
