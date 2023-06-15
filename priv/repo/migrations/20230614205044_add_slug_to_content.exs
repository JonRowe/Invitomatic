defmodule Invitomatic.Repo.Migrations.AddSlugToContent do
  use Ecto.Migration

  def up do
    alter table(:content) do
      add(:slug, :citext)
    end

    execute(
      "UPDATE content SET slug = (CASE WHEN section='other' THEN lower(title) ELSE section::text END)"
    )

    alter table(:content) do
      modify(:slug, :citext, null: false)
    end

    create unique_index(:content, [:slug])
  end

  def down do
    alter table(:content) do
      remove(:slug)
    end
  end
end
