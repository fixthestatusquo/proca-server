defmodule Proca.Service.EmailTemplateDirectory do
  @moduledoc """
  Lookup email templates.

  Supports looking up both local and remote templates.
  The remote templates are cached in an ETS table.
  The compiled local templates are cached in the ETS table too.

  ## The ETS table

  - name :local_templates
    key: {service_id, name}
    value: EmailTemplate struct

  - name :remote_templates
    key: {org_id, name, locale}


  """
  use GenServer
  alias Proca.{Service, Org, Repo}
  alias Proca.Service.{EmailBackend, EmailTemplate}
  import Ex2ms

  def table_name(:local), do: :local_templates
  def table_name(:remote), do: :remote_templates

  @impl true
  def init([]) do
    local_table = :ets.new(table_name(:local), [:set, :protected, :named_table])
    remote_table = :ets.new(table_name(:remote), [:set, :protected, :named_table])
    {:ok, %{local: local_table, remote: remote_table}}
  end

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  def remote_record(%Service{id: service_id}, %EmailTemplate{} = tmpl) do
    {{service_id, tmpl.name}, tmpl}
  end

  def local_record(%Org{id: org_id}, %EmailTemplate{} = tmpl) do
    {{org_id, tmpl.name, tmpl.locale}, tmpl}
  end

  def delete_remote_templates(%Org{email_backend_id: tb_id}) do
    spec =
      fun do
        {{id, name}, template} when id == ^tb_id -> true
      end

    :ets.select_delete(table_name(:remote), spec)
  end

  @doc """
  Reload remote template cache for org
  """
  def load_templates(org) do
    org = Repo.preload(org, [:email_backend])

    with tb when tb != nil <- org.email_backend,
         {:ok, templates} <- EmailBackend.list_templates(org) do
      delete_remote_templates(org)

      for t <- templates do
        :ets.insert(table_name(:remote), remote_record(tb, t))
      end

      {:ok, length(templates)}
    else
      nil -> {:ok, 0}
      r = {:error, _reason} -> r
    end
  end

  @impl true
  def handle_cast({:load_templates, org}, st) do
    load_templates(org)
    {:noreply, st}
  end

  @impl true
  def handle_cast(
        {
          :template_updated,
          tmpl = %EmailTemplate{id: id, org_id: org_id, name: name, locale: locale},
          store
        },
        state
      ) do
    if store do
      :ets.insert(table_name(:local), {{org_id, name, locale}, tmpl})
    else
      # remote the cached local template
      spec =
        fun do
          {{org_id, name, locale}, %{id: id}} when id == ^id -> true
        end

      :ets.select_delete(table_name(:local), spec)
    end

    {:noreply, state}
  end

  @impl true
  def handle_call({:load_templates, org}, _from, st) do
    {:reply, load_templates(org), st}
  end

  @impl true
  def handle_call(:sync, _from, state) do
    {:reply, :ok, state}
  end

  def load_templates_async(org), do: GenServer.cast(__MODULE__, {:load_templates, org})
  def load_templates_sync(org), do: GenServer.call(__MODULE__, {:load_templates, org})

  def cache_template(%EmailTemplate{} = t, store \\ false) do
    GenServer.cast(__MODULE__, {:template_updated, t, store})
  end

  def bust_cache_template(t), do: cache_template(t, false)

  @doc """
  return {:ok, nil} when given name is nil.
  """
  def by_name(org, name, locale \\ nil)
  def by_name(_, nil, _), do: {:ok, nil}

  def by_name(org = %Org{}, name, locale) do
    with r1 when is_nil(r1) <- by_name_local(org, name, locale),
         r2 when is_nil(r2) <- by_name_remote(org, name, locale) do
      :not_found
    else
      %EmailTemplate{} = tmpl -> {:ok, tmpl}
    end
  end

  def by_name_local(org = %Org{id: id}, name, locale) do
    lookup = :ets.lookup(table_name(:local), {id, name, locale})

    with [] <- lookup,
         record when record != nil <- EmailTemplate.one(org: org, name: name, locale: locale) do
      record = EmailTemplate.compile(record)
      cache_template(record, true)
      record
    else
      [{_key, cached}] -> cached
      nil -> nil
    end
  end

  def by_name_remote(%Org{email_backend_id: bid}, name, _locale)
      when is_integer(bid) and is_bitstring(name) do
    lookup = :ets.lookup(table_name(:remote), {bid, name})

    case lookup do
      [{_key, tmpl}] -> tmpl
      [] -> nil
    end
  end

  def by_name_remote(_, _, _), do: nil

  @doc """
  Lookup but if not found, reload the templates
  """
  def by_name_reload(org, name, locale \\ nil) do
    case by_name(org, name, locale) do
      {:ok, tpl} ->
        {:ok, tpl}

      :not_found ->
        load_templates_sync(org)
        by_name(org, name, locale)
    end
  end

  def by_ref(%Org{email_backend_id: bid}, ref)
      when is_integer(bid) and not is_nil(ref) do
    spec =
      fun do
        {{id, ref}, %{name: name}} when id == ^bid and ref == ^ref -> {name, ref}
      end

    lookup = :ets.select(table_name(:remote), spec)

    case lookup do
      [{n, r}] -> {:ok, %EmailTemplate{name: n, ref: r}}
      [] -> :not_found
      # inconclusive, maybe a name clash? we need to reload!
      [_ref, _ref2] -> :not_found
    end
  end

  def by_ref(%Org{email_backend_id: bid}, _ref) when is_nil(bid) do
    :not_found
  end

  def list_names(org = %Org{}) do
    if EmailBackend.supports_templates?(org) do
      list_names_local(org) ++ list_names_remote(org)
    else
      list_names_local(org)
    end
  end

  def list_names_local(org = %Org{}) do
    EmailTemplate.all(org: org)
    |> Enum.map(fn
      %{name: n, locale: l} when l != nil -> "#{n}@#{l}"
      %{name: n} -> n
    end)
  end

  def list_names_remote(org = %Org{email_backend_id: bid}) when is_number(bid) do
    load_templates_sync(org)

    spec =
      fun do
        {{id, ref}, %{name: n}} when id == ^bid -> n
      end

    :ets.select(table_name(:remote), spec)
  end

  def list_names_remote(_) do
    []
  end
end
