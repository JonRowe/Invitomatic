defmodule Invitomatic.InvitesTest do
  use Invitomatic.DataCase

  alias Invitomatic.Invites
  alias Invitomatic.Invites.Guest
  alias Invitomatic.Invites.GuestToken

  import Invitomatic.InvitesFixtures

  describe "get_guest_by_email/1" do
    test "does not return the guest if the email does not exist" do
      refute Invites.get_guest_by_email("unknown@example.com")
    end

    test "returns the guest if the email exists" do
      %{id: id} = guest = guest_fixture()
      assert %Guest{id: ^id} = Invites.get_guest_by_email(guest.email)
    end
  end

  describe "get_guest!/1" do
    test "raises if id is invalid" do
      assert_raise Ecto.NoResultsError, fn ->
        Invites.get_guest!("11111111-1111-1111-1111-111111111111")
      end
    end

    test "returns the guest with the given id" do
      %{id: id} = guest = guest_fixture()
      assert %Guest{id: ^id} = Invites.get_guest!(guest.id)
    end
  end

  describe "register_guest/1" do
    test "requires email to be set" do
      {:error, changeset} = Invites.register_guest(%{})

      assert %{
               email: ["can't be blank"]
             } = errors_on(changeset)
    end

    test "validates email when given" do
      {:error, changeset} = Invites.register_guest(%{email: "not valid"})

      assert %{
               email: ["must have the @ sign and no spaces"]
             } = errors_on(changeset)
    end

    test "validates maximum values for email for security" do
      too_long = String.duplicate("db", 100)
      {:error, changeset} = Invites.register_guest(%{email: too_long})
      assert "should be at most 160 character(s)" in errors_on(changeset).email
    end

    test "validates email uniqueness" do
      %{email: email} = guest_fixture()
      {:error, changeset} = Invites.register_guest(%{email: email})
      assert "has already been taken" in errors_on(changeset).email

      # Now try with the upper cased email too, to check that email case is ignored.
      {:error, changeset} = Invites.register_guest(%{email: String.upcase(email)})
      assert "has already been taken" in errors_on(changeset).email
    end
  end

  describe "change_guest_registration/2" do
    test "returns a changeset" do
      assert %Ecto.Changeset{} = changeset = Invites.change_guest_registration(%Guest{})
      assert changeset.required == [:email]
    end

    test "allows fields to be set" do
      email = unique_guest_email()

      changeset =
        Invites.change_guest_registration(
          %Guest{},
          valid_guest_attributes(email: email)
        )

      assert changeset.valid?
      assert get_change(changeset, :email) == email
    end
  end

  describe "change_guest_email/2" do
    test "returns a guest changeset" do
      assert %Ecto.Changeset{} = changeset = Invites.change_guest_email(%Guest{})
      assert changeset.required == [:email]
    end
  end

  describe "apply_guest_email/3" do
    setup do
      %{guest: guest_fixture()}
    end

    test "requires email to change", %{guest: guest} do
      {:error, changeset} = Invites.apply_guest_email(guest, %{})
      assert %{email: ["did not change"]} = errors_on(changeset)
    end

    test "validates email", %{guest: guest} do
      {:error, changeset} = Invites.apply_guest_email(guest, %{email: "not valid"})

      assert %{email: ["must have the @ sign and no spaces"]} = errors_on(changeset)
    end

    test "validates maximum value for email for security", %{guest: guest} do
      too_long = String.duplicate("db", 100)

      {:error, changeset} = Invites.apply_guest_email(guest, %{email: too_long})

      assert "should be at most 160 character(s)" in errors_on(changeset).email
    end

    test "validates email uniqueness", %{guest: guest} do
      %{email: email} = guest_fixture()

      {:error, changeset} = Invites.apply_guest_email(guest, %{email: email})

      assert "has already been taken" in errors_on(changeset).email
    end

    test "applies the email without persisting it", %{guest: guest} do
      email = unique_guest_email()
      {:ok, guest} = Invites.apply_guest_email(guest, %{email: email})
      assert guest.email == email
      assert Invites.get_guest!(guest.id).email != email
    end
  end

  describe "deliver_guest_update_email_instructions/3" do
    setup do
      %{guest: guest_fixture()}
    end

    test "sends token through notification", %{guest: guest} do
      token =
        extract_guest_token(fn url ->
          Invites.deliver_guest_update_email_instructions(guest, "current@example.com", url)
        end)

      {:ok, token} = Base.url_decode64(token, padding: false)
      assert guest_token = Repo.get_by(GuestToken, token: :crypto.hash(:sha256, token))
      assert guest_token.guest_id == guest.id
      assert guest_token.sent_to == guest.email
      assert guest_token.context == "change:current@example.com"
    end
  end

  describe "update_guest_email/2" do
    setup do
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

      %{guest: guest, token: token, email: email}
    end

    test "updates the email with a valid token", %{guest: guest, token: token, email: email} do
      assert Invites.update_guest_email(guest, token) == :ok
      changed_guest = Repo.get!(Guest, guest.id)
      assert changed_guest.email != guest.email
      assert changed_guest.email == email
      assert changed_guest.confirmed_at
      assert changed_guest.confirmed_at != guest.confirmed_at
      refute Repo.get_by(GuestToken, guest_id: guest.id)
    end

    test "does not update email with invalid token", %{guest: guest} do
      assert Invites.update_guest_email(guest, "oops") == :error
      assert Repo.get!(Guest, guest.id).email == guest.email
      assert Repo.get_by(GuestToken, guest_id: guest.id)
    end

    test "does not update email if guest email changed", %{guest: guest, token: token} do
      assert Invites.update_guest_email(%{guest | email: "current@example.com"}, token) == :error
      assert Repo.get!(Guest, guest.id).email == guest.email
      assert Repo.get_by(GuestToken, guest_id: guest.id)
    end

    test "does not update email if token expired", %{guest: guest, token: token} do
      {1, nil} = Repo.update_all(GuestToken, set: [inserted_at: ~N[2020-01-01 00:00:00]])
      assert Invites.update_guest_email(guest, token) == :error
      assert Repo.get!(Guest, guest.id).email == guest.email
      assert Repo.get_by(GuestToken, guest_id: guest.id)
    end
  end

  describe "deliver_guest_magic_link/1" do
    setup do
      %{guest: guest_fixture()}
    end

    test "sends token through notification", %{guest: guest} do
      token =
        extract_guest_token(fn url ->
          Invites.deliver_guest_magic_link(guest, url)
        end)

      {:ok, token} = Base.url_decode64(token, padding: false)
      assert guest_token = Repo.get_by(GuestToken, token: :crypto.hash(:sha256, token))
      assert guest_token.guest_id == guest.id
      assert guest_token.sent_to == guest.email
      assert guest_token.context == "magic:link"
    end
  end

  describe "generate_guest_session_token/1" do
    setup do
      %{guest: guest_fixture()}
    end

    test "generates a token", %{guest: guest} do
      token = Invites.generate_guest_session_token(guest)
      assert guest_token = Repo.get_by(GuestToken, token: token)
      assert guest_token.context == "session"

      # Creating the same token for another guest should fail
      assert_raise Ecto.ConstraintError, fn ->
        Repo.insert!(%GuestToken{
          token: guest_token.token,
          guest_id: guest_fixture().id,
          context: "session"
        })
      end
    end
  end

  describe "get_guest_by_session_token/1" do
    setup do
      guest = guest_fixture()
      token = Invites.generate_guest_session_token(guest)
      %{guest: guest, token: token}
    end

    test "returns guest by token", %{guest: guest, token: token} do
      assert session_guest = Invites.get_guest_by_session_token(token)
      assert session_guest.id == guest.id
    end

    test "does not return guest for invalid token" do
      refute Invites.get_guest_by_session_token("oops")
    end

    test "does not return guest for expired token", %{token: token} do
      {1, nil} = Repo.update_all(GuestToken, set: [inserted_at: ~N[2020-01-01 00:00:00]])
      refute Invites.get_guest_by_session_token(token)
    end
  end

  describe "delete_guest_session_token/1" do
    test "deletes the token" do
      guest = guest_fixture()
      token = Invites.generate_guest_session_token(guest)
      assert Invites.delete_guest_session_token(token) == :ok
      refute Invites.get_guest_by_session_token(token)
    end
  end
end
