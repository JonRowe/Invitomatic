defmodule InvitomaticWeb.ComponentCase do
  @moduledoc """
  This module defines the test case to be used by
  test for components.

  If the test case interacts with the database,
  we enable the SQL sandbox, so changes done to the database
  are reverted at the end of every test. If you are using
  PostgreSQL, you can even run database tests asynchronously
  by setting `use InvitomaticWeb.ComponentCase, async: true`, although
  this option is not recommended for other databases.
  """

  use ExUnit.CaseTemplate

  using do
    quote do
      use InvitomaticWeb, :verified_routes

      import InvitomaticWeb.ComponentCase
      import InvitomaticWeb.ConnCase, only: [socket: 0, socket: 1]
      import Phoenix.LiveViewTest, only: [render_component: 2, render_component: 3]
    end
  end

  setup tags do
    Invitomatic.DataCase.setup_sandbox(tags)
    :ok
  end
end
