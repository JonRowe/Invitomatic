defmodule Invitomatic.Repo.Migrations.AddTitleToContent do
  use Ecto.Migration

  def up do
    alter table(:content) do
      add(:title, :text)
    end

    execute "UPDATE content SET title = section::text"

    alter table(:content) do
      modify(:title, :text, null: false)
    end
  end

  def down do
    alter table(:content) do
      remove(:title)
    end
  end
end
