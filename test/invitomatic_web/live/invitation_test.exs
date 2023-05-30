defmodule InvitomaticWeb.Live.InvitationTest do
  use InvitomaticWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import Invitomatic.InvitesFixtures
  import Invitomatic.ContentFixtures

  describe "landing page" do
    setup do
      %{guests: [guest | _], logins: [login | _]} = invite = invite_fixture()
      %{guest: guest, invite: invite, login: login}
    end

    test "displays invitation content", %{conn: conn, invite: invite, login: login} do
      content_fixture(text: "# Hi <%= @invite.name %>\nSome Text", type: :invitation)

      {:ok, _index_live, html} = live(log_in(conn, login), ~p"/")

      assert html =~ "Hi #{invite.name}"
      assert html =~ "Some Text"
    end

    test "redirects if not logged in", %{conn: conn} do
      assert {:error, redirect} = live(conn, ~p"/")

      assert {:redirect, %{to: path, flash: flash}} = redirect
      assert path == ~p"/log_in"
      assert %{"error" => "You must log in to access this page."} = flash
    end
  end
end
