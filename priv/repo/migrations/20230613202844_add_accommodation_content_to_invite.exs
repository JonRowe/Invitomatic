defmodule Invitomatic.Repo.Migrations.AddAccommodationContentToInvite do
  use Ecto.Migration

  def up do
    execute("ALTER TYPE content_section ADD VALUE 'accommodation';")

    alter table(:invite) do
      add(:extra_content, :content_section)
    end
  end

  def down do
    alter table(:invite) do
      remove(:extra_content, :content_section)
    end

    execute("DELETE FROM content WHERE section = 'accommodation';")
    execute("ALTER TYPE content_section RENAME TO old_content_section;")
    execute("CREATE TYPE content_section AS ENUM ('invitation', 'rsvp', 'other', 'stylesheet');")

    execute(
      "ALTER TABLE content ALTER COLUMN section TYPE content_section USING section::text::content_section;"
    )

    execute("DROP TYPE old_content_section;")
  end
end
