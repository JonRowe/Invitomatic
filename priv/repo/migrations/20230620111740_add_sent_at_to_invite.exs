defmodule Invitomatic.Repo.Migrations.AddSentAtToInvite do
  use Ecto.Migration

  def change do
    alter table(:invite) do
      add :sent_at, :naive_datetime
    end
  end
end
