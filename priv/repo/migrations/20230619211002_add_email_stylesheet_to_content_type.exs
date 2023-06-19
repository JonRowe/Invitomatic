defmodule Invitomatic.Repo.Migrations.AddEmailStylesheetToContentType do
  use Ecto.Migration

  def up do
    execute("ALTER TYPE content_section ADD VALUE 'email_stylesheet';")
  end

  def down do
    execute("DELETE FROM content WHERE section = 'email_stylesheet';")

    execute("ALTER TYPE content_section RENAME TO old_content_section;")

    execute(
      "CREATE TYPE content_section AS ENUM ('invitation', 'rsvp', 'other', 'stylesheet', 'accommodation');"
    )

    execute(
      "ALTER TABLE content ALTER COLUMN section TYPE content_section USING section::text::content_section;"
    )

    execute(
      "ALTER TABLE invite ALTER COLUMN extra_content TYPE content_section USING extra_content::text::content_section;"
    )

    execute("DROP TYPE old_content_section;")
  end
end
