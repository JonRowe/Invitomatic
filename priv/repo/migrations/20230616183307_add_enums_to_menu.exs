defmodule Invitomatic.Repo.Migrations.AddEnumsToMenu do
  use Ecto.Migration

  def up do
    execute("CREATE TYPE menu_course_enum AS ENUM ('starter', 'main', 'dessert');")

    alter table(:menu_option) do
      add :age_group, :age_enum
      add :course, :menu_course_enum
      remove :description, :text
    end

    execute("UPDATE menu_option SET age_group = 'adult', course = 'main'")

    alter table(:menu_option) do
      modify :age_group, :age_enum, null: false
      modify :course, :menu_course_enum, null: false
    end

    drop index(:menu_option, :order)
    create index(:menu_option, [:age_group, :course, :order], unique: true)
  end

  def down do
    alter table(:menu_option) do
      remove :age_group
      remove :course
      add :description, :text
    end

    execute("UPDATE menu_option SET description = name;")

    alter table(:menu_option) do
      modify :description, :text, null: false
    end

    execute("DROP TYPE menu_course_enum;")

    drop index(:menu_option, [:age_group, :course, :order])
    create index(:menu_option, :order, unique: true)
  end
end
