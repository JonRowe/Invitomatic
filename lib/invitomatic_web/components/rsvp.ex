defmodule InvitomaticWeb.Components.RSVP do
  use InvitomaticWeb, :live_component

  alias Invitomatic.Invites
  alias Invitomatic.Menu

  @rsvp_options [
    {"Please select your rsvp...", ""},
    {"Yes I'm going", :yes},
    {"Sadly I can't make it", :no},
    {"I'm not sure", :maybe}
  ]

  @impl Phoenix.LiveComponent
  def handle_event("rsvp", %{"guest" => params}, %{assigns: %{guest: guest}} = socket) do
    {:noreply, update_guest(socket, guest, params, &rsvp_message/1)}
  end

  def handle_event("save_menu_option", %{"guest" => params}, %{assigns: %{guest: guest}} = socket) do
    {:noreply, update_guest(socket, guest, params, &menu_message/1)}
  end

  # Suppress a submit event on a form
  def handle_event("do_nothing", _params, socket), do: {:noreply, socket}

  @impl Phoenix.LiveComponent
  def mount(socket) do
    menu = Enum.map(Menu.list(), &{&1.name, &1.id})
    {:ok, socket |> assign(menu_options: menu, rsvp_options: @rsvp_options)}
  end

  @impl Phoenix.LiveComponent
  def update(%{guest: guest} = assigns, socket) do
    {:ok, socket |> assign(assigns) |> assign(form: Invites.change_guest(guest, %{}))}
  end

  @impl Phoenix.LiveComponent
  def render(assigns) do
    ~H"""
    <section class="rsvp" id={@id}>
      <.simple_form :let={form} for={@form} phx-target={@myself} phx-submit="do_nothing">
        <.input
          field={form[:rsvp]}
          id={ "guest-rsvp-#{@guest.id}-rsvp" }
          label={@guest.name}
          options={@rsvp_options}
          phx-change="rsvp"
          phx-target={@myself}
          type="select"
        />
        <.input
          :if={@guest.rsvp in [:yes, :maybe]}
          field={form[:menu_option_id]}
          id={ "guest-rsvp-#{@guest.id}-menu" }
          label="Menu Choice"
          options={@menu_options}
          phx-change="save_menu_option"
          phx-target={@myself}
          prompt="Please select a menu option"
          type="select"
        />
        <:actions></:actions>
      </.simple_form>
    </section>
    """
  end

  defp menu_message(_guest), do: "Menu choice saved!"

  defp rsvp_message(%{rsvp: :yes} = guest), do: "#{guest.name} is going!"
  defp rsvp_message(%{rsvp: :maybe} = guest), do: "We hope #{guest.name} can make it, please let us know asap."
  defp rsvp_message(%{rsvp: :no} = guest), do: "We're sorry #{guest.name} can't make it :("

  defp update_guest(socket, guest, params, message_generator) do
    with {:ok, updated_guest} <- Invites.update_guest(guest, params) do
      send(self(), {:rsvp, message_generator.(updated_guest)})

      assign(socket, guest: updated_guest, form: Invites.change_guest(updated_guest, %{}))
    else
      {:error, changeset} ->
        send(self(), {:error, "Something went wrong..."})

        assign(socket, form: changeset)
    end
  end
end
