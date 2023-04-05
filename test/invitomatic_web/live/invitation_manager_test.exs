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
      invite_fixture(%{
        guests: [
          valid_guest_attributes(%{name: "Invite 1 Guest 1", rsvp: :yes}),
          valid_guest_attributes(%{name: "Invite 1 Guest 2", age: :child, rsvp: :maybe}),
          valid_guest_attributes(%{name: "Invite 1 Guest 3", age: :under_three, rsvp: :no})
        ],
        logins: [%{email: "invitee_1@example.com"}]
      })

      invite_fixture(%{
        guests: [
          valid_guest_attributes(%{name: "Invite 2 Guest 1"})
        ],
        logins: [%{email: "invitee_2@example.com"}]
      })

      {:ok, view, html} =
        conn
        |> log_in(admin_fixture())
        |> live(~p"/manage")

      assert html =~ "Invitation Management"

      invite_1_rows = render_rows(element(view, "tbody", "invitee_1@example.com"))

      assert render_row(invite_1_rows, "Invite 1 Guest 1") =~ "Invite 1 Guest 1 | Adult | Yes"
      assert render_row(invite_1_rows, "Invite 1 Guest 2") =~ "Invite 1 Guest 2 | Child | Maybe"
      assert render_row(invite_1_rows, "Invite 1 Guest 3") =~ "Invite 1 Guest 3 | < 3 | No"

      invite_2_rows = render_rows(element(view, "tbody", "invitee_2@example.com"))
      assert render_row(invite_2_rows, "Invite 2 Guest 1") =~ "Invite 2 Guest 1 | Adult | Not replied"
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

    test "it can display an invite", %{conn: conn, invite: invite} do
      {:ok, index_live, _html} = live(log_in(conn, admin_fixture()), ~p"/manage")

      result =
        index_live
        |> element("#invite-#{invite.id} td:last-child a", "Show")
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

    test "it can update a invite", %{conn: conn, invite: invite} do
      {:ok, index_live, _html} = live(log_in(conn, admin_fixture()), ~p"/manage")

      assert index_live |> element("#invite-#{invite.id} a", "Edit") |> render_click() =~
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

    test "it can manipulate guests on an invite", %{conn: conn, guest: guest, invite: invite} do
      {:ok, index_live, _html} = live(log_in(conn, admin_fixture()), ~p"/manage")

      assert index_live |> element("#invite-#{invite.id} a", "Edit") |> render_click() =~
               "Edit Invite"

      assert index_live |> element("button", "Add Guest") |> render_click()
      assert index_live |> element("button", "Add Guest") |> render_click()

      assert index_live
             |> form("#invite-form", invite: %{"guests" => @invite_multiple_guest_attrs["guests"]})
             |> render_submit()

      assert length(get_invite(email: guest.email).guests) == 3

      assert index_live |> element("#invite-#{invite.id} a", "Edit") |> render_click() =~
               "Edit Invite"

      assert index_live |> element("button[phx-value-index=1]", "X") |> render_click()
      assert index_live |> form("#invite-form") |> render_submit()

      assert [guest_one, guest_two] = get_invite(email: guest.email).guests
      assert guest_one.name == "Name 1"
      assert guest_two.name == "Name 3"
    end
  end

  defp get_invite(attrs), do: Repo.preload(Repo.get_by(Login, attrs), invite: [:guests]).invite

  defp render_row(rows, text) do
    rows
    |> Enum.map(&String.replace(Floki.text(&1, sep: " | "), ~r/\s+/, " "))
    |> Enum.find(&(&1 =~ text))
    |> case do
      nil -> raise ArgumentError, "No row containing #{inspect(text)} found."
      row -> row
    end
  end

  defp render_rows(element) do
    [{"tbody", _, rows}] = Floki.parse_fragment!(render(element))
    rows
  end
end
