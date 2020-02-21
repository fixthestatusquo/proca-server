defmodule Mix.Tasks.GenKeys do
  use Mix.Task


  defp generate(org_name) do
    [:postgrex, :ecto]
    |> Enum.each(&Application.ensure_all_started/1)
    Proca.Repo.start_link

    case Proca.Org.get_by_name(org_name) do
      nil -> IO.puts "no such org #{org_name}"
      o -> Proca.PublicKey.build_for(o) |> Proca.Repo.insert
    end
  end


  @shortdoc "Generate encryption keys for my org"
  def run([org_name]) do
    generate(org_name)
  end

  def run([]) do
    generate(Application.get_env(:proca, Proca)[:org_name])
  end
end
