defmodule InvitomaticWeb.Live.GuestSettingsTest do
  use InvitomaticWeb.ConnCase

  alias Invitomatic.Invites

  import Phoenix.LiveViewTest
  import Invitomatic.InvitesFixtures

  describe "Settings page" do
    test "renders settings page", %{conn: conn} do
      {:ok, _lv, html} =
        conn
        |> log_in_guest(guest_fixture())
        |> live(~p"/guest/settings")

      assert html =~ "Change Email"
    end

    test "redirects if guest is not logged in", %{conn: conn} do
      assert {:error, redirect} = live(conn, ~p"/guest/settings")

      assert {:redirect, %{to: path, flash: flash}} = redirect
      assert path == ~p"/guest/log_in"
      assert %{"error" => "You must log in to access this page."} = flash
    end
  end

  describe "update email form" do
    setup %{conn: conn} do
      guest = guest_fixture()
      %{conn: log_in_guest(conn, guest), guest: guest}
    end

    test "updates the guest email", %{conn: conn, guest: guest} do
      new_email = unique_guest_email()

      {:ok, lv, _html} = live(conn, ~p"/guest/settings")

      result =
        lv
        |> form("#email_form", %{
          "guest" => %{"email" => new_email}
        })
        |> render_submit()

      assert result =~ "A link to confirm your email"
      assert Invites.get_guest_by_email(guest.email)
    end

    test "renders errors with invalid data (phx-change)", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/guest/settings")

      result =
        lv
        |> element("#email_form")
        |> render_change(%{
          "action" => "update_email",
          "guest" => %{"email" => "with spaces"}
        })

      assert result =~ "Change Email"
      assert result =~ "must have the @ sign and no spaces"
    end

    test "renders errors with invalid data (phx-submit)", %{conn: conn, guest: guest} do
      {:ok, lv, _html} = live(conn, ~p"/guest/settings")

      unchanged_result =
        lv
        |> form("#email_form", %{
          "guest" => %{"email" => guest.email}
        })
        |> render_submit()

      assert unchanged_result =~ "Change Email"
      assert unchanged_result =~ "did not change"

      invalid_result =
        lv
        |> form("#email_form", %{
          "guest" => %{"email" => "notanemail"}
        })
        |> render_submit()

      assert invalid_result =~ "Change Email"
      assert invalid_result =~ "must have the @ sign and no spaces"
    end
  end

  describe "confirm email" do
    setup %{conn: conn} do
      guest = guest_fixture()
      email = unique_guest_email()

      token =
        extract_guest_token(fn url ->
          Invites.deliver_guest_update_email_instructions(
            %{guest | email: email},
            guest.email,
            url
          )
        end)

      %{conn: log_in_guest(conn, guest), token: token, email: email, guest: guest}
    end

    test "updates the guest email once", %{conn: conn, guest: guest, token: token, email: email} do
      {:error, redirect} = live(conn, ~p"/guest/settings/confirm_email/#{token}")

      assert {:live_redirect, %{to: path, flash: flash}} = redirect
      assert path == ~p"/guest/settings"
      assert %{"info" => message} = flash
      assert message == "Email changed successfully."
      refute Invites.get_guest_by_email(guest.email)
      assert Invites.get_guest_by_email(email)

      # use confirm token again
      {:error, redirect} = live(conn, ~p"/guest/settings/confirm_email/#{token}")
      assert {:live_redirect, %{to: path, flash: flash}} = redirect
      assert path == ~p"/guest/settings"
      assert %{"error" => message} = flash
      assert message == "Email change link is invalid or it has expired."
    end

    test "does not update email with invalid token", %{conn: conn, guest: guest} do
      {:error, redirect} = live(conn, ~p"/guest/settings/confirm_email/oops")
      assert {:live_redirect, %{to: path, flash: flash}} = redirect
      assert path == ~p"/guest/settings"
      assert %{"error" => message} = flash
      assert message == "Email change link is invalid or it has expired."
      assert Invites.get_guest_by_email(guest.email)
    end

    test "redirects if guest is not logged in", %{token: token} do
      conn = build_conn()
      {:error, redirect} = live(conn, ~p"/guest/settings/confirm_email/#{token}")
      assert {:redirect, %{to: path, flash: flash}} = redirect
      assert path == ~p"/guest/log_in"
      assert %{"error" => message} = flash
      assert message == "You must log in to access this page."
    end
  end
end
