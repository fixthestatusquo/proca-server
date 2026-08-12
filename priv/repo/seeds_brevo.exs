# Setup a Brevo email backend for the instance org.
#
# Run inside the dev container:
#
#   BREVO_API_KEY=your-key mix run priv/repo/seeds_brevo.exs
#
# Or with docker-compose (set BREVO_API_KEY in .env or environment first):
#
#   docker-compose exec app mix run priv/repo/seeds_brevo.exs

api_key = System.get_env("BREVO_API_KEY")
from_email = System.get_env("BREVO_FROM_EMAIL")

unless api_key && api_key != "" do
  IO.puts("ERROR: BREVO_API_KEY env var is required")
  System.halt(1)
end

alias Proca.{Org, Service, Repo}
import Ecto.Query

org = Org.one([:instance]) || raise "No instance org found - run mix run priv/repo/seeds.exs first"

existing = Repo.one(from s in Service, where: s.org_id == ^org.id and s.name == :brevo)

service =
  if existing do
    IO.puts("Updating existing Brevo service (id=#{existing.id})")

    existing
    |> Service.changeset(%{password: api_key})
    |> Repo.update!()
  else
    IO.puts("Creating new Brevo service for org '#{org.name}'")

    Service.build_for_org(%{password: api_key, host: "", user: ""}, org, :brevo)
    |> Repo.insert!()
  end

IO.puts("Brevo service ready (id=#{service.id})")

org_updates = %{email_backend_id: service.id}

org_updates =
  if from_email && from_email != "" do
    Map.put(org_updates, :email_from, from_email)
  else
    org_updates
  end

Org.changeset(org, org_updates)
|> Repo.update!()

IO.puts("Org '#{org.name}' email_backend set to Brevo")

# Load templates from Brevo into cache
org = Org.one(id: org.id, preload: [:email_backend])

case Proca.Service.EmailTemplateDirectory.load_templates_sync(org) do
  {:ok, count} ->
    IO.puts("Loaded #{count} Brevo template(s)")

  {:error, reason} ->
    IO.puts("WARNING: Could not load templates: #{reason}")
end
