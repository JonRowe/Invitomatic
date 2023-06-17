defmodule Invitomatic.Repo.Migrations.AddOtherMenuChoicesToGuest do
  use Ecto.Migration

  def change do
    rename table(:guest), :menu_option_id, to: :main_menu_option_id

    alter table(:guest) do
      add :starter_menu_option_id, references(:menu_option, type: :uuid)
      add :dessert_menu_option_id, references(:menu_option, type: :uuid)
    end

    create index(:guest, [:starter_menu_option_id])
    create index(:guest, [:dessert_menu_option_id])
  end
end
