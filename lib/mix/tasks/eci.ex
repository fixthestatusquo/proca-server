defmodule Mix.Tasks.Eci do
  @moduledoc """
  Task to create ECI campaign
  """
  use Mix.Task
  alias Proca.Repo
  import Ecto.Changeset

  defp start_repo do
    [:postgrex, :ecto]
    |> Enum.each(&Application.ensure_all_started/1)

    Proca.Repo.start_link()
  end

  def run(["create", org_name, campaign_name]) do
    start_repo()

    Repo.transaction(fn ->
      {:ok, org} =
        Proca.Org.changeset(%Proca.Org{}, %{name: org_name, title: org_name, contact_schema: :eci})
        |> Repo.insert()

      keys = apply_changes(Proca.PublicKey.build_for(org, "ECI initial key"))

      {:ok, _k} =
        keys
        |> change(private: nil)
        |> Repo.insert()

      {:ok, camp} =
        Proca.Campaign.upsert(org, %{name: org_name, title: campaign_name})
        |> Repo.insert()

      _pages =
        Proca.Contact.EciDataRules.countries()
        |> Enum.map(fn ctr ->
          {:ok, ap} =
            Proca.ActionPage.upsert(org, camp, %{name: "#{campaign_name}/#{ctr}", locale: ctr})
            |> Repo.insert()

          ap
        end)
    end)
  end
end
