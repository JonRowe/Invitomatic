defmodule Invitomatic.Repo.Migrations.CreateFoodChoice do
  use Ecto.Migration

  def change do
    create table(:menu_option, primary_key: false) do
      add :id, :uuid, primary_key: true
      add :name, :string, null: false
      add :description, :text, null: false
      add :order, :smallserial, null: false

      timestamps(default: fragment("NOW()"))
    end

    alter table(:guest) do
      add :menu_option_id, references(:menu_option, type: :uuid)
    end

    create index(:menu_option, :order, unique: true)
    create index(:guest, [:menu_option_id])
  end
end
