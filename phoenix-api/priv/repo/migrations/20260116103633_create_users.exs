defmodule PhoenixApi.Repo.Migrations.CreateUsers do
  use Ecto.Migration

  def change do
    create table(:users) do
      add :first_name, :string, null: false
      add :last_name, :string, null: false
      add :birthdate, :date, null: false
      add :gender, :string, null: false

      timestamps()
    end

    create index(:users, [:first_name])
    create index(:users, [:last_name])
    create index(:users, [:gender])
    create index(:users, [:birthdate])
  end
end
