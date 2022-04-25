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

      def defaults(Proca.ActionPage), do: []
      def defaults(_), do: []

      def one(kw) when is_list(kw), do: all(kw ++ [one: true])
      def one!(kw) when is_list(kw), do: all(kw ++ [one!: true])

      def all(kw) when is_list(kw) do
        import Ecto.Query, only: [from: 1]
        all(from(a in unquote(schema_mod)), kw)
      end

      def all(query, []), do: Repo.all(query)
      def all(query, [{:one, true}]), do: Repo.one(query)
      def all(query, [{:one!, true}]), do: Repo.one!(query)

      def all(query, [{:id, id} | kw]) when is_list(id) do
        import Ecto.Query, only: [where: 3]
        where(query, [a], a.id in ^id) |> all(kw)
      end

      def all(query, [{:id, id} | kw]) when is_number(id) or is_bitstring(id) do
        import Ecto.Query, only: [where: 3]
        where(query, [a], a.id == ^id) |> all(kw)
      end

      def all(query, [{:preload, assocs} | kw]) when is_list(assocs) do
        import Ecto.Query, only: [preload: 3]
        preload(query, [a], ^assocs) |> all(kw)
      end

      def all(query, [{:order_by, order} | kw]) when is_list(order) do
        import Ecto.Query, only: [order_by: 3]
        order_by(query, [a], ^order) |> all(kw)
      end

      def all(query, [{:limit, limit} | kw]) when is_number(limit) do
        import Ecto.Query, only: [limit: 3]
        limit(query, [a], ^limit) |> all(kw)
      end

      def all(query, [{:by_ids, ids} | kw]) do
        import Ecto.Query, only: [where: 3, select: 3]

        query
        |> where([a], a.id in ^ids)
        |> select([a], {a.id, a})
        |> all(kw)
      end
    end
  end
end
