defmodule Invitomatic.Accounts.Notifier do
  alias Invitomatic.Email
  alias Invitomatic.Repo

  @doc """
  Deliver magic link to login.
  """
  def deliver_magic_link(login, url) do
    Email.send(
      to: sender_for(login),
      subject: "Sign in to",
      text: """
      Hi #{login.email},

      You can access your invite by visiting the URL below:

      #{url}

      If you don't request this email, please ignore this.
      """
    )
  end

  @doc """
  Deliver instructions to update a login's email.
  """
  def deliver_update_email_instructions(login, url) do
    Email.send(
      to: sender_for(login),
      subject: "Update email instructions",
      text: """
      ==============================

      Hi #{login.email},

      You can change your email by visiting the URL below:

      #{url}

      If you didn't request this change, please ignore this.

      ==============================
      """
    )
  end

  defp sender_for(%{invite: %{name: name}, email: email}), do: {name, email}
  defp sender_for(%{email: _email} = login), do: sender_for(Repo.preload(login, :invite))
end
