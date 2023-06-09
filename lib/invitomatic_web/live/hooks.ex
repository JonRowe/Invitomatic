defmodule InvitomaticWeb.Live.Hooks do
  use InvitomaticWeb, :verified_routes

  import Phoenix.Component, only: [assign: 3]

  def on_mount(:ensure_setup, _params, _session, socket) do
    {:cont, assign(socket, :modal_open, false)}
  end
end
