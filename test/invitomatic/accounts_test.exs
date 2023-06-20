defmodule Invitomatic.AccountsTest do
  use Invitomatic.DataCase, async: true

  alias Invitomatic.Accounts
  alias Invitomatic.Accounts.Login
  alias Invitomatic.Accounts.Token

  import Invitomatic.AccountsFixtures
  import Invitomatic.ContentFixtures

  describe "get_login_by_email/1" do
    test "does not return the login if the email does not exist" do
      refute Accounts.get_login_by_email("unknown@example.com")
    end

    test "returns the login if the email exists" do
      %{id: id} = login = login_fixture()
      assert %Login{id: ^id} = Accounts.get_login_by_email(login.email)
    end
  end

  describe "get_login!/1" do
    test "raises if id is invalid" do
      assert_raise Ecto.NoResultsError, fn ->
        Accounts.get_login!("11111111-1111-1111-1111-111111111111")
      end
    end

    test "returns the login with the given id" do
      %{id: id} = login = login_fixture()
      assert %Login{id: ^id} = Accounts.get_login!(login.id)
    end
  end

  describe "register/1" do
    test "requires email to be set" do
      {:error, changeset} = Accounts.register(%{})

      assert %{
               email: ["can't be blank"]
             } = errors_on(changeset)
    end

    test "validates email when given" do
      {:error, changeset} = Accounts.register(%{email: "not valid"})

      assert %{
               email: ["must have the @ sign and no spaces"]
             } = errors_on(changeset)
    end

    test "validates maximum values for email for security" do
      too_long = String.duplicate("db", 100)
      {:error, changeset} = Accounts.register(%{email: too_long})
      assert "should be at most 160 character(s)" in errors_on(changeset).email
    end

    test "validates email uniqueness" do
      %{email: email} = login_fixture()
      {:error, changeset} = Accounts.register(%{email: email})
      assert "has already been taken" in errors_on(changeset).email

      # Now try with the upper cased email too, to check that email case is ignored.
      {:error, changeset} = Accounts.register(%{email: String.upcase(email)})
      assert "has already been taken" in errors_on(changeset).email
    end
  end

  describe "change_registration/2" do
    test "returns a changeset" do
      assert %Ecto.Changeset{} = changeset = Accounts.change_registration(%Login{})
      assert changeset.required == [:email]
    end

    test "allows fields to be set" do
      email = unique_email()

      changeset =
        Accounts.change_registration(
          %Login{},
          valid_login_attributes(email: email)
        )

      assert changeset.valid?
      assert get_change(changeset, :email) == email
    end
  end

  describe "change_email/2" do
    test "returns a login changeset" do
      assert %Ecto.Changeset{} = changeset = Accounts.change_email(%Login{})
      assert changeset.required == [:email]
    end
  end

  describe "apply_email/3" do
    setup do
      %{login: login_fixture()}
    end

    test "requires email to change", %{login: login} do
      {:error, changeset} = Accounts.apply_email(login, %{})
      assert %{email: ["did not change"]} = errors_on(changeset)
    end

    test "validates email", %{login: login} do
      {:error, changeset} = Accounts.apply_email(login, %{email: "not valid"})

      assert %{email: ["must have the @ sign and no spaces"]} = errors_on(changeset)
    end

    test "validates maximum value for email for security", %{login: login} do
      too_long = String.duplicate("db", 100)

      {:error, changeset} = Accounts.apply_email(login, %{email: too_long})

      assert "should be at most 160 character(s)" in errors_on(changeset).email
    end

    test "validates email uniqueness", %{login: login} do
      %{email: email} = login_fixture()

      {:error, changeset} = Accounts.apply_email(login, %{email: email})

      assert "has already been taken" in errors_on(changeset).email
    end

    test "applies the email without persisting it", %{login: login} do
      email = unique_email()
      {:ok, login} = Accounts.apply_email(login, %{email: email})
      assert login.email == email
      assert Accounts.get_login!(login.id).email != email
    end
  end

  describe "deliver_update_email_instructions/3" do
    setup do
      %{login: login_fixture()}
    end

    test "sends token through notification", %{login: login} do
      token =
        extract_token(fn url ->
          Accounts.deliver_update_email_instructions(login, "current@example.com", url)
        end)

      {:ok, token} = Base.url_decode64(token, padding: false)
      assert login_token = Repo.get_by(Token, token: :crypto.hash(:sha256, token))
      assert login_token.login_id == login.id
      assert login_token.sent_to == login.email
      assert login_token.context == "change:current@example.com"
    end
  end

  describe "update_email/2" do
    setup do
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

      %{login: login, token: token, email: email}
    end

    test "updates the email with a valid token", %{login: login, token: token, email: email} do
      assert Accounts.update_email(login, token) == :ok
      changed_login = Repo.get!(Login, login.id)
      assert changed_login.email != login.email
      assert changed_login.email == email
      assert changed_login.confirmed_at
      assert changed_login.confirmed_at != login.confirmed_at
      refute Repo.get_by(Token, login_id: login.id)
    end

    test "does not update email with invalid token", %{login: login} do
      assert Accounts.update_email(login, "oops") == :error
      assert Repo.get!(Login, login.id).email == login.email
      assert Repo.get_by(Token, login_id: login.id)
    end

    test "does not update email if login email changed", %{login: login, token: token} do
      assert Accounts.update_email(%{login | email: "current@example.com"}, token) == :error
      assert Repo.get!(Login, login.id).email == login.email
      assert Repo.get_by(Token, login_id: login.id)
    end

    test "does not update email if token expired", %{login: login, token: token} do
      {1, nil} = Repo.update_all(Token, set: [inserted_at: ~N[2020-01-01 00:00:00]])
      assert Accounts.update_email(login, token) == :error
      assert Repo.get!(Login, login.id).email == login.email
      assert Repo.get_by(Token, login_id: login.id)
    end
  end

  describe "deliver_invite/1" do
    setup do
      %{login: login_fixture(), content: content_fixture(type: :invitation)}
    end

    test "sends token through notification", %{login: login} do
      token =
        extract_token(fn url ->
          Accounts.deliver_invite(login, url)
        end)

      {:ok, token} = Base.url_decode64(token, padding: false)
      assert login_token = Repo.get_by(Token, token: :crypto.hash(:sha256, token))
      assert login_token.login_id == login.id
      assert login_token.sent_to == login.email
      assert login_token.context == "magic:link"
    end

    test "it includes the invitiation content", %{content: content, login: login} do
      text = extract_content(fn -> Accounts.deliver_invite(login, & &1) end)
      assert text =~ content.text
    end

    test "it includes the extra content if set", %{login: login} do
      Repo.update_all(from(invite in "invite"), set: [extra_content: "accommodation"])
      extra_content = content_fixture(type: :accommodation, text: "its here!")
      text = extract_content(fn -> Accounts.deliver_invite(login, & &1) end)
      assert text =~ extra_content.text
    end
  end

  describe "deliver_magic_link/1" do
    setup do
      %{login: login_fixture()}
    end

    test "sends token through notification", %{login: login} do
      token =
        extract_token(fn url ->
          Accounts.deliver_magic_link(login, url)
        end)

      {:ok, token} = Base.url_decode64(token, padding: false)
      assert login_token = Repo.get_by(Token, token: :crypto.hash(:sha256, token))
      assert login_token.login_id == login.id
      assert login_token.sent_to == login.email
      assert login_token.context == "magic:link"
    end
  end

  describe "generate_session_token/1" do
    setup do
      %{login: login_fixture()}
    end

    test "generates a token", %{login: login} do
      token = Accounts.generate_session_token(login)
      assert login_token = Repo.get_by(Token, token: token)
      assert login_token.context == "session"

      # Creating the same token for another login should fail
      assert_raise Ecto.ConstraintError, fn ->
        Repo.insert!(%Token{
          token: login_token.token,
          login_id: login_fixture().id,
          context: "session"
        })
      end
    end
  end

  describe "get_login_from_magic_link_token/1" do
    setup do
      login = login_fixture()
      token = extract_token(&Accounts.deliver_magic_link(login, &1))

      %{login: login, token: token}
    end

    test "returns the login from a valid token", %{login: login, token: token} do
      assert {:ok, returned_login} = Accounts.get_login_from_magic_link_token(token)
      assert returned_login == Repo.get!(Login, login.id)
      assert returned_login.email == login.email
      assert returned_login.confirmed_at
      assert returned_login.confirmed_at != login.confirmed_at
    end

    test "works with an invite token", %{login: login} do
      token = extract_token(&Accounts.deliver_invite(login, &1))
      assert {:ok, returned_login} = Accounts.get_login_from_magic_link_token(token)
      assert returned_login == Repo.get!(Login, login.id)
      assert returned_login.email == login.email
      assert returned_login.confirmed_at
      assert returned_login.confirmed_at != login.confirmed_at
    end

    test "only removes the token for the used magic link", %{login: login, token: token} do
      other_token = extract_token(&Accounts.deliver_magic_link(login, &1))

      assert {:ok, _login} = Accounts.get_login_from_magic_link_token(token)

      {:ok, db_token} = Token.decode_url_token(token)
      {:ok, other_db_token} = Token.decode_url_token(other_token)

      refute Repo.get_by(Token, token: db_token)
      assert Repo.get_by(Token, token: other_db_token)
    end

    test "does not return a login from a invalid token", %{login: login} do
      assert Accounts.get_login_from_magic_link_token("oops") == :error
      assert Repo.get_by(Token, login_id: login.id)
    end

    test "does not return a login if the token expired", %{login: login, token: token} do
      {1, nil} = Repo.update_all(Token, set: [inserted_at: ~N[2020-01-01 00:00:00]])
      assert Accounts.get_login_from_magic_link_token(token) == :error
      assert Repo.get_by(Token, login_id: login.id)
    end
  end

  describe "get_login_by_session_token/1" do
    setup do
      login = login_fixture()
      token = Accounts.generate_session_token(login)
      %{login: login, token: token}
    end

    test "returns login by token", %{login: login, token: token} do
      assert session_login = Accounts.get_login_by_session_token(token)
      assert session_login.id == login.id
    end

    test "does not return login for invalid token" do
      refute Accounts.get_login_by_session_token("oops")
    end

    test "does not return login for expired token", %{token: token} do
      {1, nil} = Repo.update_all(Token, set: [inserted_at: ~N[2020-01-01 00:00:00]])
      refute Accounts.get_login_by_session_token(token)
    end
  end

  describe "delete_session_token/1" do
    test "deletes the token" do
      login = login_fixture()
      token = Accounts.generate_session_token(login)
      assert Accounts.delete_session_token(token) == :ok
      refute Accounts.get_login_by_session_token(token)
    end
  end
end
