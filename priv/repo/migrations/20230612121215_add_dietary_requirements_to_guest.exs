defmodule Invitomatic.Repo.Migrations.AddDietaryRequirementsToGuest do
  use Ecto.Migration

  def change do
    alter table(:guest) do
      add(:dietary_requirements, :text, null: false, default: "")
    end
  end
end
