defmodule InvitomaticWeb.Live.InvitationTest do
  use InvitomaticWeb.ConnCase, async: true

  alias Invitomatic.Invites

  import Phoenix.LiveViewTest
  import Invitomatic.InvitesFixtures
  import Invitomatic.ContentFixtures
  import Invitomatic.MenuFixtures

  describe "landing page" do
    setup do
      content_fixture(text: "# Hi <%= @invite.name %>\nSome Text", type: :rsvp)

      guest_attrs = [
        valid_guest_attributes(age: :adult),
        valid_guest_attributes(age: :adult),
        valid_guest_attributes(age: :child),
        valid_guest_attributes(age: :under_three)
      ]

      %{guests: [guest | _], logins: [login | _]} = invite = invite_fixture(%{guests: guest_attrs})

      %{guest: guest, invite: invite, login: login}
    end

    test "displays invitation content", %{conn: conn, invite: invite, login: login} do
      {:ok, _index_live, html} = live(log_in(conn, login), ~p"/")

      assert html =~ "Hi #{invite.name}"
      assert html =~ "Some Text"
    end

    test "displays an invitations extra content", %{conn: conn, invite: invite, login: login} do
      content_fixture(text: "You can stay with us.", type: :accommodation)
      session = log_in(conn, login)

      {:ok, _index_live, html} = live(session, ~p"/")
      refute html =~ "You can stay with us."

      Invites.update(invite, %{extra_content: :accommodation})

      {:ok, _index_live, updated_html} = live(session, ~p"/")
      assert updated_html =~ "You can stay with us."
    end

    test "if you've not rsvp'd it invites you to rsvp", %{conn: conn, invite: invite, login: login} do
      %{guests: [guest_one, guest_two, guest_three, guest_four]} = invite

      {:ok, index_live, _html} = live(log_in(conn, login), ~p"/")

      index_live
      |> element("button", ~r/rsvp/i)
      |> render_click()

      index_live
      |> element("#guest-rsvp-#{guest_one.id}-rsvp")
      |> render_change(%{guest: %{rsvp: :yes}})

      assert render(index_live) =~ "#{guest_one.name} is going!"
      assert Invites.get_guest(invite, guest_one.id).rsvp == :yes

      index_live
      |> element("#guest-rsvp-#{guest_two.id}-rsvp")
      |> render_change(%{guest: %{rsvp: :maybe}})

      assert render(index_live) =~ "We hope #{guest_two.name} can make it, please let us know asap"
      assert Invites.get_guest(invite, guest_two.id).rsvp == :maybe

      index_live
      |> element("#guest-rsvp-#{guest_three.id}-rsvp")
      |> render_change(%{guest: %{rsvp: :yes}})

      assert render(index_live) =~ "#{guest_three.name} is going!"
      assert Invites.get_guest(invite, guest_three.id).rsvp == :yes

      index_live
      |> element("#guest-rsvp-#{guest_four.id}-rsvp")
      |> render_change(%{guest: %{rsvp: :no}})

      result = render(index_live)

      assert result =~ "We&#39;re sorry #{guest_four.name} can&#39;t make it :("
      assert Invites.get_guest(invite, guest_four.id).rsvp == :no
    end

    test "if you've rsvp'd you can set food choices", %{conn: conn, invite: invite, login: login} do
      %{guests: [guest | _]} = invite

      menu_option_one = menu_option_fixture()
      menu_option_two = menu_option_fixture()

      {:ok, index_live, _html} = live(log_in(conn, login), ~p"/")

      rsvp_form =
        index_live
        |> element("button", ~r/rsvp/i)
        |> render_click()

      refute rsvp_form =~ menu_option_one.name
      refute rsvp_form =~ menu_option_two.name

      rsvp_set_form =
        index_live
        |> element("#guest-rsvp-#{guest.id}-rsvp")
        |> render_change(%{guest: %{rsvp: :yes}})

      assert rsvp_set_form =~ menu_option_one.name
      assert rsvp_set_form =~ menu_option_two.name

      index_live
      |> element("#guest-rsvp-#{guest.id}-menu")
      |> render_change(%{guest: %{menu_option_id: menu_option_one.id}})

      assert Invites.get_guest(invite, guest.id).menu_option == menu_option_one
    end

    test "guests can change their details", %{conn: conn, invite: invite, login: login} do
      %{guests: [guest | _]} = invite

      {:ok, index_live, _html} = live(log_in(conn, login), ~p"/")

      index_live
      |> element("button", ~r/rsvp/i)
      |> render_click()

      assert index_live
             |> element("#rsvp-#{guest.id} a[role=\"edit-guest\"]")
             |> render_click() =~ "Edit Guest Details"

      index_live
      |> form("#edit-guest-#{guest.id}-form", guest: %{name: "New Name", age: :under_three})
      |> render_submit()

      assert %Invites.Guest{name: "New Name", age: :under_three} = Invites.get_guest(invite, guest.id)
      assert render(index_live) =~ ~r/Success!/
      assert render(index_live) =~ ~r/New Name/
    end

    test "guests can set dietary requirements", %{conn: conn, invite: invite, login: login} do
      %{guests: [guest | _]} = invite

      {:ok, index_live, _html} = live(log_in(conn, login), ~p"/")

      index_live
      |> element("button", ~r/rsvp/i)
      |> render_click()

      index_live
      |> element("#guest-rsvp-#{guest.id}-rsvp")
      |> render_change(%{guest: %{rsvp: :yes}})

      index_live
      |> element("#rsvp-#{guest.id} button")
      |> render_click()

      index_live
      |> form(
        "#rsvp-#{guest.id} form[phx-submit=\"save_dietary_requirements\"]",
        guest: %{dietary_requirements: "Vegan"}
      )
      |> render_submit()

      assert %Invites.Guest{dietary_requirements: "Vegan"} = Invites.get_guest(invite, guest.id)
      assert render(index_live) =~ ~r/Success!/

      assert render(element(index_live, "*[phx-feedback-for=\"guest[dietary_requirements]\"]")) =~
               ~r/Dietary Requirements(.*\n)*Vegan/
    end

    test "redirects if not logged in", %{conn: conn} do
      assert {:error, redirect} = live(conn, ~p"/")

      assert {:redirect, %{to: path, flash: flash}} = redirect
      assert path == ~p"/log_in"
      assert %{"error" => "You must log in to access this page."} = flash
    end
  end
end
