defmodule Invitomatic.Repo.Migrations.AddStylesheetToContentType do
  use Ecto.Migration

  def up do
    execute("ALTER TYPE content_section ADD VALUE 'stylesheet';")
  end

  def down do
    execute("DELETE FROM content WHERE section = 'stylesheet';")
    execute("ALTER TYPE content_section RENAME TO old_content_section;")
    execute("CREATE TYPE content_section AS ENUM ('invitation', 'rsvp', 'other');")

    execute(
      "ALTER TABLE content ALTER COLUMN section TYPE content_section USING section::text::content_section;"
    )

    execute("DROP TYPE old_content_section;")
  end
end
