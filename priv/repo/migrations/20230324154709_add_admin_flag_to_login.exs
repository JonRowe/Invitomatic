defmodule Invitomatic.Repo.Migrations.AddAdminFlagToLogin do
  use Ecto.Migration

  def change do
    alter table(:login) do
      add :admin, :boolean, default: false
    end
  end
end
