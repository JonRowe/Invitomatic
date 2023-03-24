defmodule InvitomaticWeb.Live.SettingsTest do
  use InvitomaticWeb.ConnCase

  alias Invitomatic.Accounts

  import Phoenix.LiveViewTest
  import Invitomatic.AccountsFixtures

  describe "Settings page" do
    test "renders settings page", %{conn: conn} do
      {:ok, _lv, html} =
        conn
        |> log_in(login_fixture())
        |> live(~p"/settings")

      assert html =~ "Change Email"
    end

    test "redirects if not logged in", %{conn: conn} do
      assert {:error, redirect} = live(conn, ~p"/settings")

      assert {:redirect, %{to: path, flash: flash}} = redirect
      assert path == ~p"/log_in"
      assert %{"error" => "You must log in to access this page."} = flash
    end
  end

  describe "update email form" do
    setup %{conn: conn} do
      login = login_fixture()
      %{conn: log_in(conn, login), login: login}
    end

    test "updates the logins email", %{conn: conn, login: login} do
      new_email = unique_email()

      {:ok, lv, _html} = live(conn, ~p"/settings")

      result =
        lv
        |> form("#email_form", %{
          "guest" => %{"email" => new_email}
        })
        |> render_submit()

      assert result =~ "A link to confirm your email"
      assert Accounts.get_login_by_email(login.email)
    end

    test "renders errors with invalid data (phx-change)", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/settings")

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

    test "renders errors with invalid data (phx-submit)", %{conn: conn, login: login} do
      {:ok, lv, _html} = live(conn, ~p"/settings")

      unchanged_result =
        lv
        |> form("#email_form", %{
          "guest" => %{"email" => login.email}
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
      login = login_fixture()
      email = unique_email()

      token =
        extract_token(fn url ->
          Accounts.deliver_update_email_instructions(
            %{login | email: email},
            login.email,
            url
          )
        end)

      %{conn: log_in(conn, login), token: token, email: email, login: login}
    end

    test "updates the logins email once", %{conn: conn, login: login, token: token, email: email} do
      {:error, redirect} = live(conn, ~p"/settings/confirm_email/#{token}")

      assert {:live_redirect, %{to: path, flash: flash}} = redirect
      assert path == ~p"/settings"
      assert %{"info" => message} = flash
      assert message == "Email changed successfully."
      refute Accounts.get_login_by_email(login.email)
      assert Accounts.get_login_by_email(email)

      # use confirm token again
      {:error, redirect} = live(conn, ~p"/settings/confirm_email/#{token}")
      assert {:live_redirect, %{to: path, flash: flash}} = redirect
      assert path == ~p"/settings"
      assert %{"error" => message} = flash
      assert message == "Email change link is invalid or it has expired."
    end

    test "does not update email with invalid token", %{conn: conn, login: login} do
      {:error, redirect} = live(conn, ~p"/settings/confirm_email/oops")
      assert {:live_redirect, %{to: path, flash: flash}} = redirect
      assert path == ~p"/settings"
      assert %{"error" => message} = flash
      assert message == "Email change link is invalid or it has expired."
      assert Accounts.get_login_by_email(login.email)
    end

    test "redirects if not logged in", %{token: token} do
      conn = build_conn()
      {:error, redirect} = live(conn, ~p"/settings/confirm_email/#{token}")
      assert {:redirect, %{to: path, flash: flash}} = redirect
      assert path == ~p"/log_in"
      assert %{"error" => message} = flash
      assert message == "You must log in to access this page."
    end
  end
end
