defmodule Invitomatic.Repo.Migrations.RenameGuestToLogin do
  use Ecto.Migration

  def change do
    rename table("guest"), to: table("login")
    rename table("guest_tokens"), to: table("login_token")
    rename table("login_token"), :guest_id, to: :login_id
  end
end
