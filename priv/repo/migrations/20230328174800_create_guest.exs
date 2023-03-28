defmodule Invitomatic.Repo.Migrations.CreateGuest do
  use Ecto.Migration

  def change do
    execute("CREATE TYPE age_enum AS ENUM ('adult','child','under_three')", "DROP TYPE age_enum")
    execute("CREATE TYPE rsvp_enum AS ENUM ('yes','no','maybe')", "DROP TYPE rsvp_enum")

    create table(:guest, primary_key: false) do
      add :id, :uuid, primary_key: true
      add :name, :text, default: "", null: false
      add :age, :age_enum, default: "adult", null: false
      add :rsvp, :rsvp_enum, default: nil, null: true
      add :invite_id, references(:invite, type: :uuid, on_delete: :delete_all)
      timestamps(default: fragment("NOW()"))
    end

    execute(
      """
      INSERT INTO guest (id, name, invite_id)
      SELECT uuid_generate_v4(), name, id
      FROM invite;
      """,
      ""
    )
  end
end
