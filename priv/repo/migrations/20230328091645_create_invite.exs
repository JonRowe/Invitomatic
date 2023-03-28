defmodule Invitomatic.Repo.Migrations.CreateInvite do
  use Ecto.Migration

  def change do
    create table(:invite, primary_key: false) do
      add :id, :uuid, primary_key: true
      add :name, :text, default: "", null: false
      timestamps(default: fragment("now()"))
    end

    alter table(:login) do
      add :invite_id, references(:invite, type: :uuid, on_delete: :delete_all)
    end

    execute(
      """
      WITH inserted AS
        (
          INSERT INTO invite (id, name)
          SELECT uuid_generate_v4(), email
          FROM login
          RETURNING id, name
        )
      UPDATE login
      SET invite_id = inserted.id
      FROM inserted
      WHERE login.email = inserted.name;
      """,
      ""
    )

    alter table(:login) do
      modify :invite_id, :uuid, null: false, from: {:uuid, null: true}
    end

    execute("ALTER TABLE invite ALTER COLUMN name DROP DEFAULT;", "")
  end
end
