defmodule Invitomatic.AccountsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Invitomatic.Accounts` context.
  """

  def unique_email, do: "email#{System.unique_integer()}@example.com"

  def valid_login_attributes(attrs \\ %{}) do
    Enum.into(attrs, %{
      email: unique_email()
    })
  end

  def admin_fixture(attrs \\ %{}) do
    login_changeset =
      attrs
      |> login_fixture()
      |> Ecto.Changeset.change(%{admin: true})

    Invitomatic.Repo.update!(login_changeset)
  end

  def login_fixture(_attrs \\ %{}) do
    %_{logins: [login | _]} = Invitomatic.InvitesFixtures.invite_fixture()
    login
  end

  def extract_token(fun) do
    {:ok, captured_email} = fun.(&"[TOKEN]#{&1}[TOKEN]")
    [_, token | _] = String.split(captured_email.text_body, "[TOKEN]")
    token
  end

  def magic_link_token(login) do
    extract_token(&Invitomatic.Accounts.deliver_magic_link(login, &1))
  end
end
