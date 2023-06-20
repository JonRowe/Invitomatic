defmodule Invitomatic.Accounts.Token do
  use Ecto.Schema

  import Ecto.Query

  alias Invitomatic.Accounts.Token

  @hash_algorithm :sha256
  @rand_size 32

  @change_email_validity {7, "day"}
  @magic_link_validity {90, "day"}
  @session_validity {60, "day"}

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "login_token" do
    field :token, :binary
    field :context, :string
    field :sent_to, :string
    belongs_to :login, Invitomatic.Accounts.Login

    timestamps(updated_at: false)
  end

  defmacrop ago({:@, _, _} = validity) do
    {n, unit} = Macro.expand(validity, __CALLER__)
    quote(do: ago(unquote(n), unquote(unit)))
  end

  @doc """
  Generates a token that will be stored in a signed place,
  such as session or cookie. As they are signed, those
  tokens do not need to be hashed.

  The reason why we store session tokens in the database, even
  though Phoenix already provides a session cookie, is because
  Phoenix' default session cookies are not persisted, they are
  simply signed and potentially encrypted. This means they are
  valid indefinitely, unless you change the signing/encryption
  salt.

  Therefore, storing them allows individual login
  sessions to be expired. The token system can also be extended
  to store additional data, such as the device used for logging in.
  You could then use this information to display all valid sessions
  and devices in the UI and allow users to explicitly expire any
  session they deem invalid.
  """
  def build_session_token(login) do
    token = :crypto.strong_rand_bytes(@rand_size)
    {token, %Token{token: token, context: "session", login_id: login.id}}
  end

  @doc """
  Decode a url token into a binary, these tokens come via emails generally
  """
  def decode_url_token(token_string) do
    case Base.url_decode64(token_string, padding: false) do
      {:ok, decoded_token} -> {:ok, _hashed_token = :crypto.hash(@hash_algorithm, decoded_token)}
      _ -> :error
    end
  end

  @doc """
  Checks if the token is valid and returns its underlying lookup query.

  The query returns the login found by the token, if any.

  The token is valid if it matches the value in the database and it has
  not expired (after @session_validity_in_days).
  """
  def verify_session_token_query(token) do
    query =
      from token in token_and_context_query(token, "session"),
        join: login in assoc(token, :login),
        where: token.inserted_at > ago(@session_validity),
        select: login

    {:ok, query}
  end

  @doc """
  Builds a token and its hash to be delivered to the login's email.

  The non-hashed token is sent to the login email while the
  hashed part is stored in the database. The original token cannot be reconstructed,
  which means anyone with read-only access to the database cannot directly use
  the token in the application to gain access. Furthermore, if the user changes
  their email in the system, the tokens sent to the previous email are no longer
  valid.

  Users can easily adapt the existing code to provide other types of delivery methods,
  for example, by phone numbers.
  """
  def build_email_token(login, context) do
    build_hashed_token(login, context, login.email)
  end

  defp build_hashed_token(login, context, sent_to) do
    token = :crypto.strong_rand_bytes(@rand_size)
    hashed_token = :crypto.hash(@hash_algorithm, token)

    {Base.url_encode64(token, padding: false),
     %Token{
       token: hashed_token,
       context: context,
       sent_to: sent_to,
       login_id: login.id
     }}
  end

  @doc """
  Checks if the token is valid and returns its underlying lookup query.

  The query returns the login found by the token, if any.

  This is used to validate requests to change the login
  email. It is different from `verify_email_token_query/2` precisely because
  `verify_email_token_query/2` validates the email has not changed, which is
  the starting point by this function.

  The given token is valid if it matches its hashed counterpart in the
  database and if it has not expired (after @change_email_validity_in_days).
  The context must always start with "change:".
  """
  def verify_change_email_token_query(token, "change:" <> _ = context) do
    verify_email_token_query(token, context, @change_email_validity)
  end

  def verify_magic_link_token(token) do
    verify_email_token_query(token, "magic:link", @magic_link_validity, [:login])
  end

  defp verify_email_token_query(token, context, {n, unit} = _validity, preloads \\ []) do
    case decode_url_token(token) do
      {:ok, hashed_token} ->
        query =
          from token in token_and_context_query(hashed_token, context),
            where: token.inserted_at > ago(^n, ^unit),
            preload: ^preloads

        {:ok, query}

      :error ->
        :error
    end
  end

  @doc """
  """
  def magic_link_query(url_token) do
    case decode_url_token(url_token) do
      {:ok, token} -> token_and_context_query(token, "magic:link")
      _ -> :error
    end
  end

  @doc """
  Returns the token struct for the given token value and context.
  """
  def token_and_context_query(token, context) do
    from Token, where: [token: ^token, context: ^context]
  end

  @doc """
  Gets all tokens for the given login for the given contexts.
  """
  def login_and_contexts_query(login, :all) do
    from t in Token, where: t.login_id == ^login.id
  end

  def login_and_contexts_query(login, [_ | _] = contexts) do
    from t in Token, where: t.login_id == ^login.id and t.context in ^contexts
  end
end
