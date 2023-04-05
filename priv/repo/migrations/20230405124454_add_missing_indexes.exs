defmodule Invitomatic.Repo.Migrations.AddMissingIndexes do
  use Ecto.Migration

  def change do
    create index(:login, [:invite_id])
    create index(:guest, [:invite_id])
  end
end
