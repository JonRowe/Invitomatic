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
    section = %Section{text: "# Hi <%= @name %>!"}

    assert render_component(&Content.render/1, content: section, name: "Name") =~
             "<h1>Hi Name!</h1>"
  end
end
