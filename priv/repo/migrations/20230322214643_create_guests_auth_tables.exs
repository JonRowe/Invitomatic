defmodule Invitomatic.Repo.Migrations.CreateGuestAuthTables do
  use Ecto.Migration

  def change do
    execute "CREATE EXTENSION IF NOT EXISTS citext", ""
    execute "CREATE EXTENSION \"uuid-ossp\";", "DROP EXTENSION \"uuid-ossp\";"

    create table(:guest, primary_key: false) do
      add :id, :uuid, primary_key: true, default: fragment("uuid_generate_v4()")
      add :email, :citext, null: false
      add :confirmed_at, :naive_datetime
      timestamps(default: fragment("NOW()"))
    end

    create unique_index(:guest, [:email])

    create table(:guest_tokens, primary_key: false) do
      add :id, :uuid, primary_key: true, default: fragment("uuid_generate_v4()")
      add :guest_id, references(:guest, type: :uuid, on_delete: :delete_all), null: false
      add :token, :binary, null: false
      add :context, :string, null: false
      add :sent_to, :string
      timestamps(updated_at: false, default: fragment("NOW()"))
    end

    create index(:guest_tokens, [:guest_id])
    create unique_index(:guest_tokens, [:context, :token])
  end
end
