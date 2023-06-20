defmodule Invitomatic.Accounts do
  @moduledoc """
  The Accounts context.
  """

  import Ecto.Query, warn: false

  alias Invitomatic.Accounts.Login
  alias Invitomatic.Accounts.Notifier
  alias Invitomatic.Accounts.Token
  alias Invitomatic.Repo

  ## Database getters

  @doc """
  Gets a login by email.

  ## Examples

      iex> get_login_by_email("foo@example.com")
      %Login{}

      iex> get_login_by_email("unknown@example.com")
      nil

  """
  def get_login_by_email(email) when is_binary(email) do
    Repo.get_by(Login, email: email)
  end

  @doc """
  Gets a single login.

  Raises `Ecto.NoResultsError` if the Login does not exist.

  ## Examples

      iex> get_login!(123)
      %Login{}

      iex> get_login!(456)
      ** (Ecto.NoResultsError)

  """
  def get_login!(id), do: Repo.get!(Login, id)

  ## Login registration

  @doc """
  Registers a login.

  ## Examples

      iex> register_login(%{field: value})
      {:ok, %Login{}}

      iex> register_login(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def register(attrs) do
    %Login{}
    |> Login.registration_changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking login changes.

  ## Examples

      iex> change_registration(login)
      %Ecto.Changeset{data: %Login{}}

  """
  def change_registration(%Login{} = login, attrs \\ %{}) do
    Login.registration_changeset(login, attrs, validate_email: false)
  end

  ## Settings

  @doc """
  Returns an `%Ecto.Changeset{}` for changing the login email.

  ## Examples

      iex> change_email(login)
      %Ecto.Changeset{data: %Login{}}

  """
  def change_email(login, attrs \\ %{}) do
    Login.email_changeset(login, attrs, validate_email: false)
  end

  @doc """
  Emulates that the email will change without actually changing
  it in the database.

  ## Examples

      iex> apply_email(login, %{email: ...})
      {:ok, %Login{}}

      iex> apply_email(login, %{email: ...})
      {:error, %Ecto.Changeset{}}

  """
  def apply_email(login, attrs) do
    login
    |> Login.email_changeset(attrs)
    |> Ecto.Changeset.apply_action(:update)
  end

  @doc """
  Updates the login's email using the given token.

  If the token matches, the login's email is updated and the token is deleted.
  The confirmed_at date is also updated to the current time.
  """
  def update_email(login, token) do
    context = "change:#{login.email}"

    with {:ok, query} <- Token.verify_change_email_token_query(token, context),
         %Token{sent_to: email} <- Repo.one(query),
         changeset <- Login.confirm_changeset(Login.email_changeset(login, %{email: email})),
         {:ok, _} <-
           Ecto.Multi.new()
           |> Ecto.Multi.update(:login, changeset)
           |> Ecto.Multi.delete_all(
             :tokens,
             Token.login_and_contexts_query(login, [context])
           )
           |> Repo.transaction() do
      :ok
    else
      _ -> :error
    end
  end

  @doc ~S"""
  Delivers the update email instructions to the given login.

  ## Examples

      iex> deliver_update_email_instructions(login, current_email, &url(~p"/login/settings/confirm_email/#{&1})")
      {:ok, %{to: ..., body: ...}}

  """
  def deliver_update_email_instructions(
        %Login{} = login,
        current_email,
        update_email_url_fun
      )
      when is_function(update_email_url_fun, 1) do
    {encoded_token, login_token} = Token.build_email_token(login, "change:#{current_email}")

    Repo.insert!(login_token)
    Notifier.deliver_update_email_instructions(login, update_email_url_fun.(encoded_token))
  end

  ## Session

  @doc """
  Delivers an invite to the given login.
  """
  def deliver_invite(%Login{} = login, url_fun) when is_function(url_fun, 1) do
    {encoded_token, login_token} = Token.build_email_token(login, "magic:link")

    Repo.insert!(login_token)
    Notifier.deliver_invite(login, url_fun.(encoded_token))
  end

  @doc ~S"""
  Delivers a magic link to the given login.

  ## Examples

      iex> deliver_magic_link(login)
      {:ok, %{to: ..., body: ...}}

  """
  def deliver_magic_link(%Login{} = login, url_fun) when is_function(url_fun, 1) do
    {encoded_token, login_token} = Token.build_email_token(login, "magic:link")

    Repo.insert!(login_token)
    Notifier.deliver_magic_link(login, url_fun.(encoded_token))
  end

  @doc """
  Generates a session token.
  """
  def generate_session_token(login) do
    {token, login_token} = Token.build_session_token(login)
    Repo.insert!(login_token)
    token
  end

  @doc """
  Gets the login from the given magic link token.

  If the token matches, the token is deleted, and the confirmed_at date is also updated to the current time.
  """
  def get_login_from_magic_link_token(token) do
    with {:ok, query} <- Token.verify_magic_link_token(token),
         %Token{login: login, sent_to: _email} <- Repo.one(query),
         {:ok, %{login: confirmed_login}} <-
           Ecto.Multi.new()
           |> Ecto.Multi.update(:login, Login.confirm_changeset(login))
           |> Ecto.Multi.delete_all(:tokens, Token.magic_link_query(token))
           |> Repo.transaction() do
      {:ok, confirmed_login}
    else
      _ -> :error
    end
  end

  @doc """
  Gets the login with the given signed token.
  """
  def get_login_by_session_token(token) do
    {:ok, query} = Token.verify_session_token_query(token)
    Repo.one(query)
  end

  @doc """
  Deletes the signed token with the given context.
  """
  def delete_session_token(token) do
    Repo.delete_all(Token.token_and_context_query(token, "session"))
    :ok
  end
end
