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
      with {:ok, contents} when is_binary(contents) <- Keyword.fetch(opts, :html) do
        html_body(text_only_email, add_html_style(subject, contents))
      else
        :error -> text_only_email
      end

    with {:ok, _meta} <- Mailer.deliver(email) do
      {:ok, email}
    end
  end

  def button(href, text) do
    """
    <a href="#{href}" style="background: #cbe2f0; border: 1px solid #a3c2d5; color: #606c76 !important; margin: 1.0rem 0; border-radius: .4rem; cursor: pointer; display: inline-block; font-size: 1.1rem; font-weight: 700; height: 3rem; letter-spacing: .1rem; line-height: 3rem; padding: 0 3rem; text-align: center; text-decoration: none; text-transform: uppercase; white-space: nowrap;">#{text}</a>
    """
  end

  defp add_html_style(subject, html) do
    content =
      Invitomatic.Content.get(:email_stylesheet)
      |> Enum.map(& &1.text)
      |> Enum.join("\n")

    """
    <!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">
    <html xmlns="http://www.w3.org/1999/xhtml">
      <head>
        <meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
        <meta name="viewport" content="width=device-width, initial-scale=1.0"/>
        <title>#{subject}</title>
        <style type="text/css">
          #outlook a {padding:0;}
          .ExternalClass {width:100%;}
          .ExternalClass, .ExternalClass p, .ExternalClass span, .ExternalClass font, .ExternalClass td, .ExternalClass div {line-height: 100%;}
          p {margin: 0; padding: 0; font-size: 0px; line-height: 0px;}
          table td {border-collapse: collapse;}
          table {border-collapse: collapse; mso-table-lspace:0pt; mso-table-rspace:0pt; }
          #backgroundTable {margin:0; padding:0; width:100% !important; line-height: 100% !important;}
          body{width:100% !important; -webkit-text-size-adjust:100%; -ms-text-size-adjust:100%; margin:0; padding:0; font-family: "Roboto", "Helvetica Neue", "Helvetica", "Arial", sans-serif;}
          img {display: block; outline: none; text-decoration: none; -ms-interpolation-mode: bicubic;}
          a img {border: none;}
          a {text-decoration: none; color: #000001;}
          a.phone {text-decoration: none; color: #000001 !important; pointer-events: auto; cursor: default;}
          span {font-size: 13px; line-height: 17px; font-family: monospace; color: #000001;}
          img {outline:none; text-decoration:none; -ms-interpolation-mode: bicubic;}
          a img {border:none;}
          .image_fix {display:block;}
          p {margin: 1em 0;}

          h1, h2, h3, h4, h5, h6 {color: #606c76 !important;}
          h1 a:active, h2 a:active,  h3 a:active, h4 a:active, h5 a:active, h6 a:active { color: #cbe2f0 !important; }
          h1 a, h2 a, h3 a, h4 a, h5 a, h6 a, h1 a:visited, h2 a:visited,  h3 a:visited, h4 a:visited, h5 a:visited, h6 a:visited, a { color: #a3c2d5 !important; }
          td table tr td { padding: 1em 0; }

          #{content}
        </style>
      </head>
      <body>
        <table cellpadding="0" cellspacing="0" border="0" id="backgroundTable">
          <tr>
            <td valign="top" style="padding: 2em;">
              #{html}
            </td>
          </tr>
        </table>
      </body>
    </html>
    """
  end
end
