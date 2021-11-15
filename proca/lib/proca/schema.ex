defmodule Proca.Schema do 
  @moduledoc """
  Contains helpers for writing Proca Schemas.
  use Proca.Schema, module: Proca.MyRecordModule

  defines:
  - `MyRecordModule.all(criteria_keyword_list)` and you implement methods that customize the query according to criteria, eg: 

  ```
  MyRecordModule.all(query, [{:foo, foo} | kw]), do: query |> where([x], x.foo == ^foo) |> all(kw)
  ```

  After the criteria run out, list of records is returned. If last criteria is [one: true] then Repo.one() is called.
  
  - `MyRecordModule.one(criteria_keyword_list)` calls `all(criteria_keyword_list ++ [one: true])`
  """

  defmacro __using__(opts) do 
    schema_mod = opts[:module]

    quote do 
      alias Proca.Repo

      def one(kw) when is_list(kw), do: all(kw ++ [one: true])
      def one!(kw) when is_list(kw), do: all(kw ++ [one!: true])

      def all(kw) when is_list(kw) do
        import Ecto.Query, only: [from: 1]
        all(from(a in unquote(schema_mod)), kw)
      end
      def all(query, []), do: Repo.all(query)
      def all(query, [{:one, true}]), do: Repo.one(query)
      def all(query, [{:one!, true}]), do: Repo.one!(query)
      def all(query, [{:preload, assocs} | kw]) do
        import Ecto.Query, only: [preload: 3]
        preload(query, [a], ^assocs) |> all(kw)
      end

      def create(kw) when is_list(kw), do: update(Ecto.Changeset.change(struct!(unquote(schema_mod))), kw)
      def create(chset = %Ecto.Changeset{}, []), do: update(chset, [])
      def create(chset = %Ecto.Changeset{}, kw) when is_list(kw), do: update(chset, kw)

      def update(chset = %Ecto.Changeset{}, []), do: Repo.insert_or_update(chset)
    end
  end
end
