defmodule Invitomatic.InvitesFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Invitomatic.Invites` context.
  """

  def unique_guest_email, do: "guest#{System.unique_integer()}@example.com"

  def valid_guest_attributes(attrs \\ %{}) do
    Enum.into(attrs, %{
      email: unique_guest_email()
    })
  end

  def guest_fixture(attrs \\ %{}) do
    {:ok, guest} =
      attrs
      |> valid_guest_attributes()
      |> Invitomatic.Invites.register_guest()

    guest
  end

  def extract_guest_token(fun) do
    {:ok, captured_email} = fun.(&"[TOKEN]#{&1}[TOKEN]")
    [_, token | _] = String.split(captured_email.text_body, "[TOKEN]")
    token
  end
end
