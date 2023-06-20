defmodule Invitomatic.Accounts.Notifier do
  alias Invitomatic.Email
  alias Invitomatic.Repo

  @doc """
  Deliver the invite email.
  """
  def deliver_invite(raw_login, url) do
    login = maybe_preload_invite(raw_login)

    [content | _] = Invitomatic.Content.get(:invitation)

    extra_lines =
      if login.invite.extra_content do
        [extra_content | _] = Invitomatic.Content.get(login.invite.extra_content)

        String.split(extra_content.text, "\n")
      else
        []
      end

    lines = String.split(content.text, "\n") ++ extra_lines

    Email.send(
      to: {login.invite.name, login.email},
      subject: content.title,
      html: """
      <table>
        <tr><td><h3>Hi #{login.invite.name}</h3></td></tr>
        #{Enum.map(lines, &"<tr><td>#{&1}</td></tr>") |> Enum.join("\n  ")}
        <tr><td>Please get back to use as soon as you can, ideally within 2 weeks, we understand if you can't make it.</td></tr>
        <tr><td>#{Email.button(url, "RSVP")}</td></tr>
        <tr><td>(or if this is does not work, you can visit <a href="#{url}">#{url}</a> directly).</td></tr>
      </table>
      """,
      text: """
      Hi #{login.invite.name},

      #{content.text}

      #{Enum.join(extra_lines, "\n")}

      Please get back to use as soon as you can, ideally within 2 weeks, we understand if you can't make it.

      You can RSVP by visiting the URL below:

      #{url}
      """
    )
  end

  @doc """
  Deliver magic link to login.
  """
  def deliver_magic_link(raw_login, url) do
    login = maybe_preload_invite(raw_login)

    Email.send(
      to: {login.invite.name, login.email},
      subject: "Sign in to manage your invite",
      html: """
      <table>
        <tr><td><h3>Hi #{login.invite.name}</h3></td></tr>
        <tr><td>You can access your invite by clicking the button below:</td></tr>
        <tr><td>#{Email.button(url, "Manage your invitation")}</td></tr>
        <tr><td>(or if this is does not work, you can visit <a href="#{url}">#{url}</a> directly).</td></tr>
      </table>
      """,
      text: """
      Hi #{login.invite.name},

      You can access your invite by visiting the URL below:

      #{url}

      If you don't request this email, please ignore this.
      """
    )
  end

  @doc """
  Deliver instructions to update a login's email.
  """
  def deliver_update_email_instructions(raw_login, url) do
    login = maybe_preload_invite(raw_login)

    Email.send(
      to: {login.invite.name, login.email},
      subject: "Update email instructions",
      html: """
      <table>
        <tr><td><h3>Hi #{login.invite.name}</h3></td></tr>
        <tr><td>You can change your email by visiting the URL below:</td></tr>
        <tr><td>#{Email.button(url, "Change Email")}</td></tr>
        <tr><td>If you didn't request this change, please ignore this.</td></tr>
      </table>
      """,
      text: """
      Hi #{login.invite.name},

      You can change your email by visiting the URL below:

      #{url}

      If you didn't request this change, please ignore this.
      """
    )
  end

  defp maybe_preload_invite(%{invite: %{name: _name}, email: _email} = login), do: login
  defp maybe_preload_invite(%{email: _email} = login), do: Repo.preload(login, :invite)
end
