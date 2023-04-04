defmodule Invitomatic.Repo.Migrations.AddPrimaryFlagToLogin do
  use Ecto.Migration

  def change do
    alter table(:login) do
      add :primary, :boolean, default: false
    end

    create index(:login, [:invite_id, :primary], unique: true, where: "\"primary\" = true")

    execute("UPDATE login SET \"primary\"=true;", "")
  end
end
