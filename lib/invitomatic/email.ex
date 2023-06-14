defmodule Invitomatic.Email do
  import Swoosh.Email

  alias Invitomatic.Mailer

  def send(opts \\ []) do
    recipient = Keyword.fetch!(opts, :to)
    sender = Keyword.fetch!(Application.get_env(:invitomatic, :emails), :sender)
    subject = Keyword.fetch!(opts, :subject)
    text = Keyword.fetch!(opts, :text)

    text_only_email =
      new()
      |> from(sender)
      |> to(recipient)
      |> subject(subject)
      |> text_body(text)

    email =
      with contents when is_binary(contents) <- Keyword.fetch(opts, :html) do
        html_body(text_only_email, contents)
      else
        :error -> text_only_email
      end

    with {:ok, _meta} <- Mailer.deliver(email) do
      {:ok, email}
    end
  end
end
