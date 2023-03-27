defmodule InvitomaticWeb.Live.InvitiationManager.GuestComponent do
  use InvitomaticWeb, :html

  attr :guest, :map

  def show(assigns) do
    ~H"""
    <div>
      <.header>
        Guest
      </.header>
    </div>
    """
  end
end
