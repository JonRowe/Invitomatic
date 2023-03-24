defmodule Invitomatic.Invites do
  @moduledoc """
  The Invites context.
  """

  import Ecto.Query, warn: false

  alias Invitomatic.Invites.Guest
  alias Invitomatic.Invites.GuestNotifier
  alias Invitomatic.Invites.GuestToken
  alias Invitomatic.Repo

  ## Database getters

  @doc """
  Gets a guest by email.

  ## Examples

      iex> get_guest_by_email("foo@example.com")
      %Guest{}

      iex> get_guest_by_email("unknown@example.com")
      nil

  """
  def get_guest_by_email(email) when is_binary(email) do
    Repo.get_by(Guest, email: email)
  end

  @doc """
  Gets a single guest.

  Raises `Ecto.NoResultsError` if the Guest does not exist.

  ## Examples

      iex> get_guest!(123)
      %Guest{}

      iex> get_guest!(456)
      ** (Ecto.NoResultsError)

  """
  def get_guest!(id), do: Repo.get!(Guest, id)

  ## Guest registration

  @doc """
  Registers a guest.

  ## Examples

      iex> register_guest(%{field: value})
      {:ok, %Guest{}}

      iex> register_guest(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def register_guest(attrs) do
    %Guest{}
    |> Guest.registration_changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking guest changes.

  ## Examples

      iex> change_guest_registration(guest)
      %Ecto.Changeset{data: %Guest{}}

  """
  def change_guest_registration(%Guest{} = guest, attrs \\ %{}) do
    Guest.registration_changeset(guest, attrs, validate_email: false)
  end

  ## Settings

  @doc """
  Returns an `%Ecto.Changeset{}` for changing the guest email.

  ## Examples

      iex> change_guest_email(guest)
      %Ecto.Changeset{data: %Guest{}}

  """
  def change_guest_email(guest, attrs \\ %{}) do
    Guest.email_changeset(guest, attrs, validate_email: false)
  end

  @doc """
  Emulates that the email will change without actually changing
  it in the database.

  ## Examples

      iex> apply_guest_email(guest, %{email: ...})
      {:ok, %Guest{}}

      iex> apply_guest_email(guest, %{email: ...})
      {:error, %Ecto.Changeset{}}

  """
  def apply_guest_email(guest, attrs) do
    guest
    |> Guest.email_changeset(attrs)
    |> Ecto.Changeset.apply_action(:update)
  end

  @doc """
  Updates the guest's email using the given token.

  If the token matches, the guest's email is updated and the token is deleted.
  The confirmed_at date is also updated to the current time.
  """
  def update_guest_email(guest, token) do
    context = "change:#{guest.email}"

    with {:ok, query} <- GuestToken.verify_change_email_token_query(token, context),
         %GuestToken{sent_to: email} <- Repo.one(query),
         changeset <- Guest.confirm_changeset(Guest.email_changeset(guest, %{email: email})),
         {:ok, _} <-
           Ecto.Multi.new()
           |> Ecto.Multi.update(:guest, changeset)
           |> Ecto.Multi.delete_all(
             :tokens,
             GuestToken.guest_and_contexts_query(guest, [context])
           )
           |> Repo.transaction() do
      :ok
    else
      _ -> :error
    end
  end

  @doc ~S"""
  Delivers the update email instructions to the given guest.

  ## Examples

      iex> deliver_guest_update_email_instructions(guest, current_email, &url(~p"/guest/settings/confirm_email/#{&1})")
      {:ok, %{to: ..., body: ...}}

  """
  def deliver_guest_update_email_instructions(
        %Guest{} = guest,
        current_email,
        update_email_url_fun
      )
      when is_function(update_email_url_fun, 1) do
    {encoded_token, guest_token} = GuestToken.build_email_token(guest, "change:#{current_email}")

    Repo.insert!(guest_token)
    GuestNotifier.deliver_update_email_instructions(guest, update_email_url_fun.(encoded_token))
  end

  ## Session

  @doc ~S"""
  Delivers a magic link to the given guest.

  ## Examples

      iex> deliver_guest_magic_link(guest)
      {:ok, %{to: ..., body: ...}}

  """
  def deliver_guest_magic_link(%Guest{} = guest, url_fun) when is_function(url_fun, 1) do
    {encoded_token, guest_token} = GuestToken.build_email_token(guest, "magic:link")

    Repo.insert!(guest_token)
    GuestNotifier.deliver_magic_link(guest, url_fun.(encoded_token))
  end

  @doc """
  Generates a session token.
  """
  def generate_guest_session_token(guest) do
    {token, guest_token} = GuestToken.build_session_token(guest)
    Repo.insert!(guest_token)
    token
  end

  @doc """
  Gets the guest with the given signed token.
  """
  def get_guest_by_session_token(token) do
    {:ok, query} = GuestToken.verify_session_token_query(token)
    Repo.one(query)
  end

  @doc """
  Deletes the signed token with the given context.
  """
  def delete_guest_session_token(token) do
    Repo.delete_all(GuestToken.token_and_context_query(token, "session"))
    :ok
  end
end
