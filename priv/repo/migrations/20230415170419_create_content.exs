defmodule Invitomatic.Repo.Migrations.CreateContent do
  use Ecto.Migration

  def change do
    execute(
      """
      CREATE TYPE content_section AS ENUM ('invitation', 'rsvp', 'other')
      """,
      "DROP TYPE content_section;"
    )

    create table(:content, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :section, :content_section, null: false
      add :text, :text, null: false
      add :other_index, :integer, null: true

      timestamps()
    end
  end
end
