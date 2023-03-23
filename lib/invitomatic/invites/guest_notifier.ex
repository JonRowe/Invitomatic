defmodule Invitomatic.Invites.GuestNotifier do
  import Swoosh.Email

  alias Invitomatic.Mailer

  # Delivers the email using the application mailer.
  defp deliver(recipient, subject, body) do
    # TODO: configure email
    email =
      new()
      |> to(recipient)
      |> from({"Invitomatic", "contact@example.com"})
      |> subject(subject)
      |> text_body(body)

    with {:ok, _metadata} <- Mailer.deliver(email) do
      {:ok, email}
    end
  end

  @doc """
  Deliver magic link to a guest.
  """
  def deliver_magic_link(guest, url) do
    deliver(guest.email, "Sign in to", """
    Hi #{guest.email},

    You can access your invite by visiting the URL below:

    #{url}

    If you don't request this email, please ignore this.
    """)
  end

  @doc """
  Deliver instructions to update a guest's email.
  """
  def deliver_update_email_instructions(guest, url) do
    deliver(guest.email, "Update email instructions", """

    ==============================

    Hi #{guest.email},

    You can change your email by visiting the URL below:

    #{url}

    If you didn't request this change, please ignore this.

    ==============================
    """)
  end
end
