defmodule Invitomatic.Repo.Migrations.AddLockedToInvite do
  use Ecto.Migration

  def change do
    alter table(:invite) do
      add(:locked, :boolean, null: false, default: false)
    end
  end
end
