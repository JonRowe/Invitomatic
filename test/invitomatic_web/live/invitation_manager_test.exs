defmodule InvitomaticWeb.Live.InvitationManagerTest do
  use InvitomaticWeb.ConnCase

  import Phoenix.LiveViewTest
  import Invitomatic.AccountsFixtures
  import Invitomatic.InvitesFixtures

  alias Invitomatic.Accounts.Login
  alias Invitomatic.Repo

  @invite_create_attrs %{
    "name" => "Namey McName",
    "guests" => %{"0" => %{"name" => "Name", "age" => "adult"}},
    "logins" => %{"0" => %{"email" => "another@example.com"}}
  }
  @invite_update_attrs %{
    "name" => "Janey McName",
    "logins" => %{"0" => %{"email" => "new@example.com"}}
  }
  @invite_multiple_guest_attrs %{
    "name" => "Namey McName",
    "guests" => %{
      "0" => %{"name" => "Name 1", "age" => "adult"},
      "1" => %{"name" => "Name 2", "age" => "adult"},
      "2" => %{"name" => "Name 3", "age" => "child"}
    },
    "logins" => %{"0" => %{"email" => "another@example.com"}}
  }
  @invite_invalid_attrs %{"name" => "", "logins" => %{"0" => %{"email" => ""}}}

  describe "Management page" do
    setup do
      invite = invite_fixture()
      %{invite: invite, guest: List.first(invite.logins)}
    end

    test "renders the index table", %{conn: conn} do
      guest_fixture(email: "invitee_1@example.com")
      guest_fixture(email: "invitee_2@example.com")

      {:ok, _lv, html} =
        conn
        |> log_in(admin_fixture())
        |> live(~p"/manage")

      assert html =~ "Invitation Management"
      assert html =~ "invitee_1@example.com"
      assert html =~ "invitee_2@example.com"
    end

    test "redirects if not an admin", %{conn: conn} do
      assert {:error, redirect} = live(log_in(conn, login_fixture()), ~p"/manage")

      assert {:redirect, %{to: path, flash: flash}} = redirect
      assert path == ~p"/"
      assert %{"error" => "You cannot access this page."} = flash
    end

    test "redirects if not logged in", %{conn: conn} do
      assert {:error, redirect} = live(conn, ~p"/settings")

      assert {:redirect, %{to: path, flash: flash}} = redirect
      assert path == ~p"/log_in"
      assert %{"error" => "You must log in to access this page."} = flash
    end

    test "it can display a guest", %{conn: conn, guest: guest, invite: invite} do
      {:ok, index_live, _html} = live(log_in(conn, admin_fixture()), ~p"/manage")

      result =
        index_live
        |> element("#guest-#{guest.id} td:last-child a", "Show")
        |> render_click()

      assert result =~ "Invitation"
      assert_patch(index_live, ~p"/manage/invites/#{invite}")
    end

    test "it can create a new invite", %{conn: conn} do
      {:ok, index_live, _html} = live(log_in(conn, admin_fixture()), ~p"/manage")

      assert index_live |> element("a", "New Invite") |> render_click() =~
               "New Invite"

      assert_patch(index_live, ~p"/manage/invites/new")

      assert index_live
             |> form("#invite-form", invite: @invite_invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert index_live
             |> form("#invite-form", invite: @invite_create_attrs)
             |> render_submit()

      assert_patch(index_live, ~p"/manage")

      html = render(index_live)
      assert html =~ "Invite created successfully"
    end

    test "it can update a invite", %{conn: conn, guest: guest, invite: invite} do
      {:ok, index_live, _html} = live(log_in(conn, admin_fixture()), ~p"/manage")

      assert index_live |> element("#guest-#{guest.id} a", "Edit") |> render_click() =~
               "Edit Invite"

      assert_patch(index_live, ~p"/manage/invites/#{invite}/edit")

      assert index_live
             |> form("#invite-form", invite: @invite_invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert index_live
             |> form("#invite-form", invite: @invite_update_attrs)
             |> render_submit()

      assert_patch(index_live, ~p"/manage")

      html = render(index_live)
      assert html =~ "Invite updated successfully"
    end

    test "it can add multiple guests to a new invite", %{conn: conn} do
      {:ok, index_live, _html} = live(log_in(conn, admin_fixture()), ~p"/manage")

      assert index_live |> element("a", "New Invite") |> render_click() =~
               "New Invite"

      assert_patch(index_live, ~p"/manage/invites/new")

      assert index_live |> element("button", "Add Guest") |> render_click()
      assert index_live |> element("button", "Add Guest") |> render_click()

      assert index_live
             |> form("#invite-form", invite: @invite_multiple_guest_attrs)
             |> render_submit()

      assert_patch(index_live, ~p"/manage")

      html = render(index_live)
      assert html =~ "Invite created successfully"
      assert length(get_invite(email: "another@example.com").guests) == 3
    end

    test "it can manipulate guests on an invite", %{conn: conn, guest: guest} do
      {:ok, index_live, _html} = live(log_in(conn, admin_fixture()), ~p"/manage")

      assert index_live |> element("#guest-#{guest.id} a", "Edit") |> render_click() =~
               "Edit Invite"

      assert index_live |> element("button", "Add Guest") |> render_click()
      assert index_live |> element("button", "Add Guest") |> render_click()

      assert index_live
             |> form("#invite-form", invite: %{"guests" => @invite_multiple_guest_attrs["guests"]})
             |> render_submit()

      assert length(get_invite(email: guest.email).guests) == 3

      assert index_live |> element("#guest-#{guest.id} a", "Edit") |> render_click() =~
               "Edit Invite"

      assert index_live |> element("button[phx-value-index=1]", "X") |> render_click()
      assert index_live |> form("#invite-form") |> render_submit()

      assert [guest_one, guest_two] = get_invite(email: guest.email).guests
      assert guest_one.name == "Name 1"
      assert guest_two.name == "Name 3"
    end

    test "it can delete a guest in listing", %{conn: conn, guest: guest} do
      {:ok, index_live, _html} = live(log_in(conn, admin_fixture()), ~p"/manage")

      assert index_live |> element("#guest-#{guest.id} a", "Delete") |> render_click()
      refute has_element?(index_live, "#guest-#{guest.id}")
    end
  end

  defp get_invite(attrs), do: Repo.preload(Repo.get_by(Login, attrs), invite: [:guests]).invite
end
