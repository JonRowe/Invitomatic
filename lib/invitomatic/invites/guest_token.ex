defmodule Invitomatic.Invites.GuestToken do
  use Ecto.Schema

  import Ecto.Query

  alias Invitomatic.Invites.GuestToken

  @hash_algorithm :sha256
  @rand_size 32

  @change_email_validity {7, "day"}
  @session_validity {60, "day"}

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "guest_tokens" do
    field :token, :binary
    field :context, :string
    field :sent_to, :string
    belongs_to :guest, Invitomatic.Invites.Guest

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

  Therefore, storing them allows individual guest
  sessions to be expired. The token system can also be extended
  to store additional data, such as the device used for logging in.
  You could then use this information to display all valid sessions
  and devices in the UI and allow users to explicitly expire any
  session they deem invalid.
  """
  def build_session_token(guest) do
    token = :crypto.strong_rand_bytes(@rand_size)
    {token, %GuestToken{token: token, context: "session", guest_id: guest.id}}
  end

  @doc """
  Checks if the token is valid and returns its underlying lookup query.

  The query returns the guest found by the token, if any.

  The token is valid if it matches the value in the database and it has
  not expired (after @session_validity_in_days).
  """
  def verify_session_token_query(token) do
    query =
      from token in token_and_context_query(token, "session"),
        join: guest in assoc(token, :guest),
        where: token.inserted_at > ago(@session_validity),
        select: guest

    {:ok, query}
  end

  @doc """
  Builds a token and its hash to be delivered to the guest's email.

  The non-hashed token is sent to the guest email while the
  hashed part is stored in the database. The original token cannot be reconstructed,
  which means anyone with read-only access to the database cannot directly use
  the token in the application to gain access. Furthermore, if the user changes
  their email in the system, the tokens sent to the previous email are no longer
  valid.

  Users can easily adapt the existing code to provide other types of delivery methods,
  for example, by phone numbers.
  """
  def build_email_token(guest, context) do
    build_hashed_token(guest, context, guest.email)
  end

  defp build_hashed_token(guest, context, sent_to) do
    token = :crypto.strong_rand_bytes(@rand_size)
    hashed_token = :crypto.hash(@hash_algorithm, token)

    {Base.url_encode64(token, padding: false),
     %GuestToken{
       token: hashed_token,
       context: context,
       sent_to: sent_to,
       guest_id: guest.id
     }}
  end

  @doc """
  Checks if the token is valid and returns its underlying lookup query.

  The query returns the guest found by the token, if any.

  This is used to validate requests to change the guest
  email. It is different from `verify_email_token_query/2` precisely because
  `verify_email_token_query/2` validates the email has not changed, which is
  the starting point by this function.

  The given token is valid if it matches its hashed counterpart in the
  database and if it has not expired (after @change_email_validity_in_days).
  The context must always start with "change:".
  """
  def verify_change_email_token_query(token, "change:" <> _ = context) do
    case Base.url_decode64(token, padding: false) do
      {:ok, decoded_token} ->
        hashed_token = :crypto.hash(@hash_algorithm, decoded_token)

        query =
          from token in token_and_context_query(hashed_token, context),
            where: token.inserted_at > ago(@change_email_validity)

        {:ok, query}

      :error ->
        :error
    end
  end

  @doc """
  Returns the token struct for the given token value and context.
  """
  def token_and_context_query(token, context) do
    from GuestToken, where: [token: ^token, context: ^context]
  end

  @doc """
  Gets all tokens for the given guest for the given contexts.
  """
  def guest_and_contexts_query(guest, :all) do
    from t in GuestToken, where: t.guest_id == ^guest.id
  end

  def guest_and_contexts_query(guest, [_ | _] = contexts) do
    from t in GuestToken, where: t.guest_id == ^guest.id and t.context in ^contexts
  end
end
