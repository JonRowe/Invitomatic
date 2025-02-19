defmodule InvitomaticWeb.Live.MenuManager.ShowComponent do
  use InvitomaticWeb, :live_component

  @impl Phoenix.LiveComponent
  def render(assigns) do
    ~H"""
    <div>
      <.header>
        {@option.name}
      </.header>

      <.list>
        <:item title="Age group">{@option.age_group}</:item>
        <:item title="Course">{@option.course}</:item>
        <:item title="Order">{@option.order}</:item>
      </.list>
      <.link patch={~p"/manage/menu/#{@option}/edit?return_to=show"} class="button">
        Edit
      </.link>
    </div>
    """
  end
end
