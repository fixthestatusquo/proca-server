defmodule Mix.Tasks.Eci do
  use Mix.Task
  alias Proca.Repo
  import Ecto.Changeset

  defp start_repo do
    [:postgrex, :ecto]
    |> Enum.each(&Application.ensure_all_started/1)
    Proca.Repo.start_link
  end


  def run(["create", org_name, campaign_name]) do
    start_repo()

    Repo.transaction fn ->
      {:ok, org} = Proca.Org.changeset(%Proca.Org{}, %{name: org_name, title: org_name, contact_schema: :eci})
      |> Repo.insert()

      keys = apply_changes(Proca.PublicKey.build_for(org, "ECI initial key"))

      IO.puts("{'#{Proca.PublicKey.base_encode(keys.public)}': '#{Proca.PublicKey.base_encode(keys.private)}'")

      {:ok, k} = keys
      |> change(private: nil)
      |> Repo.insert()

      {:ok, camp} = Proca.Campaign.upsert(org, %{name: org_name, title: campaign_name})
      |> Repo.insert()

      pages = Proca.Contact.EciDataRules.countries
      |> Enum.map(fn ctr ->
        {:ok, ap} = Proca.ActionPage.upsert(org, camp, %{name: "#{campaign_name}/#{ctr}",
                                                         locale: ctr})
                                                         |> Repo.insert()
        ap
      end)
    end
  end
end
