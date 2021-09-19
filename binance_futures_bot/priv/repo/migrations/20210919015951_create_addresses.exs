defmodule BinanceFuturesBot.Repo.Migrations.CreateAddresses do
  use Ecto.Migration

  def change do
    create table(:addresses) do
      add :city, :string

      timestamps()
    end

  end
end
