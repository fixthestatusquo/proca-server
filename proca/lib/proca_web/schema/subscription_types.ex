defmodule ProcaWeb.Schema.SubscriptionTypes do
  use Absinthe.Schema.Notation

  alias Proca.Repo
  alias Proca.{ActionPage, Org}

  object :updates do
    field :action_page_upserted, :public_action_page do
      arg :org_name, :string

      config fn args, _ ->
        t = case args do
              %{org_name: name} when is_bitstring(name) -> 
                case Repo.get_by(Org, name: name) do
                  %Org{name: name} -> name
                  nil -> nil
                end
              _ -> "$instance"
        end

        case t do
          nil -> 
            {:error, %{
                message: "Org not found",
                extensions: %{code: "not_found"} } }
          t -> {:ok, topic: t}
        end
      end

      resolve fn action_page, _, _ ->
        {
          :ok,
          action_page
          |> ActionPage.stringify_config()
        }
      end
    end

  end
end
