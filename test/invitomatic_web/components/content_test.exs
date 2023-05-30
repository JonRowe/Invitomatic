defmodule InvitomaticWeb.Components.ContentTest do
  use InvitomaticWeb.ComponentCase, async: true

  alias Invitomatic.Content.Section
  alias InvitomaticWeb.Components.Content

  test "it renders markdown content" do
    section = %Section{
      text: """
      # A title

      Some text.
      """
    }

    assert render_component(&Content.render/1, content: section) =~
             "<h1>A title</h1>\n<p>Some text.</p>"
  end

  test "it renders markdown content with heex assigns" do
    section = %Section{
      text: """
      # Hi <%= @person.name %>!

      <%= @more %>
      """
    }

    assert render_component(&Content.render/1, content: section, person: %{name: "Name"}, more: "Lets go!") =~
             "<h1>Hi Name!</h1>\n<p>Lets go!</p>"
  end

  test "it handles missing heex assigns" do
    section = %Section{
      text: """
      # Hi <%= @name %>!

      <%=
        @multi_line.map
      %>
      """
    }

    assert render_component(&Content.render/1, content: section) =~ "<h1>Hi !</h1>\n<p></p>"
  end
end
